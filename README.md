# Windows Endpoint Support Lab Portfolio (PowerShell, Defender, Nessus, Log Review)

This repo is my personal **Home Lab Portfolio** project. I use one Windows 11 VM as an “employee laptop” and build small labs around it to practice the kind of work a junior IT support / Security Analyst / M365 Security role does:

- Collecting and reviewing endpoint and identity telemetry  
- Writing detections and triage queries (SPL / KQL)  
- Investigating alerts/incidents and documenting decisions  
- Basic endpoint hygiene and vulnerability remediation

**Certifications:** ISC2 Certified in Cybersecurity (CC), CompTIA Security+ (SY0‑701)  
**Next:** Microsoft SC‑200 (Security Operations Analyst)

---

## Labs in this repo

1. **Lab 1 – Windows endpoint + Sysmon + Splunk** *(root of the repo)*  
   - Windows 11 VM `WIN-ENDPOINT-01`  
   - Sysmon (SwiftOnSecurity config) + Windows Security logs  
   - Splunk Enterprise Free ingestion  
   - SPL detections (failed logons, suspicious PowerShell, DNS from PowerShell)  
   - One PICERL incident report based on a lab alert

2. **Lab 2 – Endpoint hygiene + Microsoft Defender** (`lab2-endpoint-hygiene/`)  
   - PowerShell script `Get-EndpointHygiene.ps1` to check Defender status, firewall profiles, and ransomware protection  
   - EICAR test to generate a Defender alert  
   - Hygiene + alert triage runbooks

3. **Lab 3 – Vulnerability management with Nessus Essentials** (`lab3-vulnerability-management/`)  
   - Credentialed Nessus scans of `WIN-ENDPOINT-01`  
   - Before/after comparison and remediation notes  
   - Focus on WinVerifyTrust CVE‑2013‑3900 mitigation and VMware Tools findings

4. **Lab 4 – Microsoft Sentinel + Entra ID incident handling** (`lab4-sentinel-m365/`)  
   - Log Analytics workspace + Microsoft Sentinel  
   - Entra ID AuditLogs/SigninLogs ingestion  
   - Scheduled analytics rule for repeated failed sign-ins  
   - Incident generation, entity mapping (Account/IP), and triage workflow  
   - KQL triage pack + runbook

Each lab has its **own README and journal** inside its folder.

---

## How to use this repo

- Start with each lab’s `README.md` for the goal + outputs.  
- Use the lab’s `lab-journal.md` for the exact build steps.  
- Reusable detections and reports live at the repo root:
  - `detections/` (Lab 1 SPL queries)
  - `incident_reports/` (Lab 1 PICERL write-up)
  - `screenshots/` (evidence; sanitized before publishing)

---

## Folder structure (high level)

On my machine the root looks like this:

```text
D:\Hit-support-lab
  README.md
  lab-journal.md

  detections\
  incident_reports\
  screenshots\

  lab2-endpoint-hygiene\
  lab3-vulnerability-management\
  lab4-sentinel-m365\

  iso\    # local only (NOT in GitHub)
  VMs\    # local only (NOT in GitHub)
```

Only folders that are safe and reasonably small go to GitHub.  
The `iso\` and `VMs\` directories stay local and are covered by `.gitignore`.
