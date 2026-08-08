# Prints Android SHA-1 / SHA-256 for Firebase Phone Auth (stops browser reCAPTCHA).
# Usage: powershell -File jobfrontend-main/scripts/print_android_sha.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== DEBUG keystore (flutter run / debug APK) ===" -ForegroundColor Cyan
$debugKs = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (-not (Test-Path $debugKs)) {
  Write-Host "Debug keystore not found at $debugKs"
} else {
  keytool -list -v -alias androiddebugkey -keystore $debugKs -storepass android -keypass android |
    Select-String -Pattern "SHA1:|SHA256:"
}

Write-Host ""
Write-Host "=== RELEASE keystore (if android/key.properties exists) ===" -ForegroundColor Cyan
$androidDir = Join-Path $PSScriptRoot "..\android"
$keyProps = Join-Path $androidDir "key.properties"
if (-not (Test-Path $keyProps)) {
  Write-Host "No key.properties - skip release fingerprints."
} else {
  $props = @{}
  Get-Content $keyProps | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') { $props[$matches[1].Trim()] = $matches[2].Trim() }
  }
  $storeFile = $props["storeFile"]
  $storePass = $props["storePassword"]
  $alias = $props["keyAlias"]
  $keyPass = $props["keyPassword"]
  if (-not $storeFile) {
    Write-Host "storeFile missing in key.properties"
  } else {
    if (-not [System.IO.Path]::IsPathRooted($storeFile)) {
      $storeFile = Join-Path $androidDir $storeFile
    }
    if (-not (Test-Path $storeFile)) {
      Write-Host "Release keystore not found: $storeFile"
    } else {
      keytool -list -v -alias $alias -keystore $storeFile -storepass $storePass -keypass $keyPass |
        Select-String -Pattern "SHA1:|SHA256:"
    }
  }
}

Write-Host ""
Write-Host "Add BOTH SHA-1 and SHA-256 in Firebase Console:" -ForegroundColor Yellow
Write-Host "  Project settings -> Your apps -> Android (com.joballocate.careers) -> Add fingerprint"
Write-Host "Then enable Play Integrity API in Google Cloud for project joballocate."
Write-Host "Re-download google-services.json and replace android/app/google-services.json"
Write-Host ""
