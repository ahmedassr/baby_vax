#!/usr/bin/env bash
#
# Rotate the Baby Vax Play upload key (Linux / macOS / Git Bash).
#
#   bash scripts/rotate-upload-key.sh
#
# What it does, in order:
#   1. checks keytool (JDK 17+) and gh (logged in, can see the repo)
#   2. asks for the store and key passwords (hidden, typed twice)
#   3. creates ~/keys/babyvax-upload.jks (refuses to overwrite it)
#   4. sets the GitHub Actions secrets the CI workflow reads
#   5. writes android/key.properties (gitignored) for local release builds
#   6. prints the SHA-1 / SHA-256 fingerprints
#   7. reminds you to back the key up
#
# Passwords are never put on a command line, echoed, or written anywhere
# except android/key.properties (mode 600). They reach keytool through that
# process's environment only (-storepass:env), and gh through stdin.
#
# Safe to re-run: if the keystore already exists, the script offers to reuse
# it (after verifying the password) to redo steps 4-6, e.g. when gh failed.

set -euo pipefail
umask 077
export LC_ALL=C

REPO="ahmedassr/baby_vax"
ALIAS="upload"
KEY_DIR="$HOME/keys"
KEYSTORE="$KEY_DIR/babyvax-upload.jks"

# The four secret names read by .github/workflows/ci.yml. Keep in sync.
SECRET_KEYSTORE_BASE64="KEYSTORE_BASE64"
SECRET_KEYSTORE_PASSWORD="KEYSTORE_PASSWORD"
SECRET_KEY_PASSWORD="KEY_PASSWORD"
SECRET_KEY_ALIAS="KEY_ALIAS"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_PROPS="$ROOT/android/key.properties"

STOREPASS=""
KEYPASS=""

cleanup() {
  # Restore terminal echo in case we were interrupted inside `read -s`.
  if [ -t 0 ]; then stty echo 2>/dev/null || true; fi
  STOREPASS=""
  KEYPASS=""
  unset STOREPASS KEYPASS
}
trap cleanup EXIT
trap 'printf "\nInterrupted. Nothing further was changed.\n" >&2; exit 130' INT TERM

die()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }

# ---------------------------------------------------------------- 1. checks

step "Checking prerequisites"

[ -t 0 ] || die "Run this in an interactive terminal (passwords are typed, never piped)."

command -v keytool >/dev/null 2>&1 || die "keytool not found.
Install a JDK 17 or newer and make sure its bin/ is on PATH:
  Ubuntu/Debian: sudo apt install openjdk-17-jdk
  macOS:         brew install openjdk@17
  Windows:       winget install EclipseAdoptium.Temurin.17.JDK"

# keytool has no -version flag; -J-version asks its JVM instead.
java_version_line="$(keytool -J-version 2>&1 | grep -m1 -i 'version' || true)"
java_major="$(printf '%s' "$java_version_line" | sed -E 's/.*version "([0-9]+)(\.([0-9]+))?.*/\1 \3/')"
read -r jv_first jv_second <<<"$java_major"
if [ "${jv_first:-0}" = "1" ]; then jv_first="${jv_second:-0}"; fi  # 1.8 -> 8
case "${jv_first:-}" in
  ''|*[!0-9]*) die "Could not read the Java version from keytool: '$java_version_line'" ;;
esac
[ "$jv_first" -ge 17 ] || die "keytool is from Java $jv_first; JDK 17 or newer is required."
info "keytool: Java $jv_first"

command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) not found.
  Ubuntu/Debian: see https://github.com/cli/cli/blob/trunk/docs/install_linux.md
  macOS:         brew install gh
  Windows:       winget install --id GitHub.cli
Then run: gh auth login"

gh auth status >/dev/null 2>&1 || die "gh is not logged in. Run: gh auth login"
gh repo view "$REPO" --json name >/dev/null 2>&1 \
  || die "gh cannot see $REPO. Log in with an account that has admin access to it."
info "gh: logged in, $REPO reachable"

# ---------------------------------------------------------------- 2. mode

MODE="create"
if [ -e "$KEYSTORE" ]; then
  MODE="reuse"
  info ""
  info "$KEYSTORE already exists. This script will NOT overwrite it."
  info "You can reuse it to (re)set the GitHub secrets and key.properties,"
  info "for example if an earlier run stopped at the gh step."
  printf "Type 'reuse' to continue with the existing keystore, anything else to stop: "
  IFS= read -r answer
  [ "$answer" = "reuse" ] || die "Stopped. Nothing was changed."
fi

# ---------------------------------------------------------------- 3. passwords

# Reads one hidden line into the variable named by $2.
read_hidden() {
  local prompt="$1" __var="$2" __value=""
  printf '%s' "$prompt" >&2
  IFS= read -r -s __value
  printf '\n' >&2
  printf -v "$__var" '%s' "$__value"
  __value=""
}

# Rules that keep the password intact through every place it travels:
#  - printable ASCII, no spaces: Gradle reads key.properties as ISO-8859-1
#    and java.util.Properties trims leading whitespace
#  - no backslash: Properties treats it as an escape character
check_password() {
  local pw="$1" min="$2"
  if [ "${#pw}" -lt "$min" ]; then
    printf '  Too short: use at least %s characters.\n' "$min" >&2; return 1
  fi
  if ! [[ "$pw" =~ ^[[:graph:]]+$ ]]; then
    printf '  Use printable ASCII only: no spaces, tabs or non-Latin letters.\n' >&2; return 1
  fi
  case "$pw" in
    *\\*) printf '  No backslashes, please (key.properties treats them as escapes).\n' >&2; return 1 ;;
  esac
  return 0
}

# Asks twice until both match and the rules pass. Result in the named var.
ask_password() {
  local label="$1" __out="$2" min="$3" a="" b=""
  while :; do
    read_hidden "$label: " a
    if ! check_password "$a" "$min"; then a=""; continue; fi
    read_hidden "$label (again): " b
    if [ "$a" != "$b" ]; then
      printf '  The two entries do not match. Try again.\n' >&2
      a=""; b=""; continue
    fi
    printf -v "$__out" '%s' "$a"
    a=""; b=""
    return 0
  done
}

step "Passwords"
if [ "$MODE" = "create" ]; then
  info "Choose a long password (16+ characters is good; a password manager can"
  info "generate one). Printable ASCII, no spaces, no backslash."
  ask_password "Store password" STOREPASS 12
else
  ask_password "Store password of the existing keystore" STOREPASS 6
fi

info ""
info "Key password. A PKCS12 keystore has ONE password: keytool ignores a"
info "different key password, and the build would then fail to open the key."
info "So enter the same password again here."
while :; do
  ask_password "Key password" KEYPASS 6
  if [ "$KEYPASS" = "$STOREPASS" ]; then break; fi
  printf '  The key password must equal the store password for PKCS12. Try again.\n' >&2
  KEYPASS=""
done

# ---------------------------------------------------------------- 4. keystore

if [ "$MODE" = "create" ]; then
  step "Creating $KEYSTORE"
  mkdir -p "$KEY_DIR"
  chmod 700 "$KEY_DIR"
  # Re-check right before writing, in case something appeared meanwhile.
  [ ! -e "$KEYSTORE" ] || die "$KEYSTORE appeared while the script was running. Not touching it."
  info "keytool will now ask for your name and organisation (any honest values)."
  BV_STOREPASS="$STOREPASS" BV_KEYPASS="$KEYPASS" keytool -genkeypair -v \
    -keystore "$KEYSTORE" -storetype PKCS12 \
    -keyalg RSA -keysize 2048 -validity 10000 -alias "$ALIAS" \
    -storepass:env BV_STOREPASS -keypass:env BV_KEYPASS
  chmod 600 "$KEYSTORE"
fi

step "Verifying the keystore opens with that password and has alias '$ALIAS'"
BV_STOREPASS="$STOREPASS" keytool -list -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env BV_STOREPASS >/dev/null 2>&1 \
  || die "keytool could not open $KEYSTORE with that password, or alias '$ALIAS' is missing."
info "OK"

# ---------------------------------------------------------------- 5. secrets

step "Setting GitHub Actions secrets on $REPO"
# Values go through stdin, never as arguments. base64 output is unwrapped
# so CI can decode it with a plain `base64 -d`.
base64 < "$KEYSTORE" | tr -d '\r\n' | gh secret set "$SECRET_KEYSTORE_BASE64" --repo "$REPO"
printf '%s' "$STOREPASS" | gh secret set "$SECRET_KEYSTORE_PASSWORD" --repo "$REPO"
printf '%s' "$KEYPASS"   | gh secret set "$SECRET_KEY_PASSWORD"      --repo "$REPO"
printf '%s' "$ALIAS"     | gh secret set "$SECRET_KEY_ALIAS"         --repo "$REPO"
info "Set: $SECRET_KEYSTORE_BASE64, $SECRET_KEYSTORE_PASSWORD, $SECRET_KEY_PASSWORD, $SECRET_KEY_ALIAS"

# ---------------------------------------------------------------- 6. key.properties

step "Writing android/key.properties (gitignored)"
write_props=1
if [ -e "$KEY_PROPS" ]; then
  printf "android/key.properties already exists. Type 'replace' to overwrite it, anything else to keep it: "
  IFS= read -r answer
  [ "$answer" = "replace" ] || write_props=0
fi
if [ "$write_props" -eq 1 ]; then
  {
    printf '# Local release signing. Gitignored; never commit. Written by scripts/rotate-upload-key.sh\n'
    printf 'storePassword=%s\n' "$STOREPASS"
    printf 'keyPassword=%s\n' "$KEYPASS"
    printf 'keyAlias=%s\n' "$ALIAS"
    printf 'storeFile=%s\n' "$KEYSTORE"
  } > "$KEY_PROPS"
  chmod 600 "$KEY_PROPS"
  info "Wrote $KEY_PROPS"
  if git -C "$ROOT" check-ignore -q "$KEY_PROPS"; then
    info "Confirmed: git ignores it."
  else
    printf 'WARNING: git does NOT ignore %s. Do not commit it; fix .gitignore.\n' "$KEY_PROPS" >&2
  fi
else
  info "Kept the existing file. Make sure it points at $KEYSTORE."
fi

# ---------------------------------------------------------------- 7. fingerprints

step "Upload key fingerprints"
BV_STOREPASS="$STOREPASS" keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env BV_STOREPASS 2>/dev/null | grep -E '^[[:space:]]*(SHA1|SHA256):' || true
cat <<'EOF'

Where these go:
  - Play Console: nothing to paste. Play reads the upload certificate from
    your first signed upload.
  - Firebase: optional for this app. It signs in with email + password only
    (no Google Sign-In, no phone auth), so Auth needs no fingerprint. App
    Check / Play Integrity needs the SHA-256 of Google's APP SIGNING key
    (Play Console > Test and release > App integrity), not this upload key.
  - If the OLD key's fingerprints were ever added in Firebase, delete them.
EOF

# ---------------------------------------------------------------- 8. backup

cat <<EOF

==> BACK UP THE KEY NOW. Do not skip this.

Copy BOTH of these to TWO places off this laptop:
    $KEYSTORE
    the password you just typed
For example:
    1. your password manager (attach the .jks file, store the password with it)
    2. an encrypted USB stick kept somewhere else
If you lose this key you cannot ship updates until Google resets it (days).

Never use the old leaked key (android/app/keystore_base64.txt) for Play.
Delete any local copies of it.

Done.
EOF
