# Home SOC Lab 1 – Windows Endpoint + Sysmon + Splunk

This lab is a small **“Home SOC” mini-stack** built on a single Windows 11 VM:

- **Endpoint:** Windows 11 VM (`WIN-ENDPOINT-01`) acting like an employee laptop.
- **Telemetry:** Windows Security logs + Sysmon (SwiftOnSecurity config).
- **SIEM:** Splunk Enterprise Free running on the same VM.
- **Focus:** Junior SOC / Endpoint / Detection Engineer skills:
  - Collecting Windows + Sysmon logs
  - Writing detections in SPL
  - Simulating safe attacker behavior
  - Writing a PICERL incident report

> This is Lab 1 in a series of small blue-team labs I’m building while studying **ISC2 CC** and **Security+**.

---

## Lab Architecture

- **Host machine:** Windows (runs VMware Workstation Pro)
- **Guest VM:** Windows 11 Pro (`WIN-ENDPOINT-01`)
- **On the VM:**
  - Sysmon (`Sysmon64.exe`) with SwiftOnSecurity config
  - Splunk Enterprise Free (local install)
  - Windows event forwarding into Splunk index `endpoint`

Data flow (all on one box for simplicity):

`Windows 11 endpoint → Windows Event Log + Sysmon → Splunk index=endpoint → Searches & Alerts`

---

## Detections Implemented (SPL)

All SPL queries are stored under `detections\`.

1. **Repeated failed logons (possible brute force)**
   - File: `detections\failed_logons_spl.txt`
   - Data: `WinEventLog:Security` (EventCode 4625)
   - Logic: 4+ failed logons for the same account on the same host within 5 minutes
   - Alert name: **Possible brute force - multiple failed logons**

2. **Suspicious PowerShell execution**
   - File: `detections\suspicious_powershell_spl.txt`
   - Data: Sysmon Process Create (`XmlWinEventLog:Microsoft-Windows-Sysmon/Operational`)
   - Logic: `powershell.exe` with high-risk flags:
     - `-ExecutionPolicy Bypass`, `-EncodedCommand`, `-WindowStyle Hidden`, or `-nop`
   - Alert name: **Suspicious PowerShell execution**

3. **DNS queries from PowerShell (unusual outbound activity)**
   - File: `detections\unusual_dns_powershell_spl.txt`
   - Data: Sysmon DNS query events (Event ID 22)
   - Logic: DNS queries where the **Image** is `powershell.exe`
   - Alert name: **Unusual DNS query from PowerShell**

All three detections are configured as **scheduled alerts** in Splunk that log an event to the `main` index when they fire.

---

## Incident Reporting (PICERL)

Folder: `incident_reports\`

- **IR-001_Suspicious_PowerShell_PICERL.md**
  - Incident based on the *Suspicious PowerShell execution* detection.
  - Follows **PICERL**:
    - Preparation  
    - Identification  
    - Containment  
    - Eradication  
    - Recovery  
    - Lessons Learned
  - Includes:
    - Sysmon event details (Image, User, full command line)
    - What containment/eradication would look like in a real SOC
    - Lab-specific notes and next steps

---

## Build Journal

File: `lab-journal.md`

- Notes of how the lab was built:
  - VM & ISO setup
  - OOBE / account challenges and decisions
  - Sysmon install and config
  - Splunk install, index creation, and `inputs.conf` changes
  - Test activity + detections + incident report
- This is a **full walkthrough** for anyone who wants to recreate the lab.

---

## Screenshots

Folder: `screenshots\`

Key images (for documentation / GitHub):

- `01_folder_structure.png` – Lab folder layout on the host.
- `02_sysmon_eventviewer.png` – Sysmon Operational log showing events.
- `03_splunk_index_endpoint.png` – Splunk index / sourcetypes view.
- `04_detection1_failed_logons_search.png` – Failed logon detection search.
- `05_detection1_alert_config.png` – Brute-force alert configuration.
- `06_detection2_suspicious_powershell_search.png` – Suspicious PowerShell search.
- `07_detection3_dns_powershell_search.png` – DNS from PowerShell search.

(Names may vary slightly; these are examples of the intended content.)

---

## Folder Structure (local)

```text
D:\Home-SOC-Lab
  README.md
  lab-journal.md
  detections  incident_reports  screenshots  lab2-endpoint-hygiene\
  iso\          (Windows ISO – local only, NOT uploaded to GitHub)
  VMs\          (VMware files – local only, NOT uploaded to GitHub)
```

> When publishing to GitHub, the `iso\` and `VMs\` folders should be **excluded** (they are large and contain OS/licensed files).

---

## Additional Labs

- **Lab 2 – Endpoint Hygiene & Microsoft Defender** (`lab2-endpoint-hygiene/`)
  - Reuses `WIN-ENDPOINT-01` from Lab 1.
  - Adds `Get-EndpointHygiene.ps1` to check Defender status, signature/scan recency, firewall profiles, and ransomware protection.
  - Includes a short endpoint hygiene checklist and Defender malware alert triage notes, plus screenshots and a build journal.
