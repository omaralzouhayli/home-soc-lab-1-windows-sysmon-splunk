# Lab 2 – Endpoint Hygiene & Defender – Lab Journal

## Setup & Structure

- Reusing the same repo and root folder from Lab 1: `D:\it-support-lab\`.
- Created the Lab 2 folder structure:

  - `lab2-endpoint-hygiene\scripts\`
  - `lab2-endpoint-hygiene\screenshots\`
  - `lab2-endpoint-hygiene\runbooks\`
  - `lab2-endpoint-hygiene\notes\`

- Added a minimal `README.md` for Lab 2 instead of repeating all environment details from Lab 1.
- Confirmed I will reuse the same Windows 11 VM (`WIN-ENDPOINT-01`) from Lab 1.

## Baseline – Defender & Firewall

- Opened the Windows 11 VM (`WIN-ENDPOINT-01`) and logged in as `labadmin`.
- Opened **Windows Security** to confirm the built-in security stack is available.

  - Captured `01-windows-security-home.png` showing the main Windows Security dashboard.

- Checked **Virus & threat protection**:

  - Verified that Microsoft Defender Antivirus is active as the AV provider.
  - Noted the current status of real-time protection and cloud-delivered protection.
  - Observed the current "last scan" information (if any).
  - Captured `02-defender-virus-threat.png` as a baseline reference.

- Checked **Firewall & network protection**:

  - Reviewed the status of Domain, Private, and Public network profiles.
  - Noted which profile is currently active and whether the firewall is reported as On/Off.
  - Captured `03-firewall-network-status.png` as a baseline reference.

- No settings were changed in this step; the goal was only to record the initial state before building any PowerShell hygiene checks.

## Defender Hygiene Script – Draft v1.2

- Tried to run `Get-EndpointHygiene.ps1` from the Desktop and hit a PowerShell execution policy error:

  - Error: `running scripts is disabled on this system` (PSSecurityException).
  - This is expected on a default Windows 11 system where scripts are restricted.

- Updated the PowerShell execution policy **for the current user only**:

  - Command: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`
  - This allows locally created scripts to run for the `labadmin` account without loosening the policy for the whole machine.

- Created the first version of the endpoint hygiene script as `Get-EndpointHygiene.ps1` (stored under `lab2-endpoint-hygiene\scripts\` in the repo and copied to the VM Desktop for execution).

  - Script focus in v1.2:
    - Uses `Get-MpComputerStatus` to query Microsoft Defender status.
    - Collects key fields:
      - `RealTimeProtectionEnabled`
      - `CloudProtectionEnabled`
      - `BehaviorMonitoringEnabled`
      - `QuickScanEndTime`
      - `AntivirusSignatureVersion`
      - `AntivirusSignatureLastUpdated`
    - Calculates:
      - `QuickScanAgeDays` (days since the last quick scan)
      - `SignatureAgeHours` (hours since the last signature update)

- Hit a couple of issues while building the script and fixed them:

  - Initially assumed different property names and that all date fields would always be valid `DateTime` values.
  - Added checks to only perform date math when the underlying value is a valid `DateTime`.
  - Also ran into a parsing issue where `Get-Date - $quickScanTime` was interpreted as passing a `-Date` parameter instead of doing subtraction.
    - Fixed by changing it to `((Get-Date) - $quickScanTime)` so PowerShell clearly treats it as “current time minus scan time”.

- Result for `Get-EndpointHygiene.ps1` (v1.2):

  - Runs successfully on `WIN-ENDPOINT-01` with no errors.
  - Sample output at the time of testing:

    - `RealTimeProtectionEnabled`: `True`
    - `QuickScanEndTime`: `11/24/2025 12:34:07 PM`
    - `QuickScanAgeDays`: `0`
    - `AntivirusSignatureVersion`: `1.441.463.0`
    - `SignatureLastUpdated`: `11/24/2025 5:01:22 AM`
    - `SignatureAgeHours`: `7.9`

- Captured `04-endpoint-hygiene-defender-v1.png` showing the script output in an elevated PowerShell session.

- At this stage the script surfaced raw Defender hygiene data only. Firewall checks and Pass/Warn/Fail logic were added in later iterations.

## Defender and Firewall Hygiene Script Updates

- Updated `Get-EndpointHygiene.ps1` to include Windows Firewall checks alongside the existing Microsoft Defender hygiene checks.

- Defender section (behavior from v1.2 kept the same):

  - Uses `Get-MpComputerStatus` to pull:
    - `RealTimeProtectionEnabled`
    - `CloudProtectionEnabled`
    - `BehaviorMonitoringEnabled`
    - `QuickScanEndTime`
    - `AntivirusSignatureVersion`
    - `AntivirusSignatureLastUpdated`
  - Calculates:
    - `QuickScanAgeDays` (days since the last quick scan)
    - `SignatureAgeHours` (hours since the last signature update)
  - Outputs these fields in a dedicated "Microsoft Defender" section.

- New Firewall section:

  - Uses `Get-NetFirewallProfile` to retrieve per-profile settings.
  - Selects the following fields for each profile:
    - `Name` (Domain, Private, Public)
    - `Enabled`
    - `DefaultInboundAction`
    - `DefaultOutboundAction`
  - Displays the results as a table under a "Windows Firewall Profiles" heading.
  - This mirrors what an endpoint/SOC analyst would quickly check:
    - Is the firewall enabled on all profiles?
    - Are inbound and outbound defaults explicitly configured or left to inherited defaults?

- Example output from one run of the script on `WIN-ENDPOINT-01`:

  - Defender:
    - `RealTimeProtectionEnabled`: `True`
    - `QuickScanEndTime`: `11/24/2025 12:34:07 PM`
    - `QuickScanAgeDays`: `0.3`
    - `AntivirusSignatureVersion`: `1.441.463.0`
    - `SignatureLastUpdated`: `11/24/2025 5:01:22 AM`
    - `SignatureAgeHours`: `13.6`
  - Windows Firewall profiles (from `Get-NetFirewallProfile`):
    - Domain: `Enabled = True`, `DefaultInboundAction = NotConfigured`, `DefaultOutboundAction = NotConfigured`
    - Private: `Enabled = True`, `DefaultInboundAction = NotConfigured`, `DefaultOutboundAction = NotConfigured`
    - Public: `Enabled = True`, `DefaultInboundAction = NotConfigured`, `DefaultOutboundAction = NotConfigured`

- Captured `05-firewall-profiles-v1.png` showing both the Defender hygiene summary and the firewall profile table from a single script run.

- At this point the script still returned raw data only. A Pass/Warn/Fail style summary and additional checks (for example, ransomware protection / controlled folder access) were added in later steps.

## Pass / Warn / Fail Hygiene Summary

- Extended the script to add a Pass/Warn/Fail style summary at the end.

- The summary builds a small table of checks that an L1 SOC / endpoint analyst would care about:

  - **Defender real-time protection**
    - Pass if `RealTimeProtectionEnabled` is `True`.
    - Fail if real-time protection is disabled.

  - **Defender quick scan recency**
    - Uses `QuickScanAgeDays`:
      - Pass if `<= 7` days.
      - Warn if `> 7` and `<= 14` days.
      - Fail if `> 14` days or if no quick scan time is reported.
    - This models a basic expectation that endpoints should run frequent AV scans.

  - **Defender signature age**
    - Uses `SignatureAgeHours`:
      - Pass if `<= 24` hours.
      - Warn if `> 24` and `<= 48` hours.
      - Fail if `> 48` hours or if no signature update time is reported.
    - Idea: signatures should normally be updated at least once a day.

  - **Windows Firewall profiles**
    - Evaluates data from `Get-NetFirewallProfile`.
    - Pass if all profiles (Domain, Private, Public) report `Enabled = True`.
    - Fail if any profile is disabled.
    - Warn if no firewall profile data could be retrieved.

- The script now produces three layers of output:
  1. Raw Defender hygiene data.
  2. Raw Windows Firewall profile data.
  3. A concise Pass/Warn/Fail summary table that can be pasted into a ticket or incident note.

- Captured `06-hygiene-summary-v1.png` showing the hygiene summary table for `WIN-ENDPOINT-01`.

## Ransomware / Controlled Folder Access Check

- Extended `Get-EndpointHygiene.ps1` to include a basic ransomware protection check using Microsoft Defender's Controlled Folder Access (CFA) setting.

- Added a small Defender preferences section:

  - Calls `Get-MpPreference` and reads the `EnableControlledFolderAccess` value.
  - Prints a subset of preferences under a "Defender Preferences (subset)" heading to show the current CFA mode.

- Integrated CFA into the Pass/Warn/Fail summary:

  - New control: **"Defender ransomware / Controlled Folder Access"**.
  - Logic:
    - If Defender preferences cannot be queried, mark as **Warn** and note that CFA should be checked manually.
    - If `EnableControlledFolderAccess` is `0` or `$null`, mark as **Fail** with a note that CFA appears to be disabled.
    - If `EnableControlledFolderAccess` is non-zero (e.g., 1 or 2), mark as **Pass** and include the numeric mode value in the details.

- This matches what the Windows Security UI shows under **Ransomware protection** (yellow warning that ransomware protection needs to be set up) and makes that gap visible in the script output instead of only in the GUI.

- Captured `07-cfa-check-v1.png` showing the Defender preferences subset and the updated hygiene summary row for Controlled Folder Access.

## Defender Test Alert – EICAR

- Used the standard **EICAR test string** to generate a safe Microsoft Defender alert on `WIN-ENDPOINT-01`.

- Steps taken:

  - Opened Notepad as `labadmin` on the VM.
  - Pasted the official EICAR test string into a new file as a single line:
    - `X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*`
  - Saved the file to the Desktop as `eicar-test.com`.

- Result:

  - Microsoft Defender immediately detected the file and raised an alert.
  - The file was automatically quarantined/removed from the Desktop by Defender's real-time protection.

- Evidence collected:

  - `08-eicar-detection-toast.png` – Defender toast notification (if visible at the time of detection).
  - `09-eicar-protection-history.png` – Windows Security → Virus & threat protection → Protection history entry showing the detection details for `eicar-test.com`.

- This confirms that:

  - Defender real-time protection is not only enabled (as reported by the hygiene script) but also actively blocking test malware.
  - The endpoint can generate malware alerts that an L1 SOC / endpoint analyst would triage.

## Defender Detection Details (EICAR)

- Opened **Windows Security → Virus & threat protection → Protection history** on `WIN-ENDPOINT-01`.

- Observed two malware events related to the EICAR test file created on the Desktop:
  - **Threat blocked** (severity: Severe).
  - **Threat quarantined** (severity: Severe).

- The expanded details for the EICAR event show that:
  - Microsoft Defender Antivirus detected the EICAR test file saved as `C:\Users\labadmin\Desktop\eicar-test.com`.
  - The threat was automatically blocked and then quarantined by real-time protection.
  - The detection time in Protection history matches the moment the file was saved in Notepad.

- This confirms that:
  - Defender is enforcing real-time protection (the file cannot remain on disk).
  - The event is fully visible to an analyst through the Protection history view, with severity and action clearly labeled.

- Captured `10-eicar-protection-details.png` showing the expanded Protection history entry for the EICAR detection (including severity, status, and affected item path).

## Endpoint Hygiene Checklist Document

- Created `runbooks/endpoint-hygiene-checklist.md` as a short, L1-friendly checklist for assessing basic endpoint hygiene on a Windows 11 device.

- The checklist assumes the analyst will:
  - Run `Get-EndpointHygiene.ps1` in an elevated PowerShell session.
  - Use the Pass/Warn/Fail summary to quickly evaluate:
    - Defender real-time protection
    - Defender signature age
    - Defender quick scan recency
    - Windows Firewall profiles
    - Defender ransomware / Controlled Folder Access
  - Cross-check recent malware activity via **Windows Security → Protection history**.
  - Optionally review **Windows Update** for obvious patching gaps.

- The final step in the checklist is to paste the hygiene summary table and attach screenshots to the ticket or case notes, mirroring what a junior SOC / endpoint analyst would do during initial triage.

## Defender Malware Alert Triage Runbook

- Created `runbooks/defender-malware-alert-triage.md` as a short triage guide for Microsoft Defender malware alerts on a Windows 11 endpoint (for example, `WIN-ENDPOINT-01`).

- The runbook focuses on:
  - Confirming the alert details in **Windows Security → Protection history**.
  - Verifying the endpoint identity.
  - Running `Get-EndpointHygiene.ps1` and pasting the Pass/Warn/Fail summary into the ticket.
  - Assessing whether the threat was blocked/quarantined or may have executed.
  - Triggering scans or updates when needed.
  - Documenting evidence and escalating when appropriate.

- This ties the technical script work to a realistic first-response workflow that could be reused for real Defender alerts, not just the EICAR test case from this lab.

## Lab 2 README

- Updated `lab2-endpoint-hygiene/README.md` to describe:
  - The endpoint hygiene script and its Pass/Warn/Fail summary.
  - The endpoint hygiene checklist.
  - The Defender EICAR test scenario and the malware alert triage runbook.
- The README explains how to run the script and reproduce the EICAR test on `WIN-ENDPOINT-01` without repeating all of the detailed build notes from this journal.
