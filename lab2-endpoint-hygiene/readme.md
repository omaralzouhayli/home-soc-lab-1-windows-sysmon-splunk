# Lab 2 - Endpoint Security with PowerShell and Microsoft Defender

This lab builds on the Windows monitoring environment from Lab 1. Lab 1 focused on Windows logs, Sysmon, Splunk, and detections (described in the root `README.md`).

Lab 2 stays on the same Windows 11 VM (`WIN-ENDPOINT-01`) but shifts the focus to **endpoint hygiene** and **Microsoft Defender Antivirus**. The goal is to have something you can actually run on a workstation during basic triage:

- A small PowerShell script that checks Defender and firewall state.
- A quick hygiene checklist built around the script output.
- A short triage note for handling a Defender malware alert (using the EICAR test file in this lab).

---

## Folder Layout (Lab 2)

All Lab 2 content lives under:

```text
lab2-endpoint-hygiene/
  scripts/
  runbooks/
  screenshots/
  notes/
  lab-journal.md
  README.md
```

Key files:

- `scripts/Get-EndpointHygiene.ps1`  
  PowerShell script that checks Defender status, firewall profiles, and Controlled Folder Access, then prints a **Pass / Warn / Fail** summary.

- `runbooks/endpoint-hygiene-checklist.md`  
  Short checklist for running the script and interpreting the results on a single endpoint.

- `runbooks/defender-malware-alert-triage.md`  
  Mini triage guide for a Defender malware alert on `WIN-ENDPOINT-01`, built around the EICAR test event.

- `lab-journal.md`  
  Build log with step-by-step notes and references to the screenshots used during the lab.

- `screenshots/`  
  Evidence from the lab (Windows Security views, script output, EICAR detection, etc.).

The `notes/` folder is reserved for any future scratch notes or ideas and can stay empty for now.

---

## Get-EndpointHygiene.ps1 – What it checks

The script is meant to be simple to read and adjust. It runs locally on the Windows 11 VM and:

1. Uses `Get-MpComputerStatus` to collect Defender state, including:
   - Real-time protection
   - Last quick scan time
   - Signature version and last update time

2. Uses `Get-MpPreference` to look at:
   - `EnableControlledFolderAccess` (Controlled Folder Access / ransomware protection mode)

3. Uses `Get-NetFirewallProfile` to pull per-profile firewall status:
   - Domain / Private / Public
   - Whether each profile is enabled

4. Builds a small **Pass / Warn / Fail** summary table that covers:
   - Defender real-time protection
   - Quick scan recency
   - Signature age
   - Firewall profiles
   - Ransomware protection / Controlled Folder Access

The idea is that the summary table can be pasted directly into a ticket or investigation note.

---

## How to Run the Hygiene Script

On `WIN-ENDPOINT-01`:

1. Copy `Get-EndpointHygiene.ps1` onto the VM  
   (for example, Desktop or `C:\Tools\`).

2. In an elevated PowerShell window (Run as Administrator), allow scripts for the current user (done once):

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

3. Run the script:

   ```powershell
   cd <folder_where_script_lives>
   .\Get-EndpointHygiene.ps1
   ```

4. Review:
   - The Defender and firewall sections.
   - The **Hygiene Summary (Pass/Warn/Fail)** at the end.

For more detailed narrative and troubleshooting notes, see `lab-journal.md`.

---

## Defender Malware Test (EICAR) – High-Level

To verify that Defender is actually blocking malware (not just “enabled”):

1. Create the standard EICAR test file on the Desktop using Notepad.  
   (Exact string and details are in `lab-journal.md`.)

2. Save the file and wait for Defender to react:
   - Real-time protection should detect and quarantine the file immediately.

3. Open **Windows Security → Virus & threat protection → Protection history**:
   - Confirm the EICAR detection entry.
   - Expand it to see the threat name, severity, action, and affected file.

Screenshots of this process live in `screenshots/` and are referenced from the journal and the malware triage runbook.

---

## Runbooks

Two short documents turn this lab into something reusable:

- **Endpoint hygiene checklist**  
  `runbooks/endpoint-hygiene-checklist.md`  
  A quick list of steps for checking Defender, firewall, Controlled Folder Access, Protection history, and (optionally) Windows Update on a single endpoint.

- **Defender malware alert triage**  
  `runbooks/defender-malware-alert-triage.md`  
  A small L1-style flow for:
  - Confirming the alert in Protection history
  - Verifying the endpoint
  - Running the hygiene script
  - Triggering scans/updates if needed
  - Documenting and escalating when appropriate

Together with the script and screenshots, these files document a repeatable workflow for reviewing Defender alerts and endpoint security controls on a Windows 11 workstation.
