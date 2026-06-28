# === CHECK AUTHENTICATION FIRST ===
# Check if running locally in your VS Code folder
if (Test-Path "$PSScriptRoot\auth.ps1") {
    . "$PSScriptRoot\auth.ps1"
} else {
    # Fallback to the cloud when deployed to a remote machine
    irm https://gist.githubusercontent.com/markvayson/871ad5d15704bff310166dffdc33589e/raw/auth.ps1 | iex
}

if ($Global:AuthSuccess -eq $true) {
    
    # === MAIN LAUNCHER LOOP ===
    while ($true) { 

  try {
        # Fetch directly from the WebApp bypass route with a token to prevent Windows caching
        $LiveUrl = "${WebAppUrl}?action=read&token=$(Get-Date -UFormat %s)"
        
        $AntiCacheHeaders = @{
            "Cache-Control" = "no-cache, no-store, must-revalidate"
            "Pragma"        = "no-cache"
            "Expires"       = "0"
        }

        # Pulls live data instantly, automatically converts from JSON, and sorts alphabetically
        $Data = Invoke-RestMethod -Uri $LiveUrl -Method Get -Headers $AntiCacheHeaders | Sort-Object -Property Facility
        $LastUpdated = Get-Date -Format "HH:mm:ss"
    } catch {
        Write-Host "ERROR: Could not fetch live data. Check connection." -ForegroundColor Red
        Start-Sleep -Seconds 3
        continue
    }
    Clear-Host
    
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "              ANYDESK FACILITY LAUNCHER TEST VERSION                        " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host " Last Sync: $LastUpdated" -ForegroundColor DarkGray
    if ($Global:DevMode -eq $true) {
            Write-Host " MODE: DEVELOPMENT / BYPASS ENABLED" -ForegroundColor Magenta
        }
    
    Write-Host " #  - FACILITY NAME                     | ANYDESK ID      | STATUS        " -ForegroundColor Gray
    Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray

    for ($i = 0; $i -lt $Data.Count; $i++) {
        $Row = $Data[$i]
        $DisplayID  = ($i + 1).ToString()
        $FacName    = $Row.Facility
        $DeskID     = $Row.AnyDeskID
        $Status     = $Row.Status
        
        $IdPad      = $DisplayID.PadRight(3)
        $FacPad     = ([string]$FacName).PadRight(35)
        if ($FacPad.Length -gt 35) { $FacPad = $FacPad.Substring(0, 35) }
        $DeskPad    = ([string]$DeskID).PadRight(15)
        
        Write-Host " $IdPad" -ForegroundColor Yellow -NoNewline
        Write-Host "- $FacPad" -ForegroundColor White -NoNewline
        Write-Host "| $DeskPad" -ForegroundColor Cyan -NoNewline
        
        Write-Host "| " -ForegroundColor White -NoNewline
        if ($Status -match "Online") {
            Write-Host "$Status" -ForegroundColor Green
        } elseif ($Status -match "Offline") {
            Write-Host "$Status" -ForegroundColor Red
        } else {
            Write-Host "$Status" -ForegroundColor Gray
        }
    }

    Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host " [A] Add Facility  |  [U] Update/Remove  |  [R] Refresh Data  |  [Q] Quit" -ForegroundColor Yellow
    Write-Host ""
    
    $Selection = Read-Host "Enter ID to connect, or a letter to choose an action"

    if ($Selection -eq "q" -or $Selection -eq "Q") { break }

    # === ADD FACILITY ===
    if ($Selection -eq "a" -or $Selection -eq "A") {
        Write-Host "`n--- ADD NEW FACILITY ---" -ForegroundColor Cyan
        $NewFac  = Read-Host "Enter Facility Name"
        $NewDesk = Read-Host "Enter AnyDesk ID (Numbers only)"
        
        $EncodedFac = [Uri]::EscapeDataString($NewFac)
        $EncodedDesk = [Uri]::EscapeDataString($NewDesk)
        $Url = "${WebAppUrl}?action=add&facility=${EncodedFac}&anydesk=${EncodedDesk}"
        
        $Response = Invoke-RestMethod -Uri $Url -Method Get
        Write-Host "Result: $Response" -ForegroundColor Green
        Start-Sleep -Seconds 2
    }

    # === REFRESH ===
    if ($Selection -eq "r" -or $Selection -eq "R") {
        Write-Host "`n--- Refreshing ---" -ForegroundColor Cyan
        Start-Sleep -Seconds 2
    }

   # === MANAGE / UPDATE FACILITY ===
   elseif ($Selection -eq "u" -or $Selection -eq "U") {
        Write-Host "`n--- MANAGE FACILITY ---" -ForegroundColor Cyan
        $TargetNum = Read-Host "Enter the ID number to manage"
        
        if ($TargetNum -match '^\d+$' -and [int]$TargetNum -ge 1 -and [int]$TargetNum -le $Data.Count) {
            
            # Sub-menu loop starts here
            while ($true) {
                # Dynamically track the row object in case it was modified in the previous loop iteration
                $TargetRow    = $Data[[int]$TargetNum - 1]
                # Force string cast right away to prevent URL escape errors
                $CurrentDesk  = [string]$TargetRow.AnyDeskID
                $CurrentName  = $TargetRow.Facility
                $CurrentStatus = $TargetRow.Status

                # Show Sub-Menu UI
                Clear-Host
                Write-Host "`n  [ MANAGING FACILITY ]" -ForegroundColor Yellow
                Write-Host "  Name:       $CurrentName" -ForegroundColor White
                Write-Host "  AnyDesk ID: $CurrentDesk" -ForegroundColor White
                Write-Host "  Status:     $CurrentStatus" -ForegroundColor White
                Write-Host "  ------------------------------------" -ForegroundColor Gray
                Write-Host "  [1] Change Facility Name" -ForegroundColor White
                Write-Host "  [2] Change AnyDesk ID" -ForegroundColor White
                Write-Host "  [3] Change Status" -ForegroundColor White
                Write-Host "  [4] Remove Facility (DELETE)" -ForegroundColor Red
                Write-Host "  [B] Back to Main Menu" -ForegroundColor Yellow
                Write-Host ""
                
                $SubSelect = Read-Host "Choose an action (1-4, or B)"
                $Url = ""

                # Exit the sub-menu loop and return to the main facility dashboard
                if ($SubSelect -eq "b" -or $SubSelect -eq "B") { 
                    break 
                }

                # Option 1: Change Name
                if ($SubSelect -eq "1") {
                    $NewName = Read-Host "Enter new Facility Name"
                    if ($NewName) {
                        $Url = "${WebAppUrl}?action=editName&anydesk=$([Uri]::EscapeDataString($CurrentDesk))&newName=$([Uri]::EscapeDataString($NewName))"
                        $TargetRow.Facility = $NewName # Update local screen memory instantly
                    }
                }
                # Option 2: Change AnyDesk ID
                elseif ($SubSelect -eq "2") {
                    $NewDesk = Read-Host "Enter new AnyDesk ID"
                    if ($NewDesk) {
                        $Url = "${WebAppUrl}?action=editAnyDesk&anydesk=$([Uri]::EscapeDataString($CurrentDesk))&newAnydesk=$([Uri]::EscapeDataString($NewDesk))"
                        $TargetRow.AnyDeskID = $NewDesk # Update local screen memory instantly
                    }
                }
                # Option 3: Change Status
                elseif ($SubSelect -eq "3") {
                    $NewStatus = Read-Host "Enter new status (Online / Offline / Maintenance)"
                    if ($NewStatus) {
                        $Url = "${WebAppUrl}?action=update&anydesk=$([Uri]::EscapeDataString($CurrentDesk))&status=$([Uri]::EscapeDataString($NewStatus))"
                        $TargetRow.Status = $NewStatus # Update local screen memory instantly
                    }
                }
                # Option 4: Delete Entirely
                elseif ($SubSelect -eq "4") {
                    $Confirm = Read-Host "Are you sure you want to completely DELETE $CurrentName? (yes/no)"
                    if ($Confirm -eq "yes" -or $Confirm -eq "y") {
                        $Url = "${WebAppUrl}?action=delete&anydesk=$([Uri]::EscapeDataString($CurrentDesk))"
                        Write-Host "`nConnecting to database backend..." -ForegroundColor DarkGray
                        $Response = Invoke-RestMethod -Uri $Url -Method Get
                        Write-Host "Result: $Response" -ForegroundColor Green
                        Start-Sleep -Seconds 2
                        break # Drop out of sub-menu entirely since the item no longer exists
                    }
                }

                # Process the web request for updates without closing the sub-menu
                if ($Url -and $SubSelect -ne "4") {
                    Write-Host "`nConnecting to database backend..." -ForegroundColor DarkGray
                    $Response = Invoke-RestMethod -Uri $Url -Method Get
                    Write-Host "Result: $Response" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
        }
    }

    # === LAUNCH ANYDESK ===
    elseif ($Selection -match '^\d+$') {
        $num = [int]$Selection
        if ($num -ge 1 -and $num -le $Data.Count) {
            $TargetRow = $Data[$num - 1]
            # Wrap the cast in parentheses to ensure it becomes a string BEFORE .Replace() is called
            $CleanID = ([string]$TargetRow.AnyDeskID).Replace(" ", "")
            Write-Host "`nConnecting to $($TargetRow.Facility)..." -ForegroundColor Green
            cmd /c start "" "anydesk:$CleanID"
            Start-Sleep -Seconds 1
        }
    }
}

} else {
    # If not successful, stop here
    Write-Host "Access denied by security gateway." -ForegroundColor Red
    exit
}