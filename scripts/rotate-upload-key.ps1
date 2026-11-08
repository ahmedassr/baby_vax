#Requires -Version 5.1
<#
.SYNOPSIS
  Rotate the Baby Vax Play upload key (Windows).

.DESCRIPTION
  powershell -ExecutionPolicy Bypass -File scripts\rotate-upload-key.ps1

  1. checks keytool (JDK 17+) and gh (logged in, can see the repo)
  2. asks for the store and key passwords (hidden, typed twice)
  3. creates %USERPROFILE%\keys\babyvax-upload.jks (refuses to overwrite it)
  4. sets the GitHub Actions secrets the CI workflow reads
  5. writes android\key.properties (gitignored) for local release builds
  6. prints the SHA-1 / SHA-256 fingerprints
  7. reminds you to back the key up

  Passwords are never put on a command line, echoed, or written anywhere
  except android\key.properties (readable by you only). They reach keytool
  through that child process's environment only (-storepass:env), and gh
  through stdin. Read-Host input is not saved to PowerShell history.

  Safe to re-run: if the keystore already exists, the script offers to reuse
  it (after verifying the password) to redo steps 4-6.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Repo     = 'ahmedassr/baby_vax'
$Alias    = 'upload'
$KeyDir   = Join-Path $HOME 'keys'
$Keystore = Join-Path $KeyDir 'babyvax-upload.jks'

# The four secret names read by .github/workflows/ci.yml. Keep in sync.
$SecretKeystoreBase64   = 'KEYSTORE_BASE64'
$SecretKeystorePassword = 'KEYSTORE_PASSWORD'
$SecretKeyPassword      = 'KEY_PASSWORD'
$SecretKeyAlias         = 'KEY_ALIAS'

$Root     = Split-Path -Parent $PSScriptRoot
$KeyProps = Join-Path $Root 'android\key.properties'

function Fail([string]$Message) {
    Write-Host ''
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}
function Step([string]$Message) { Write-Host ''; Write-Host "==> $Message" -ForegroundColor Cyan }

# Quotes one argument for a Windows command line. Only paths and fixed words
# go through here, never a password.
function Quote-Arg([string]$Value) {
    if ($Value -notmatch '[\s"]') { return $Value }
    return '"' + ($Value -replace '"', '\"') + '"'
}

# Runs a native program without exposing secrets on its command line.
#  -Env       extra environment variables for THIS child process only
#  -StdinText written to the child's stdin, no trailing newline
#  -Capture   return stdout+stderr instead of passing them through
# Returns an object with ExitCode and Output.
function Invoke-Native {
    param(
        [Parameter(Mandatory)] [string]   $FilePath,
        [string[]]  $Arguments = @(),
        [hashtable] $Env = @{},
        [string]    $StdinText = $null,
        [switch]    $Capture
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = ($Arguments | ForEach-Object { Quote-Arg $_ }) -join ' '
    $psi.UseShellExecute = $false
    foreach ($k in $Env.Keys) { $psi.EnvironmentVariables[$k] = $Env[$k] }
    $hasStdin = $PSBoundParameters.ContainsKey('StdinText')
    $psi.RedirectStandardInput  = $hasStdin
    $psi.RedirectStandardOutput = [bool]$Capture
    $psi.RedirectStandardError  = [bool]$Capture

    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $null; $errTask = $null
    if ($Capture) {
        $outTask = $p.StandardOutput.ReadToEndAsync()
        $errTask = $p.StandardError.ReadToEndAsync()
    }
    if ($hasStdin) {
        $p.StandardInput.Write($StdinText)
        $p.StandardInput.Close()
    }
    $p.WaitForExit()
    $output = ''
    if ($Capture) { $output = $outTask.Result + $errTask.Result }
    # Drop the child's copy of the secret from the start info.
    foreach ($k in $Env.Keys) { $psi.EnvironmentVariables.Remove($k) }
    return [pscustomobject]@{ ExitCode = $p.ExitCode; Output = $output }
}

function Read-Hidden([string]$Prompt) {
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try   { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr); $secure.Dispose() }
}

# Rules that keep the password intact through every place it travels:
#  - printable ASCII, no spaces: Gradle reads key.properties as ISO-8859-1
#    and java.util.Properties trims leading whitespace
#  - no backslash: Properties treats it as an escape character
function Test-Password([string]$Pw, [int]$Min) {
    if ($Pw.Length -lt $Min) { Write-Host "  Too short: use at least $Min characters."; return $false }
    if ($Pw -cnotmatch '^[\x21-\x7E]+$') { Write-Host '  Use printable ASCII only: no spaces, tabs or non-Latin letters.'; return $false }
    if ($Pw.Contains('\')) { Write-Host '  No backslashes, please (key.properties treats them as escapes).'; return $false }
    return $true
}

function Ask-Password([string]$Label, [int]$Min) {
    while ($true) {
        $a = Read-Hidden "${Label}"
        if (-not (Test-Password $a $Min)) { $a = $null; continue }
        $b = Read-Hidden "${Label} (again)"
        if ($a -cne $b) { Write-Host '  The two entries do not match. Try again.'; $a = $null; $b = $null; continue }
        $b = $null
        return $a
    }
}

# Restricts a file to the current user (best effort; warns on failure).
function Protect-File([string]$Path) {
    $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $r = Invoke-Native -FilePath 'icacls.exe' -Arguments @($Path, '/inheritance:r', '/grant:r', "${me}:F") -Capture
    if ($r.ExitCode -ne 0) { Write-Host "  WARNING: could not restrict permissions on $Path" -ForegroundColor Yellow }
}

$StorePass = $null
$KeyPass   = $null
try {
    # ------------------------------------------------------------ 1. checks
    Step 'Checking prerequisites'

    if ([Console]::IsInputRedirected) { Fail 'Run this in an interactive terminal (passwords are typed, never piped).' }

    $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
    if (-not $keytoolCmd -and $env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
        if (Test-Path $candidate) { $keytoolCmd = Get-Item $candidate }
    }
    if (-not $keytoolCmd) {
        Fail "keytool not found. Install a JDK 17+ and put its bin\ on PATH:`n  winget install EclipseAdoptium.Temurin.17.JDK"
    }
    $Keytool = if ($keytoolCmd -is [System.Management.Automation.CommandInfo]) { $keytoolCmd.Source } else { $keytoolCmd.FullName }

    # keytool has no -version flag; -J-version asks its JVM instead.
    $v = Invoke-Native -FilePath $Keytool -Arguments @('-J-version') -Capture
    if ($v.Output -notmatch 'version "(\d+)(?:\.(\d+))?') { Fail "Could not read the Java version from keytool: $($v.Output)" }
    $javaMajor = [int]$Matches[1]
    if ($javaMajor -eq 1 -and $Matches[2]) { $javaMajor = [int]$Matches[2] }   # 1.8 -> 8
    if ($javaMajor -lt 17) { Fail "keytool is from Java $javaMajor; JDK 17 or newer is required." }
    Write-Host "keytool: Java $javaMajor ($Keytool)"

    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghCmd) { Fail "GitHub CLI (gh) not found. Install it, then run 'gh auth login':`n  winget install --id GitHub.cli" }
    $Gh = $ghCmd.Source

    if ((Invoke-Native -FilePath $Gh -Arguments @('auth', 'status') -Capture).ExitCode -ne 0) {
        Fail "gh is not logged in. Run: gh auth login"
    }
    if ((Invoke-Native -FilePath $Gh -Arguments @('repo', 'view', $Repo, '--json', 'name') -Capture).ExitCode -ne 0) {
        Fail "gh cannot see $Repo. Log in with an account that has admin access to it."
    }
    Write-Host "gh: logged in, $Repo reachable"

    # ------------------------------------------------------------ 2. mode
    $Mode = 'create'
    if (Test-Path -LiteralPath $Keystore) {
        $Mode = 'reuse'
        Write-Host ''
        Write-Host "$Keystore already exists. This script will NOT overwrite it."
        Write-Host 'You can reuse it to (re)set the GitHub secrets and key.properties,'
        Write-Host 'for example if an earlier run stopped at the gh step.'
        $answer = Read-Host "Type 'reuse' to continue with the existing keystore, anything else to stop"
        if ($answer -cne 'reuse') { Fail 'Stopped. Nothing was changed.' }
    }

    # ------------------------------------------------------------ 3. passwords
    Step 'Passwords'
    if ($Mode -eq 'create') {
        Write-Host 'Choose a long password (16+ characters is good; a password manager can'
        Write-Host 'generate one). Printable ASCII, no spaces, no backslash.'
        $StorePass = Ask-Password 'Store password' 12
    } else {
        $StorePass = Ask-Password 'Store password of the existing keystore' 6
    }

    Write-Host ''
    Write-Host 'Key password. A PKCS12 keystore has ONE password: keytool ignores a'
    Write-Host 'different key password, and the build would then fail to open the key.'
    Write-Host 'So enter the same password again here.'
    while ($true) {
        $KeyPass = Ask-Password 'Key password' 6
        if ($KeyPass -ceq $StorePass) { break }
        Write-Host '  The key password must equal the store password for PKCS12. Try again.'
        $KeyPass = $null
    }

    $pwEnv = @{ BV_STOREPASS = $StorePass; BV_KEYPASS = $KeyPass }

    # ------------------------------------------------------------ 4. keystore
    if ($Mode -eq 'create') {
        Step "Creating $Keystore"
        if (-not (Test-Path -LiteralPath $KeyDir)) { New-Item -ItemType Directory -Path $KeyDir | Out-Null }
        Protect-File $KeyDir
        if (Test-Path -LiteralPath $Keystore) { Fail "$Keystore appeared while the script was running. Not touching it." }
        Write-Host 'keytool will now ask for your name and organisation (any honest values).'
        $r = Invoke-Native -FilePath $Keytool -Env $pwEnv -Arguments @(
            '-genkeypair', '-v',
            '-keystore', $Keystore, '-storetype', 'PKCS12',
            '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-alias', $Alias,
            '-storepass:env', 'BV_STOREPASS', '-keypass:env', 'BV_KEYPASS')
        if ($r.ExitCode -ne 0) { Fail "keytool -genkeypair failed (exit $($r.ExitCode))." }
        Protect-File $Keystore
    }

    Step "Verifying the keystore opens with that password and has alias '$Alias'"
    $r = Invoke-Native -FilePath $Keytool -Env $pwEnv -Capture -Arguments @(
        '-list', '-keystore', $Keystore, '-alias', $Alias, '-storepass:env', 'BV_STOREPASS')
    if ($r.ExitCode -ne 0) { Fail "keytool could not open $Keystore with that password, or alias '$Alias' is missing." }
    Write-Host 'OK'

    # ------------------------------------------------------------ 5. secrets
    Step "Setting GitHub Actions secrets on $Repo"
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Keystore))   # unwrapped
    $secrets = [ordered]@{
        $SecretKeystoreBase64   = $b64
        $SecretKeystorePassword = $StorePass
        $SecretKeyPassword      = $KeyPass
        $SecretKeyAlias         = $Alias
    }
    foreach ($name in $secrets.Keys) {
        $r = Invoke-Native -FilePath $Gh -Arguments @('secret', 'set', $name, '--repo', $Repo) -StdinText $secrets[$name] -Capture
        if ($r.ExitCode -ne 0) { Fail "gh secret set $name failed:`n$($r.Output)`nRe-run this script and choose 'reuse'." }
        Write-Host "  set $name"
    }
    $secrets = $null; $b64 = $null

    # ------------------------------------------------------------ 6. key.properties
    Step 'Writing android\key.properties (gitignored)'
    $writeProps = $true
    if (Test-Path -LiteralPath $KeyProps) {
        $answer = Read-Host "android\key.properties already exists. Type 'replace' to overwrite it, anything else to keep it"
        if ($answer -cne 'replace') { $writeProps = $false }
    }
    if ($writeProps) {
        # Forward slashes: java.util.Properties would eat the backslashes.
        $storeFile = $Keystore -replace '\\', '/'
        $content = "# Local release signing. Gitignored; never commit. Written by scripts/rotate-upload-key.ps1`n" +
                   "storePassword=$StorePass`nkeyPassword=$KeyPass`nkeyAlias=$Alias`nstoreFile=$storeFile`n"
        [IO.File]::WriteAllText($KeyProps, $content, (New-Object System.Text.UTF8Encoding $false))
        $content = $null
        Protect-File $KeyProps
        Write-Host "Wrote $KeyProps"
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            $ci = Invoke-Native -FilePath $git.Source -Arguments @('-C', $Root, 'check-ignore', '-q', $KeyProps) -Capture
            if ($ci.ExitCode -eq 0) { Write-Host 'Confirmed: git ignores it.' }
            else { Write-Host "WARNING: git does NOT ignore $KeyProps. Do not commit it; fix .gitignore." -ForegroundColor Yellow }
        }
    } else {
        Write-Host "Kept the existing file. Make sure it points at $Keystore."
    }

    # ------------------------------------------------------------ 7. fingerprints
    Step 'Upload key fingerprints'
    $r = Invoke-Native -FilePath $Keytool -Env $pwEnv -Capture -Arguments @(
        '-list', '-v', '-keystore', $Keystore, '-alias', $Alias, '-storepass:env', 'BV_STOREPASS')
    $r.Output -split "`r?`n" | Where-Object { $_ -match '^\s*(SHA1|SHA256):' } | ForEach-Object { Write-Host $_ }
    $pwEnv = $null
    Write-Host @'

Where these go:
  - Play Console: nothing to paste. Play reads the upload certificate from
    your first signed upload.
  - Firebase: optional for this app. It signs in with email + password only
    (no Google Sign-In, no phone auth), so Auth needs no fingerprint. App
    Check / Play Integrity needs the SHA-256 of Google's APP SIGNING key
    (Play Console > Test and release > App integrity), not this upload key.
  - If the OLD key's fingerprints were ever added in Firebase, delete them.
'@

    # ------------------------------------------------------------ 8. backup
    Write-Host ''
    Write-Host '==> BACK UP THE KEY NOW. Do not skip this.' -ForegroundColor Yellow
    Write-Host @"

Copy BOTH of these to TWO places off this laptop:
    $Keystore
    the password you just typed
For example:
    1. your password manager (attach the .jks file, store the password with it)
    2. an encrypted USB stick (BitLocker To Go) kept somewhere else
If you lose this key you cannot ship updates until Google resets it (days).

Never use the old leaked key (android/app/keystore_base64.txt) for Play.
Delete any local copies of it.

Done.
"@
}
finally {
    $StorePass = $null; $KeyPass = $null; $pwEnv = $null
    [GC]::Collect()
}
