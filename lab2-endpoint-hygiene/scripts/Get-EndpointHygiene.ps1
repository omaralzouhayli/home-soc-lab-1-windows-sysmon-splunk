# Get-EndpointHygiene.ps1
# Draft v1.5 - Defender + Firewall + Ransomware (CFA) + Pass/Warn/Fail summary

Write-Host "=== Endpoint Hygiene Check (Draft v1.5) ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# Microsoft Defender status
# ----------------------------------------------------------------------

try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
} catch {
    Write-Host "ERROR: Unable to query Microsoft Defender status on this system." -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)"
    return
}

# --- Quick scan age (days) ---

$quickScanTime = $mp.QuickScanEndTime
$quickScanAgeDays = $null

if ($quickScanTime -is [datetime] -and $quickScanTime -gt [datetime]::MinValue) {
    # (Get-Date) - $quickScanTime (not Get-Date - $quickScanTime)
    $quickScanAgeDays = [math]::Round(((Get-Date) - $quickScanTime).TotalDays, 1)
}

# --- Signature age (hours) ---

$signatureTime = $mp.AntivirusSignatureLastUpdated
$signatureAgeHours = $null

if ($signatureTime -is [datetime] -and $signatureTime -gt [datetime]::MinValue) {
    $signatureAgeHours = [math]::Round(((Get-Date) - $signatureTime).TotalHours, 1)
}

$defenderSummary = [PSCustomObject]@{
    RealTimeProtectionEnabled = $mp.RealTimeProtectionEnabled
    CloudProtectionEnabled    = $mp.CloudProtectionEnabled
    BehaviorMonitoringEnabled = $mp.BehaviorMonitorEnabled
    QuickScanEndTime          = $quickScanTime
    QuickScanAgeDays          = $quickScanAgeDays
    AntivirusSignatureVersion = $mp.AntivirusSignatureVersion
    SignatureLastUpdated      = $signatureTime
    SignatureAgeHours         = $signatureAgeHours
}

Write-Host "---- Microsoft Defender ----" -ForegroundColor Yellow
$defenderSummary | Format-List
Write-Host ""

# ----------------------------------------------------------------------
# Defender preferences (e.g., ransomware / Controlled Folder Access)
# ----------------------------------------------------------------------

$mpPref = $null
$cfaMode = $null  # Controlled Folder Access mode

try {
    $mpPref = Get-MpPreference -ErrorAction Stop
    $cfaMode = $mpPref.EnableControlledFolderAccess
} catch {
    Write-Host "WARNING: Unable to query Defender preferences (e.g., Controlled Folder Access)." -ForegroundColor DarkYellow
}

if ($mpPref) {
    Write-Host "---- Defender Preferences (subset) ----" -ForegroundColor Yellow
    [PSCustomObject]@{
        EnableControlledFolderAccess = $cfaMode
    } | Format-List
    Write-Host ""
}

# ----------------------------------------------------------------------
# Windows Firewall status
# ----------------------------------------------------------------------

$firewallProfiles = $null

try {
    $firewallProfiles = Get-NetFirewallProfile -ErrorAction Stop |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
} catch {
    Write-Host "ERROR: Unable to query Windows Firewall profiles on this system." -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)"
}

if ($firewallProfiles) {
    Write-Host "---- Windows Firewall Profiles ----" -ForegroundColor Yellow
    $firewallProfiles | Format-Table -AutoSize
    Write-Host ""
} else {
    Write-Host "No firewall profile data available." -ForegroundColor DarkYellow
    Write-Host ""
}

# ----------------------------------------------------------------------
# Pass / Warn / Fail hygiene summary
# ----------------------------------------------------------------------

$summary = @()

# 1) Defender real-time protection
if ($mp.RealTimeProtectionEnabled) {
    $summary += [PSCustomObject]@{
        Control = "Defender real-time protection"
        Status  = "Pass"
        Details = "Real-time protection is enabled."
    }
} else {
    $summary += [PSCustomObject]@{
        Control = "Defender real-time protection"
        Status  = "Fail"
        Details = "Real-time protection is DISABLED."
    }
}

# 2) Defender quick scan recency
if ($quickScanAgeDays -eq $null) {
    $summary += [PSCustomObject]@{
        Control = "Defender quick scan recency"
        Status  = "Fail"
        Details = "No quick scan time reported. Run a quick scan."
    }
} elseif ($quickScanAgeDays -le 7) {
    $summary += [PSCustomObject]@{
        Control = "Defender quick scan recency"
        Status  = "Pass"
        Details = "Last quick scan ~${quickScanAgeDays} days ago."
    }
} elseif ($quickScanAgeDays -le 14) {
    $summary += [PSCustomObject]@{
        Control = "Defender quick scan recency"
        Status  = "Warn"
        Details = "Last quick scan ~${quickScanAgeDays} days ago. Consider running a new scan."
    }
} else {
    $summary += [PSCustomObject]@{
        Control = "Defender quick scan recency"
        Status  = "Fail"
        Details = "Last quick scan ~${quickScanAgeDays} days ago. Scan is overdue."
    }
}

# 3) Defender signature age
if ($signatureAgeHours -eq $null) {
    $summary += [PSCustomObject]@{
        Control = "Defender signature age"
        Status  = "Fail"
        Details = "No signature update time reported. Check updates."
    }
} elseif ($signatureAgeHours -le 24) {
    $summary += [PSCustomObject]@{
        Control = "Defender signature age"
        Status  = "Pass"
        Details = "Signatures updated ~${signatureAgeHours} hours ago."
    }
} elseif ($signatureAgeHours -le 48) {
    $summary += [PSCustomObject]@{
        Control = "Defender signature age"
        Status  = "Warn"
        Details = "Signatures updated ~${signatureAgeHours} hours ago. Verify automatic updates."
    }
} else {
    $summary += [PSCustomObject]@{
        Control = "Defender signature age"
        Status  = "Fail"
        Details = "Signatures are stale (~${signatureAgeHours} hours). Force an update."
    }
}

# 4) Windows Firewall profiles
if ($firewallProfiles) {
    $disabledProfiles = $firewallProfiles | Where-Object { -not $_.Enabled }

    if ($disabledProfiles) {
        $names = ($disabledProfiles | Select-Object -ExpandProperty Name) -join ", "
        $summary += [PSCustomObject]@{
            Control = "Windows Firewall profiles"
            Status  = "Fail"
            Details = "Firewall disabled for profile(s): $names."
        }
    } else {
        $summary += [PSCustomObject]@{
            Control = "Windows Firewall profiles"
            Status  = "Pass"
            Details = "Firewall enabled on all profiles (Domain/Private/Public)."
        }
    }
} else {
    $summary += [PSCustomObject]@{
        Control = "Windows Firewall profiles"
        Status  = "Warn"
        Details = "Could not retrieve firewall profiles. Check local firewall configuration."
    }
}

# 5) Defender ransomware / Controlled Folder Access
if (-not $mpPref) {
    $summary += [PSCustomObject]@{
        Control = "Defender ransomware / Controlled Folder Access"
        Status  = "Warn"
        Details = "Could not query Defender preferences. Check CFA settings manually."
    }
} else {
    # According to Microsoft docs, EnableControlledFolderAccess is typically 0 (disabled), 1 or 2 (enabled/audit modes).
    if ($cfaMode -eq 0 -or $cfaMode -eq $null) {
        $summary += [PSCustomObject]@{
            Control = "Defender ransomware / Controlled Folder Access"
            Status  = "Fail"
            Details = "Controlled Folder Access appears to be DISABLED."
        }
    } else {
        $summary += [PSCustomObject]@{
            Control = "Defender ransomware / Controlled Folder Access"
            Status  = "Pass"
            Details = "Controlled Folder Access mode value: $cfaMode."
        }
    }
}

Write-Host "---- Hygiene Summary (Pass/Warn/Fail) ----" -ForegroundColor Yellow
$summary | Format-Table -AutoSize
