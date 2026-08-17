# IR-001: Suspicious PowerShell Execution

**Environment:** `WIN-ENDPOINT-01` (Windows 11 VM)

**Detection:** Suspicious PowerShell execution in Splunk

**Event time:** 2025-11-14 23:27:03.283 (lab event timestamp)

**Severity:** Low - controlled test activity

## 1. Preparation

The lab endpoint had:

- Sysmon installed with the SwiftOnSecurity configuration
- Windows Security and Sysmon logs collected in the Splunk `endpoint` index
- Three SPL detections:
  - Repeated failed logons (Event ID 4625)
  - Suspicious PowerShell execution
  - DNS activity from PowerShell

## 2. Identification

The **Suspicious PowerShell execution** alert fired after Sysmon recorded a Process Create event (Event ID 1) for `powershell.exe`.

The command line contained two high-risk flags:

- `-ExecutionPolicy Bypass`
- `-WindowStyle Hidden`

Key event details:

- **Host:** `WIN-ENDPOINT-01`
- **User:** `WIN-ENDPOINT-01\labadmin`
- **Image:** `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
- **Command:**

  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Write-Host 'Suspicious PowerShell test from Home SOC lab'"
  ```

The command was a harmless test. In a production environment, the same flags could be associated with malware execution, downloaders, or command-and-control scripts.

## 3. Containment

### Lab action

- Confirmed that the command was launched intentionally for the test.
- Reviewed the event for unexpected child processes or network activity.
- Kept the VM online because no malicious behavior was found.

### Production response

If the activity were not authorized, the next actions would be:

- Isolate the endpoint through EDR or network controls.
- Stop the suspicious process.
- Restrict the user account if compromise were suspected.

## 4. Eradication

No malicious files or persistence mechanisms were created in the lab.

For a real incident, eradication would include:

- Removing malicious scripts, scheduled tasks, or autoruns.
- Searching other endpoints for the same command-line pattern.
- Tuning the detection to exclude known administrative scripts.

## 5. Recovery

- Verified that the VM remained in its normal state.
- No rollback or account restoration was required.
- Kept the detection enabled for future testing.

## 6. Lessons Learned

- Sysmon Process Create events provide useful command-line evidence for PowerShell investigations.
- Flags such as `-ExecutionPolicy Bypass`, `-EncodedCommand`, `-WindowStyle Hidden`, and `-NoProfile` are useful detection signals but require context.
- A PICERL structure keeps investigation decisions and hypothetical response actions separate from what actually occurred in the lab.

## Evidence

- [Suspicious PowerShell SPL detection](../detections/suspicious_powershell_spl.txt)
- [Splunk event evidence - view 1](../screenshots/06_detection2_suspicious_powershell_search_1.png)
- [Splunk event evidence - view 2](../screenshots/06_detection2_suspicious_powershell_search_2.png)
