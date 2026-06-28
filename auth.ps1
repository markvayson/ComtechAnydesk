# ====================================================================
# ALL-IN-ONE HYBRID CONFIG LOADER
# ====================================================================

$StoredHash = "XwXClStMclCMaWoq4/oD8le44zfneH9Tei6iA4vadLM="
$CsvUrl         = "https://docs.google.com/spreadsheets/d/e/2PACX-1vS6vCWnm35OQf2IHjbNoxKwnCZwiFhUAhggkBib84yRGkQzOCTBCWjT003UMywIgVcrFMCP_jU6Sf_8/pub?gid=0&single=true&output=csv"
$WebAppUrl      = "https://script.google.com/macros/s/AKfycbylzTZlgIj-9_J8HH2JAQsqrmqrkRG-1vPVL4cWFbExuvXcU7wnbYlOIgrT3mS8Nc4f/exec"



$Global:DevMode = $false 

if ($Global:DevMode) {
    Write-Host "`n[!] DEV MODE ENABLED: Bypassing Security Gateway..." -ForegroundColor Magenta
    $Global:AuthSuccess = $true
    return # This exits the auth script immediately, returning to launcher
}




# === OPTIMIZED UI GATEKEEPER ===
$Authenticated = $false
$Attempts = 0
$MaxAttempts = 3
$ErrorMessage = ""

while (-not $Authenticated -and $Attempts -lt $MaxAttempts) {
    Clear-Host
    Write-Host "`n  +====================================================================+" -ForegroundColor DarkGray
    Write-Host "  |                      COMTECH SYSTEMS COMPUTER                      |" -ForegroundColor DarkGray
    Write-Host "  |                           SECURE GATEWAY                           |" -ForegroundColor DarkGray
    Write-Host "  +====================================================================+`n" -ForegroundColor DarkGray

    if ($ErrorMessage) { Write-Host "  $ErrorMessage`n" -ForegroundColor Red }

    $Attempts++
    Write-Host "  [?] Master Password: " -NoNewline -ForegroundColor Yellow
    
    $SecureInput = Read-Host -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureInput)
    $PlainInput = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # Reduced delay for snappy feel
    Write-Host "  [*] Verifying... " -NoNewline -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 200 
    
    $InputBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainInput)
    $InputHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($InputBytes)
    $InputHashString = [System.Convert]::ToBase64String($InputHash)

    if ($InputHashString -eq $StoredHash) {
        $Authenticated = $true
    
        
    } else {
        $Remaining = $MaxAttempts - $Attempts
        $ErrorMessage = "[!] Invalid credentials. ($Remaining attempts remaining)"
        if ($Remaining -gt 0) { Start-Sleep -Milliseconds 100 }
    }
}
if (-not $Authenticated) {
    $Global:AuthSuccess = $false # Set a global flag
} else {
    $Global:AuthSuccess = $true
}

$Script:AuthResult = $Authenticated