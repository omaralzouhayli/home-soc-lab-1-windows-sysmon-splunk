# Security Operations and Endpoint Security Lab Portfolio

I built these four labs to practice entry-level security operations, endpoint security, and vulnerability management. The environment uses a Windows 11 VM plus Microsoft Sentinel and Entra ID.

- Collect Windows endpoint and identity telemetry
- Write detections and triage queries in SPL and KQL
- Investigate test alerts and document decisions
- Check endpoint security controls with PowerShell and Microsoft Defender
- Scan, remediate, and rescan vulnerabilities with Nessus

**Related certifications:** CompTIA Security+ (SY0-701), ISC2 Certified in Cybersecurity (CC)

---

## Labs in this repo

1. **Lab 1 - Windows monitoring with Sysmon and Splunk** *(root of the repo)*
   - Windows 11 VM `WIN-ENDPOINT-01`  
   - Sysmon (SwiftOnSecurity config) + Windows Security logs  
   - Splunk Enterprise Free ingestion  
   - SPL detections (failed logons, suspicious PowerShell, DNS from PowerShell)  
   - One PICERL incident report based on a lab alert

2. **Lab 2 - Endpoint security with PowerShell and Microsoft Defender** (`lab2-endpoint-hygiene/`)
   - PowerShell script `Get-EndpointHygiene.ps1` to check Defender status, firewall profiles, and ransomware protection  
   - EICAR test to generate a Defender alert  
   - Hygiene + alert triage runbooks

3. **Lab 3 - Vulnerability management with Nessus Essentials** (`lab3-vulnerability-management/`)
   - Credentialed Nessus scans of `WIN-ENDPOINT-01`  
   - Before/after comparison and remediation notes  
   - Focus on WinVerifyTrust CVE‑2013‑3900 mitigation and VMware Tools findings

4. **Lab 4 - Identity monitoring and incident handling with Microsoft Sentinel** (`lab4-sentinel-m365/`)
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

The repository is organized like this:

```text
it-support-lab-portfolio/
  README.md
  lab-journal.md

  detections/
  incident_reports/
  screenshots/

  lab2-endpoint-hygiene/
  lab3-vulnerability-management/
  lab4-sentinel-m365/

  iso/    # local only (not in GitHub)
  VMs/    # local only (not in GitHub)
```

Only folders that are safe and reasonably small go to GitHub.
The `iso\` and `VMs\` directories stay local and are covered by `.gitignore`.
