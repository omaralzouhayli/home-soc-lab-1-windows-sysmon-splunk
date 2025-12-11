# Home SOC Lab – Windows Endpoint & Blue-Team Practice

This repo is my personal **Home SOC** playground. I’m using a single Windows 11 VM as an “employee laptop” and building small labs around it to practice:

- Endpoint logging and detections  
- Defender hygiene and basic hardening  
- Vulnerability scanning and remediation

I’m doing this while studying **ISC2 CC** and **CompTIA Security+ (SY0‑701)**, so the labs stay close to what a junior SOC / endpoint / vuln‑management role would actually do.

---

## Labs in this repo

Right now there are **three labs**:

1. **Lab 1 – Windows endpoint + Sysmon + Splunk**  *(root of the repo)*  
   - Windows 11 VM `WIN-ENDPOINT-01` acting as a user workstation  
   - Sysmon (SwiftOnSecurity config) writing into Windows Event Log  
   - Splunk Enterprise Free on the same VM  
   - A few SPL detections (failed logons, suspicious PowerShell, DNS from PowerShell)  
   - One PICERL incident report based on a “suspicious PowerShell” alert  

2. **Lab 2 – Endpoint hygiene + Microsoft Defender**  (`lab2-endpoint-hygiene/`)  
   - Reuses `WIN-ENDPOINT-01` from Lab 1  
   - PowerShell script to check Defender status, signatures, scan history, firewall, and ransomware protection  
   - Short hygiene checklist and notes on how I would triage Defender alerts

3. **Lab 3 – Vulnerability management with Nessus Essentials**  (`lab3-vulnerability-management/`)  
   - Nessus Essentials runs on the Windows host  
   - Targets the same VM `WIN-ENDPOINT-01` over VMware NAT  
   - Baseline unauthenticated scan → credentialed scan → remediation → rescan  
   - Focus on one real High Windows finding (WinVerifyTrust / `EnableCertPaddingCheck`) and a set of VMware Tools Medium findings, plus Windows Update hygiene

Each lab has its **own README and journal** inside its folder. The root README you’re reading now is just an overview so people don’t get lost.

---

## Lab 1 details (root of the repo)

Lab 1 lives directly at the top level of this repo.

Key pieces:

- `lab-journal.md` – step‑by‑step notes for building the lab:  
  VM creation, Sysmon install, Splunk setup, index + inputs, detections, and the PICERL report.
- `detections/` – plain‑text SPL searches for:
  - repeated failed logons  
  - suspicious PowerShell flags  
  - DNS queries coming from PowerShell
- `incident_reports/` – incident write‑ups (PICERL format).  
- `screenshots/` – evidence used in the README and journal (Sysmon events, Splunk searches, alert config, etc.).

If you want to **rebuild Lab 1**, start with:

1. Read `lab-journal.md` from top to bottom.  
2. Use the SPL files in `detections/` to create alerts in your own Splunk instance.  
3. Open the PICERL report in `incident_reports/` to see how I turned one alert into a small incident story.

---

## Folder structure (high level)

On my machine the root looks like this:

```text
D:\Home-SOC-Lab
  README.md                # this overview
  lab-journal.md           # Lab 1 build journal
  detections\             # Lab 1 SPL queries
  incident_reports\       # Lab 1 incident reports
  screenshots\            # Lab 1 screenshots

  lab2-endpoint-hygiene\  # Lab 2 – Defender hygiene
  lab3-vulnerability-management\  # Lab 3 – Nessus vuln management

  iso\                    # Windows ISO (local only, NOT in GitHub)
  VMs\                    # VMware VM files (local only, NOT in GitHub)
```

Only the folders that are safe and reasonably small go to GitHub.  
The `iso\` and `VMs\` directories stay local and are covered by `.gitignore`.

---

## How to use this repo

- If you’re curious about **detections and log analysis**, focus on **Lab 1**.  
- If you want quick **endpoint health checks**, look at **Lab 2**.  
- If you care about **patching and vuln management**, open **Lab 3**.

You don’t have to follow my order. Each lab can stand on its own, but all three share the same Windows VM, which makes it feel like one small, growing environment instead of three random demos.
