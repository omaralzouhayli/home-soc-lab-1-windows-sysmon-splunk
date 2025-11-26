# Endpoint Hygiene Checklist – Windows 11 + Microsoft Defender

**Purpose:**  
Quick checklist to assess basic endpoint hygiene on a Windows 11 machine using built-in Microsoft Defender and the `Get-EndpointHygiene.ps1` script.

This is meant to be fast to run during initial triage (for example, after a Defender alert or during a routine health check).

---

## Checklist

1. **Confirm endpoint identity**
   - Verify you are on the expected host:
     - Check the `Computer:` line in the `Get-EndpointHygiene.ps1` output, or run `hostname`.
   - Make sure the device name matches the ticket / case (for example, `WIN-ENDPOINT-01`).

2. **Run the hygiene script**
   - Open **PowerShell as Administrator**.
   - Run `Get-EndpointHygiene.ps1`.
   - Wait for:
     - Defender section
     - Defender preferences (subset)
     - Windows Firewall profiles
     - **Hygiene Summary (Pass/Warn/Fail)** table

3. **Defender real-time protection**
   - In the summary table, check **“Defender real-time protection”**.
   - Expected: **Status = Pass** with details `Real-time protection is enabled.`  
   - If **Fail**:
     - Confirm if another AV product is installed.
     - If not, raise / flag this as a high-priority issue.

4. **Defender signature age**
   - In the summary table, check **“Defender signature age”**.
   - Expected: **Pass** (signatures updated within the last 24 hours).
   - If **Warn/Fail**:
     - Try a manual update from **Windows Security → Virus & threat protection → Check for updates**.
     - Record the result in the ticket or notes.

5. **Defender quick scan recency**
   - In the summary table, check **“Defender quick scan recency”**.
   - Expected: **Pass** (quick scan within the last 7 days).
   - If **Warn/Fail**:
     - Start a new quick scan or schedule one.
     - Note in the ticket that a scan was triggered or requested.

6. **Windows Firewall profiles**
   - In the summary table, check **“Windows Firewall profiles”**.
   - Expected: **Pass** with details `Firewall enabled on all profiles (Domain/Private/Public).`
   - If **Fail**:
     - Identify which profile(s) are disabled.
     - Confirm whether this is expected for this host; if not, escalate or re-enable according to policy.

7. **Ransomware protection / Controlled Folder Access**
   - In the summary table, check **“Defender ransomware / Controlled Folder Access”**.
   - Expected on a hardened device: **Pass** (CFA enabled or in the correct mode).
   - If **Fail**:
     - Confirm with the owner or policy whether CFA should be enabled on this device.
     - Document the decision (for example, “CFA disabled by design for this lab endpoint”).

8. **Recent malware activity**
   - Open **Windows Security → Virus & threat protection → Protection history**.
   - Look for any recent malware events (especially **Severe**).
   - If relevant:
     - Expand the entry and note:
       - Threat name
       - Action (blocked, quarantined, removed)
       - Affected file/path
     - Take a screenshot for evidence.

9. **Patch / update state (high-level)**
   - Open **Settings → Windows Update**.
   - Check whether:
     - Updates are pending
     - A restart is required
   - If the device is far behind on updates:
     - Flag this for patching in the ticket or change request.

10. **Document evidence**
    - Copy the **Hygiene Summary (Pass/Warn/Fail)** table into the ticket or case notes.
    - Attach relevant screenshots:
      - Script output
      - Protection history
      - Windows Update status (if relevant).
