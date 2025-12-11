# Home SOC Lab 1 – Build Journal

This journal explains how I built **Home SOC Lab 1**, which focuses on Windows endpoint telemetry, Splunk, and a few simple detections.

- Endpoint: Windows 11 VM (`WIN-ENDPOINT-01`)
- Telemetry: Windows Security logs + Sysmon (SwiftOnSecurity config)
- SIEM: Splunk Enterprise Free on the same VM
- Main goals:
  - Collect Windows + Sysmon logs
  - Write detections in SPL
  - Generate safe test activity
  - Produce a PICERL-style incident report

---

## 1. Environment and Folder Layout

**Host and hypervisor**

- Host OS: Windows
- Hypervisor: VMware Workstation Pro (NAT networking)

**Root lab folder on the host**

```text
D:\Home-SOC-Lab\
  README.md
  lab-journal.md      # this file
  detections\
  incident_reports\
  screenshots\
  iso\               # Windows ISO (local only, not for GitHub)
  VMs\               # VMware VM files (local only, not for GitHub)
```

- `iso\` holds the Windows 11 ISO used for the VM.
- `VMs\` holds the VMware Workstation files.
- `detections\`, `incident_reports\`, and `screenshots\` are shared across all labs in this project.

---

## 2. Windows 11 VM – Build and Basic Setup

**2.1 Create the VM**

- Downloaded the Windows 11 ISO from Microsoft:
  - Option: **“Download Windows 11 Disk Image (ISO) for x64 devices”**
  - Saved as: `D:\Home-SOC-Lab\iso\Win11_English_x64.iso`
- In VMware Workstation Pro:
  - Created a new VM and chose **“I will install the operating system later”** (to avoid Easy Install).
  - OS type: Windows 11 x64.
  - VM location: `D:\Home-SOC-Lab\VMs\`
  - Attached `Win11_English_x64.iso` to the virtual CD/DVD drive.

> Note: When I tried Easy Install earlier, VMware mis-detected the ISO as **“Windows Server 2025”**. Using the manual “install later” flow fixed that.

---

**2.2 OOBE and accounts**

- Goal: use a **local admin account** to simulate an on-prem / workgroup endpoint.
- Tried the usual tricks:
  - `ipconfig /release` during OOBE.
  - `oobe\bypassnro` to expose the offline account option.
- Windows 11 kept looping back into the online-account flow.
- Final approach:
  - Completed OOBE as prompted.
  - After setup, created a dedicated local admin account for the lab.

---

**2.3 Hostname and local admin**

Inside the VM:

- Renamed the computer to:

  ```text
  WIN-ENDPOINT-01
  ```

- Created a local admin user:

  ```text
  Username: labadmin
  Type: Administrator
  ```

- Verified:

  ```powershell
  whoami
  hostname
  ```

  Output showed `WIN-ENDPOINT-01\labadmin` and `WIN-ENDPOINT-01`.

This VM represents a single **employee-style laptop** for the Home SOC labs.

---

**2.4 VMware Tools and network**

- Installed **VMware Tools** in the guest to get:
  - Better screen resolution
  - Mouse / clipboard integration
- Network:
  - Adapter mode: **NAT** (from VMware settings).
  - Confirmed internet access from inside the VM using Edge as `labadmin`.

---

**2.5 Tools folder inside the VM**

To keep security tools organized:

- Created:

  ```text
  C:\Tools\Sysmon\
  ```

This is where Sysmon binaries and config live.

---

## 3. Sysmon – Install and Verify

On `WIN-ENDPOINT-01`:

1. Downloaded **Sysinternals Sysmon** and extracted it to:

   ```text
   C:\Tools\Sysmon\
   ```

2. Downloaded the community Sysmon config by **SwiftOnSecurity** as:

   ```text
   C:\Tools\Sysmon\sysmonconfig.xml
   ```

3. Installed Sysmon with the custom config:

   ```cmd
   Sysmon64.exe -accepteula -i sysmonconfig.xml
   ```

4. Verified the service:

   ```cmd
   sc query sysmon64
   ```

   - Status showed **RUNNING**.

5. Confirmed the log source in Event Viewer:

   - Applications and Services Logs  
     → Microsoft → Windows → Sysmon → **Operational**

A screenshot of the Sysmon Operational log lives in `screenshots\`.

---

## 4. Splunk – Install, Index, and Ingestion

**4.1 Install Splunk Enterprise**

Inside `WIN-ENDPOINT-01`:

- Downloaded **Splunk Enterprise for Windows (x64)**.
- Saved the installer under:

  ```text
  C:\Tools\
  ```

- Installed with defaults:
  - Path: `C:\Program Files\Splunk\`
  - Service account: Local System
  - Startup: Automatic
- Created a Splunk admin user:

  ```text
  Username: splunkadmin
  Password: (stored in private notes)
  ```

---

**4.2 First login**

- Opened a browser in the VM:
  - `http://localhost:8000`
- Logged in as `splunkadmin`.
- Confirmed the main Splunk Web interface loaded.

---

**4.3 Create the `endpoint` index**

In Splunk Web:

- Settings → Indexes → **New Index**
  - Name: `endpoint`
  - Purpose: store:
    - Windows Security / System / Application logs
    - Sysmon Operational logs

---

**4.4 Configure `inputs.conf` for Windows + Sysmon**

Originally tried the older CLI syntax:

```cmd
splunk add win-event-log Security -index endpoint
```

but the command failed (`'win-event-log' is not a valid argument`), so I switched to editing `inputs.conf` directly.

- Edited:

  ```text
  C:\Program Files\Splunk\etc\system\local\inputs.conf
  ```

- Added WinEventLog stanzas for:
  - Application
  - System
  - Security
- Added the Sysmon Operational log with `renderXml = true` so the raw XML is available for SPL field extraction.

Then restarted Splunk:

```cmd
"C:\Program Files\Splunk\bin\splunk.exe" restart
```

---

**4.5 Verify ingestion**

In Splunk Search:

```spl
index=endpoint | head 20
```

and:

```spl
index=endpoint | stats count by sourcetype
```

- Confirmed:
  - Windows Security logs (WinEventLog sourcetypes).
  - Sysmon events under:

    ```text
    XmlWinEventLog:Microsoft-Windows-Sysmon/Operational
    ```

Screenshots show the index view and sourcetypes.

---

## 5. Detections and Test Activity

All SPL queries are saved under `detections\` so they can be reused.

### 5.1 Detection 1 – Repeated Failed Logons (Possible Brute Force)

**Test activity**

- On `WIN-ENDPOINT-01`:
  - Locked the screen / logged out.
  - Entered the wrong password for `labadmin` **4 times** to generate failed logon events.

**Investigate in Splunk**

```spl
index=endpoint sourcetype="WinEventLog:Security" EventCode=4625
```

- Verified that:
  - Events showed user `labadmin`.
  - Username field was `Account_Name`.

**Detection logic**

Saved as: `detections\failed_logons_spl.txt`

```spl
index=endpoint sourcetype="WinEventLog:Security" EventCode=4625
| bin _time span=5m
| stats count as failed_count values(IpAddress) as ip by _time, host, Account_Name
| where failed_count >= 4
| sort - _time
```

**Alert**

- Name: **Possible brute force - multiple failed logons**
- Type: Scheduled search
- Trigger: number of results > 0
- Action: **Log Event** to index `main` with a simple message.

---

### 5.2 Detection 2 – Suspicious PowerShell Execution

**Test activity**

In an elevated PowerShell window as `labadmin`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Write-Host 'Suspicious PowerShell test from Home SOC lab'"
```

- The command is harmless but uses flags (`-ExecutionPolicy Bypass`, `-WindowStyle Hidden`) that are often abused.

**Investigate in Splunk**

Base search:

```spl
index=endpoint sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" "powershell.exe"
```

From the Sysmon XML, I extracted:

- `Image` – full path to the exe
- `CommandLine` – full command line
- `User` – account that ran the process

**Detection logic**

Saved as: `detections\suspicious_powershell_spl.txt`

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

**Alert**

- Name: **Suspicious PowerShell execution**
- Type: Scheduled
- Trigger: results > 0
- Action: **Log Event** to index `main`.

---

### 5.3 Detection 3 – DNS Queries from PowerShell (Unusual Outbound)

**Test activity**

In PowerShell as `labadmin`:

```powershell
Test-NetConnection example.com -Port 4444
```

- This triggers DNS lookups for `example.com` plus a failed TCP connection.

**Investigate in Splunk**

Search for the domain:

```spl
index=endpoint "example.com"
```

- Verified Sysmon DNS events (Event ID 22) with:
  - `QueryName`
  - `QueryResults`
  - `Image` pointing to PowerShell.

**Detection logic**

Saved as: `detections\unusual_dns_powershell_spl.txt`

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

**Alert**

- Name: **Unusual DNS query from PowerShell**
- Type: Scheduled
- Trigger: results > 0
- Action: **Log Event** to `main`.

---

## 6. PICERL Incident Report

To practice basic incident handling, I took one **Suspicious PowerShell execution** event and turned it into a small PICERL report:

- File: `incident_reports\IR-001_Suspicious_PowerShell_PICERL.md`

The report includes:

- Environment summary:
  - `WIN-ENDPOINT-01`, Sysmon, Splunk, detections
- **Preparation:** what logging and tools were in place
- **Identification:** Sysmon Process Create event for `powershell.exe` with:
  - `-ExecutionPolicy Bypass`
  - `-WindowStyle Hidden`
  - User `WIN-ENDPOINT-01\labadmin`
- **Containment / Eradication / Recovery:**
  - What I would do in a real SOC vs. in this lab
- **Lessons Learned:**
  - Why this detection matters
  - Ideas for follow-up (e.g., tightening PowerShell restrictions, adding more detections)

---

## 7. Where Everything Lives in the Repo

For anyone reading this from GitHub:

- **Detections (SPL):** `detections\`
  - `failed_logons_spl.txt`
  - `suspicious_powershell_spl.txt`
  - `unusual_dns_powershell_spl.txt`
- **Incident report:** `incident_reports\IR-001_Suspicious_PowerShell_PICERL.md`
- **Screenshots for Lab 1:** `screenshots\`  
  (folder also holds images for later labs; names make it clear which ones belong to Lab 1)
- **Lab 2 & Lab 3:** live under:
  - `lab2-endpoint-hygiene\`
  - `lab3-vulnerability-management\`

This lab gives me a small Windows endpoint, telemetry, and three detections I can reuse in later labs when I start looking at Defender, Nessus, and more advanced scenarios.
