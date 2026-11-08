#!/usr/bin/env bash
#
# CI helper for the signed Android release build. Called from
# .github/workflows/ci.yml; also runnable locally to test the failure paths.
#
#   android-signing.sh prepare
#       Requires all four secrets in the environment:
#         KEYSTORE_BASE64  KEYSTORE_PASSWORD  KEY_PASSWORD  KEY_ALIAS
#       Decodes the keystore to $KEYSTORE_OUT, proves the passwords and the
#       alias really open the key (by signing a throwaway jar), and writes
#       $KEY_PROPERTIES_OUT. Fails with a named, actionable error otherwise.
#
#   android-signing.sh verify-artifact FILE...
#       Fails unless every FILE (aab/apk) is signed by the certificate in
#       $KEYSTORE_OUT, and never by an Android debug certificate.
#
# Secrets are read from the environment only and handed to keytool/jarsigner
# with -storepass:env / -keypass:env, so they never appear in argv or logs.

set -euo pipefail

KEYSTORE_OUT="${KEYSTORE_OUT:-android/app/baby-vax-release-key.jks}"
KEY_PROPERTIES_OUT="${KEY_PROPERTIES_OUT:-android/key.properties}"
# key.properties is read from android/app, so storeFile is relative to it.
STORE_FILE_IN_PROPS="${STORE_FILE_IN_PROPS:-baby-vax-release-key.jks}"

HOW_TO_FIX="Fix: run scripts/rotate-upload-key.sh (or .ps1) on your own machine. It sets all four secrets. See 'Key rotation' in RELEASE_NOTES_FOR_AHMED.md."

fail() {
  # ::error:: makes GitHub show the message on the run summary page.
  printf '::error title=Release signing::%s\n' "$1"
  printf '%s\n' "$HOW_TO_FIX"
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || fail "$1 not found on the runner (needs a JDK 17)."; }

prepare() {
  need keytool
  need jarsigner
  need jar

  local missing=()
  for name in KEYSTORE_BASE64 KEYSTORE_PASSWORD KEY_PASSWORD KEY_ALIAS; do
    if [ -z "${!name:-}" ]; then missing+=("$name"); fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    fail "Missing GitHub secret(s): ${missing[*]}. A signed release cannot be built, and this workflow never falls back to debug signing on main."
  fi

  mkdir -p "$(dirname "$KEYSTORE_OUT")"
  if ! printf '%s' "$KEYSTORE_BASE64" | tr -d ' \r\n' | base64 -d > "$KEYSTORE_OUT" 2>/dev/null \
     || [ ! -s "$KEYSTORE_OUT" ]; then
    rm -f "$KEYSTORE_OUT"
    fail "KEYSTORE_BASE64 is not valid base64."
  fi

  if ! keytool -list -keystore "$KEYSTORE_OUT" -storepass:env KEYSTORE_PASSWORD >/dev/null 2>&1; then
    fail "KEYSTORE_BASE64 is not a keystore, or KEYSTORE_PASSWORD does not open it."
  fi

  if ! keytool -list -keystore "$KEYSTORE_OUT" -storepass:env KEYSTORE_PASSWORD \
        -alias "$KEY_ALIAS" >/dev/null 2>&1; then
    fail "The keystore has no key with alias KEY_ALIAS='$KEY_ALIAS'."
  fi

  # The only reliable test of KEY_PASSWORD is to actually sign something.
  local tmp
  tmp="$(mktemp -d)"
  printf 'probe\n' > "$tmp/probe.txt"
  (cd "$tmp" && jar cf probe.jar probe.txt)
  if ! jarsigner -keystore "$KEYSTORE_OUT" -storepass:env KEYSTORE_PASSWORD \
        -keypass:env KEY_PASSWORD "$tmp/probe.jar" "$KEY_ALIAS" >/dev/null 2>&1; then
    rm -rf "$tmp"
    fail "KEY_PASSWORD does not unlock key '$KEY_ALIAS'. (For a PKCS12 keystore it must equal KEYSTORE_PASSWORD.)"
  fi
  rm -rf "$tmp"

  if cert_is_debug "$(cert_of_keystore)"; then
    fail "The keystore in KEYSTORE_BASE64 holds an Android DEBUG certificate. Play rejects debug-signed uploads."
  fi

  # printf is a shell builtin: the values never reach a process's argv.
  umask 077
  {
    printf 'storePassword=%s\n' "$KEYSTORE_PASSWORD"
    printf 'keyPassword=%s\n' "$KEY_PASSWORD"
    printf 'keyAlias=%s\n' "$KEY_ALIAS"
    printf 'storeFile=%s\n' "$STORE_FILE_IN_PROPS"
  } > "$KEY_PROPERTIES_OUT"

  printf 'Signing secrets verified: keystore decodes, both passwords and alias "%s" work.\n' "$KEY_ALIAS"
  printf 'Upload certificate SHA-256: %s\n' "$(sha256_of_keystore)"
}

# Normalizes a hex digest: drop colons and spaces, upper-case.
norm() { tr -d ': \r' | tr '[:lower:]' '[:upper:]'; }

# Owner line + SHA-256 of the keystore's alias certificate.
cert_of_keystore() {
  keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KEYSTORE_PASSWORD \
    -alias "$KEY_ALIAS" 2>/dev/null | grep -E '^(Owner:|[[:space:]]*SHA256:)'
}

sha256_of_keystore() {
  cert_of_keystore | grep -m1 'SHA256:' | sed -E 's/.*SHA256:[[:space:]]*//' | norm
}

cert_is_debug() { printf '%s' "$1" | grep -qi 'CN=Android Debug'; }

# apksigner from $APKSIGNER, PATH, or the newest $ANDROID_HOME build-tools.
find_apksigner() {
  if [ -n "${APKSIGNER:-}" ]; then printf '%s' "$APKSIGNER"; return; fi
  if command -v apksigner >/dev/null 2>&1; then command -v apksigner; return; fi
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  [ -n "$sdk" ] || return 1
  local latest
  # Directory names are version numbers, so ls | sort -V is safe here.
  # shellcheck disable=SC2012
  latest="$(ls -1 "$sdk/build-tools" 2>/dev/null | sort -V | tail -n1)"
  [ -n "$latest" ] && [ -x "$sdk/build-tools/$latest/apksigner" ] || return 1
  printf '%s' "$sdk/build-tools/$latest/apksigner"
}

# Prints "DN<TAB>SHA256" for every signer of an artifact; empty if unsigned.
# AABs carry a JAR signature (keytool reads it). APKs with minSdk >= 24 carry
# only v2/v3 signatures, which keytool cannot see, so apksigner reads those.
signers_of() {
  local f="$1"
  case "$f" in
    *.apk)
      local apksigner
      apksigner="$(find_apksigner)" || fail "apksigner not found (set APKSIGNER or ANDROID_HOME) to verify $f."
      "$apksigner" verify --print-certs "$f" 2>/dev/null | awk '
        /certificate DN:/          { sub(/.*certificate DN: /, ""); dn = $0 }
        /certificate SHA-256 digest:/ { sub(/.*digest: /, ""); print dn "\t" $0 }'
      ;;
    *)
      keytool -printcert -jarfile "$f" 2>/dev/null | awk '
        /^Owner:/            { sub(/^Owner: /, ""); dn = $0 }
        /^[[:space:]]*SHA256:/ { sub(/.*SHA256:[[:space:]]*/, ""); print dn "\t" $0 }'
      ;;
  esac
}

verify_artifact() {
  [ "$#" -gt 0 ] || fail "verify-artifact needs at least one file."
  need keytool
  if [ -z "${KEYSTORE_PASSWORD:-}" ] || [ -z "${KEY_ALIAS:-}" ] || [ ! -s "$KEYSTORE_OUT" ]; then
    fail "verify-artifact needs the keystore and KEYSTORE_PASSWORD / KEY_ALIAS from 'prepare'."
  fi

  local expected
  expected="$(sha256_of_keystore)"
  [ -n "$expected" ] || fail "Could not read the upload certificate from the keystore."

  local f signers dn digest
  for f in "$@"; do
    [ -f "$f" ] || fail "Artifact not found: $f"
    signers="$(signers_of "$f")"
    [ -n "$signers" ] || fail "$f is NOT signed. Refusing to publish an unsigned release."
    # Every signer of the file must be the upload certificate.
    while IFS=$'\t' read -r dn digest; do
      if cert_is_debug "$dn"; then
        fail "$f is signed with an Android DEBUG certificate. Refusing to publish it."
      fi
      digest="$(printf '%s' "$digest" | norm)"
      if [ "$digest" != "$expected" ]; then
        fail "$f is signed by '$dn' ($digest), not by the upload key ($expected)."
      fi
    done <<<"$signers"
    printf 'OK: %s is signed by the upload key (SHA-256 %s)\n' "$f" "$expected"
  done
}

case "${1:-}" in
  prepare)         shift; prepare "$@" ;;
  verify-artifact) shift; verify_artifact "$@" ;;
  *) printf 'usage: %s prepare | verify-artifact FILE...\n' "$0" >&2; exit 2 ;;
esac
