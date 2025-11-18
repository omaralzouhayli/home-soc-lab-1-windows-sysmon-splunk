\# IR-001 – Suspicious PowerShell Execution (Home SOC Lab)



\*\*Environment:\*\* WIN-ENDPOINT-01 (Windows 11 VM – Home SOC Lab)  

\*\*Detection:\*\* Suspicious PowerShell execution (Splunk alert)  

\*\*Time (UTC):\*\* \[INCIDENT\_TIME]  

\*\*Severity (Lab):\*\* Low – simulated activity for training



---



\## 1. Preparation



\- Windows 11 endpoint `WIN-ENDPOINT-01` with:

&nbsp; - Sysmon installed and forwarding logs to Splunk index `endpoint`.

&nbsp; - Windows Security event logs also forwarded to Splunk.

\- Splunk Enterprise running on the lab host with:

&nbsp; - Index: `endpoint`

&nbsp; - Detections:

&nbsp;   - Repeated failed logons (4625)

&nbsp;   - Suspicious PowerShell execution (this incident)

&nbsp;   - DNS activity from PowerShell (unusual outbound)



---



\## 2. Identification



\- Alert: \*\*"Suspicious PowerShell execution"\*\* fired in Splunk.

\- Why it triggered:

&nbsp; - Sysmon Process Create (Event ID 1) for `powershell.exe`.

&nbsp; - Command line contained high-risk flags:

&nbsp;   - `-ExecutionPolicy Bypass`

&nbsp;   - `-WindowStyle Hidden`

\- Key event details:

&nbsp; - \*\*Time:\*\* `\[2025-11-14 23:27:03.283]`

&nbsp; - \*\*Host:\*\* `WIN-ENDPOINT-01`

&nbsp; - \*\*User:\*\* `\[WIN-ENDPOINT-01\\labadmin]`

&nbsp; - \*\*Image:\*\* `\[C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe]`

&nbsp; - \*\*Command line:\*\*  

&nbsp;   ` "C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Write-Host 'Suspicious PowerShell test from Home SOC lab'" `

\- Assessment:

&nbsp; - In this lab the command is a harmless test, but in production this pattern could indicate malware execution, downloaders, or C2 scripts.



---



\## 3. Containment



\*(What would be done in a real environment)\*



\- Isolate the endpoint from the network (EDR / NAC quarantine).

\- Kill the suspicious PowerShell process.

\- Temporarily lock or reset the user account if compromise is suspected.



\*(What was done in this lab)\*



\- Confirmed the process was manually launched by the analyst as part of a controlled test.

\- No additional suspicious child processes or outbound connections identified.



---



\## 4. Eradication



\- Real-world:

&nbsp; - Remove any malicious scripts, scheduled tasks, or autoruns.

&nbsp; - Hunt for similar PowerShell activity on other endpoints.

\- Lab:

&nbsp; - No malicious artifacts created.

&nbsp; - Detection logic documented and kept enabled for future tests.



---



\## 5. Recovery



\- Real-world:

&nbsp; - Return the endpoint to normal operation after verification.

&nbsp; - Rejoin to domain / re-enable user account if necessary.

\- Lab:

&nbsp; - VM remains in normal state.

&nbsp; - No rollback needed.



---



\## 6. Lessons Learned



\- Sysmon + Splunk can effectively detect risky PowerShell usage based on command-line arguments.

\- High-risk flags (`-ExecutionPolicy Bypass`, `-EncodedCommand`, `-WindowStyle Hidden`, `-nop`) are good candidates for alerting.

\- Even in a small home lab, using a PICERL structure helps practice real SOC workflows.

\- Next steps:

&nbsp; - Add tuning to exclude known good administrative scripts.

&nbsp; - Reuse this template for future lab incidents (failed logons, DNS anomalies, etc.).



---



\*\*Evidence:\*\*



\- Screenshot: Splunk search showing the suspicious PowerShell event (command line + user).

\- Screenshot: Splunk alert configuration for "Suspicious PowerShell execution".



