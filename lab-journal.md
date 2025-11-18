# Home SOC Lab 1 – Build Journal

This journal documents how I built my first **Home SOC** lab focused on
Windows endpoint telemetry, Splunk, and basic detections.

- Endpoint: Windows 11 VM (`WIN-ENDPOINT-01`)
- Telemetry: Windows Security logs + Sysmon (SwiftOnSecurity config)
- SIEM: Splunk Enterprise Free on the same VM
- Goals:
  - Collect Windows + Sysmon logs
  - Write detections in SPL
  - Generate safe test activity
  - Produce a PICERL incident report

---

## Day 1 – Project Folder, VM, and Windows Setup

### Step 1 – Create the lab root and subfolders

- Root folder on the host:
  - `D:\Home-SOC-Lab\`
- Subfolders created:
  - `iso\`
  - `screenshots\`
  - `detections\`
  - `incident_reports\`
  - `VMs\`  ← VMware VM files (local only, not for GitHub)
- Created this journal file: `lab-journal.md` in the root.

**Notes / Thoughts**

- I chose **VMware Workstation Pro** (already installed) instead of VirtualBox.
- Later I might ask the community if there’s any reason to rebuild this in VirtualBox.

---

### Step 2 – Download Windows 11 ISO

- Downloaded Windows 11 ISO using the official option:
  - **“Download Windows 11 Disk Image (ISO) for x64 devices”**
- Saved as:
  - `D:\Home-SOC-Lab\iso\Win11_English_x64.iso`
- Reason: I need a plain ISO that I can attach to a VM in VMware.

---

### Step 3 – Create the Windows 11 VM in VMware

- In VMware Workstation Pro:
  - Chose **“I will install the operating system later”** to avoid Easy Install.
  - OS type: Windows 11 x64.
  - VM files stored under: `D:\Home-SOC-Lab\VMs\`
- After VM creation:
  - Attached the ISO: `Win11_English_x64.iso` to the virtual CD/DVD drive.

**Issue – VMware mis-detected ISO**

- When I tried Easy Install earlier, VMware detected the ISO as **“Windows Server 2025”**.
- Fix: disable Easy Install and use the manual “install later” option, then boot from ISO.

---

### Step 4 – Windows OOBE / account setup

- Goal: use a **local account**, not a Microsoft account, for the lab.
- Tried:
  - `ipconfig /release` during OOBE to break internet connection.
  - `oobe\bypassnro` to expose the offline account option.
- Behavior:
  - Windows 11 kept looping back into the online account flow.
- Final decision:
  - Completed OOBE and then created a dedicated **local admin** account later.

**Lesson**

- Modern Windows 11 Pro strongly pushes Microsoft / AAD accounts, which is realistic for enterprise environments.

---

### Step 5 – Rename endpoint and create local admin

- Renamed the VM to:
  - `WIN-ENDPOINT-01`
- Created a local user:
  - Username: `labadmin`
  - Type: **Administrator**
- Verified identity inside the VM:
  - `whoami` → `WIN-ENDPOINT-01\labadmin`
  - `hostname` → `WIN-ENDPOINT-01`
- This account and hostname represent my **simulated employee laptop**.

---

### Step 6 – VMware Tools and network check

- Installed **VMware Tools** inside the VM.
  - Result: better screen resolution + smoother mouse and clipboard integration.
- Confirmed network connectivity:
  - Adapter mode: **NAT** (from VMware settings).
  - Tested internet access with Edge as `labadmin`.

---

### Step 7 – Tools folder on the endpoint

- Created folder for security tools inside the VM:
  - `C:\Tools\Sysmon\`  ← for Sysmon binaries + config
- This keeps lab tools organized and easy to reference later.

---

## Day 2 – Sysmon and Splunk

### Step 8 – Sysmon installation

On `WIN-ENDPOINT-01`:

- Downloaded **Sysinternals Sysmon** and extracted it to:
  - `C:\Tools\Sysmon\`
- Downloaded community Sysmon configuration (SwiftOnSecurity) as:
  - `sysmonconfig.xml` in the same folder.
- Installed Sysmon:

  ```cmd
  Sysmon64.exe -accepteula -i sysmonconfig.xml
  ```

- Verified service:

  ```cmd
  sc query sysmon64
  ```

  → Status showed **RUNNING**.

- Verified log source:
  - Event Viewer → Applications and Services Logs  
    → Microsoft → Windows → Sysmon → **Operational**

---

### Step 9 – Install Splunk Enterprise (mini-SIEM)

- Downloaded **Splunk Enterprise for Windows (x64)** inside the VM.
- Saved installer under:
  - `C:\Tools\`
- Installed Splunk with defaults:
  - Path: `C:\Program Files\Splunk\`
  - Service account: Local System
  - Service startup: automatic
- Created admin account:
  - Username: `splunkadmin`
  - Password: stored separately in private notes.

---

### Step 10 – First Splunk login

- Opened browser inside the VM:
  - URL: `http://localhost:8000`
- Logged in as:
  - `splunkadmin`
- Confirmed Splunk Web loads and shows the main dashboard.

---

### Step 11 – Create `endpoint` index and ingest logs

**11.1 – Create index**

- In Splunk Web:
  - Settings → Indexes → New Index
  - Name: `endpoint`
  - Purpose: store:
    - Windows Security / System / Application logs
    - Sysmon Operational logs

**11.2 – Configure `inputs.conf`**

- Tried CLI:

  ```cmd
  splunk add win-event-log Security -index endpoint
  ```

- Splunk returned: `'win-event-log' is not a valid argument for the 'add' command`  
  (newer versions changed the syntax).

- Switched to manual configuration:
  - Edited: `C:\Program Files\Splunk\etc\system\local\inputs.conf`
  - Added WinEventLog stanzas for:
    - Application
    - System
    - Security
  - Added Sysmon Operational log with `renderXml = true`.

- Restarted Splunk:

  ```cmd
  "C:\Program Files\Splunk\bin\splunk.exe" restart
  ```

**11.3 – Verify ingestion**

- In Splunk Search:

  ```spl
  index=endpoint | head 20
  ```

- And:

  ```spl
  index=endpoint | stats count by sourcetype
  ```

- Verified:
  - Security log sourcetypes
  - Sysmon sourcetype:
    - `XmlWinEventLog:Microsoft-Windows-Sysmon/Operational`

---

## Day 3 – Detections and Test Activity

### Step 12 – Detection #1 – Repeated failed logons

**12.1 – Generate failed logons**

- On `WIN-ENDPOINT-01`:
  - Locked the screen / logoff.
  - Entered the wrong password for `labadmin` **4 times**.

**12.2 – Inspect events in Splunk**

- Search:

  ```spl
  index=endpoint sourcetype="WinEventLog:Security" EventCode=4625
  ```

- Confirmed:
  - Events for user `labadmin`.
  - Username field in events is `Account_Name`.

**12.3 – Build SPL detection**

- SPL stored in `detections\failed_logons_spl.txt`:

  ```spl
  index=endpoint sourcetype="WinEventLog:Security" EventCode=4625
  | bin _time span=5m
  | stats count as failed_count values(IpAddress) as ip by _time, host, Account_Name
  | where failed_count >= 4
  | sort - _time
  ```

**12.4 – Save as Scheduled Alert**

- Alert title: **Possible brute force - multiple failed logons**
- Type: Scheduled
- Runs periodically (at least once per hour in this lab)
- Trigger: Number of results > 0
- Action: **Log Event**
  - Event text: `"Brute-force detection alert triggered."`
  - Destination index: `main` (defaults)

---

### Step 13 – Detection #2 – Suspicious PowerShell execution

**13.1 – Generate suspicious-looking PowerShell**

- In an elevated PowerShell window as `labadmin`:

  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Write-Host 'Suspicious PowerShell test from Home SOC lab'"
  ```

- This is harmless, but it uses flags that are often abused by attackers.

**13.2 – Inspect Sysmon Process Create events**

- Base search:

  ```spl
  index=endpoint sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" "powershell.exe"
  ```

- Extracted fields from the XML using `rex`:
  - `Image` – full executable path
  - `CommandLine` – full command line
  - `User` – account running the process

**13.3 – SPL detection logic**

Stored in `detections\suspicious_powershell_spl.txt`:

```spl
index=endpoint sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" "powershell.exe"
| rex field=_raw "Data Name='Image'>(?<Image>[^<]+)"
| rex field=_raw "Data Name='CommandLine'>(?<CommandLine>[^<]+)"
| rex field=_raw "Data Name='User'>(?<User>[^<]+)"
| eval cmd=lower(CommandLine)
| where cmd LIKE "%-executionpolicy%" OR cmd LIKE "%-encodedcommand%" OR cmd LIKE "%-windowstyle hidden%" OR cmd LIKE "%-nop%"
| stats values(CommandLine) as commands count by _time, host, User, Image
| sort - _time
```

**13.4 – Save as Scheduled Alert**

- Alert title: **Suspicious PowerShell execution**
- Type: Scheduled
- Runs at least once per hour
- Trigger: Number of results > 0
- Action: **Log Event** (simple entry in `main` index)

---

### Step 14 – Detection #3 – DNS queries from PowerShell (unusual outbound)

**14.1 – Generate DNS activity**

- In PowerShell as `labadmin`:

  ```powershell
  Test-NetConnection example.com -Port 4444
  ```

- This produces DNS lookups for `example.com` plus a failed TCP connection to port 4444.

**14.2 – Inspect Sysmon DNS events**

- Search for the domain:

  ```spl
  index=endpoint "example.com"
  ```

- Confirmed Sysmon DNS events (Event ID 22) with:
  - `QueryName`
  - `QueryResults`
  - `Image` pointing to PowerShell.

**14.3 – SPL detection logic**

Stored in `detections\unusual_dns_powershell_spl.txt`:

```spl
index=endpoint sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" "QueryName"
| rex field=_raw "Data Name='Image'>(?<Image>[^<]+)"
| rex field=_raw "Data Name='User'>(?<User>[^<]+)"
| rex field=_raw "Data Name='QueryName'>(?<QueryName>[^<]+)"
| rex field=_raw "Data Name='QueryResults'>(?<QueryResults>[^<]+)"
| where Image LIKE "%powershell.exe%"
| stats values(QueryName) as domains values(QueryResults) as ip_addresses count by _time host User Image
| sort - _time
```

**14.4 – Save as Scheduled Alert**

- Alert title: **Unusual DNS query from PowerShell**
- Type: Scheduled
- Runs hourly (lab setting)
- Trigger: Number of results > 0
- Action: **Log Event** to index `main` with a short message.

---

## Day 4 – Incident Report (PICERL)

### Step 15 – IR-001 – Suspicious PowerShell execution

- Selected one of the **Suspicious PowerShell execution** events as a sample incident.
- Created a PICERL-style report in:
  - `incident_reports\IR-001_Suspicious_PowerShell_PICERL.md`
- The report includes:
  - Environment description (`WIN-ENDPOINT-01`, Sysmon, Splunk, detections in place)
  - Identification details:
    - Sysmon Process Create event (ID 1) for `powershell.exe`
    - Full command line with:
      - `-ExecutionPolicy Bypass`
      - `-WindowStyle Hidden`
    - User `WIN-ENDPOINT-01\labadmin`
  - Containment / Eradication / Recovery:
    - Real-world actions vs. lab actions
  - Lessons Learned and next steps.

---

## Next Ideas

- Add more detections (service creation, persistence, suspicious child processes).
- Repeat the PICERL process for:
  - Brute-force failed logons
  - Unusual DNS queries from PowerShell
- Later labs:
  - Integrate Microsoft Defender / Sentinel and practice KQL.
  - Add another VM to simulate a small network.
