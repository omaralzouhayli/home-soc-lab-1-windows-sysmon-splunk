# Lab 4 – Microsoft Sentinel & M365 Defender – Lab Journal

## Environment
- Endpoint: `WIN-ENDPOINT-01` (Windows 11 VM)
- Cloud: Azure (Log Analytics + Microsoft Sentinel)

---

## Phase 1 – Setup & Planning

**What I planned**
- Create a dedicated Sentinel lab linked to my Home SOC.
- Focus on identity telemetry and at least one incident investigation.

**What I did**
- Created the `lab4-sentinel-m365` folder and subfolders in my Home SOC repo.
- Wrote the initial README with goals and structure.

---

## Phase 2 – Azure & Sentinel Setup

- Subscription: **Azure subscription 1 (Free Trial)**, Region: **East US**
- Created resource group: `rg-home-soc` (East US)
- Created Log Analytics workspace: `law-home-soc-eastus` (East US) in `rg-home-soc`
- Enabled Microsoft Sentinel on: `law-home-soc-eastus`

---

## Phase 3 – Data Connectors (Entra ID logs)

- Installed **Microsoft Entra ID** solution from Sentinel Content hub.
- Enabled Microsoft Entra ID data connector:
  - Selected **Audit** + **Sign-in**
  - Started **Entra P2 trial** to access sign-in logs
- Initial KQL check (last 24h): `AuditLogs` and `SigninLogs` returned **no results** (new environment).
- Verified Entra diagnostic setting:
  - `AzureSentinel_law-home-soc-eastus` → `law-home-soc-eastus`
  - Enabled: `AuditLogs`, `SignInLogs`
- Generated activity to create logs:
  - Created test user **“Lab4 Test User”** (AuditLogs)
  - Signed in once as the test user (SigninLogs)
- KQL verification (Last 7 days):
  - `AuditLogs` returned results after generating activity
  - `SigninLogs` returned results after sign-in attempts
- Saved queries: `kql/verify-entra.kql`

---

## Phase 4 – Test Activity and Alerts (Sentinel analytics rule)

- Created Sentinel scheduled analytics rule:
  - Name: **“LAB4 - Multiple Failed Sign-ins (Entra)”**
  - Severity: **Medium**
  - Frequency: **Every 5 minutes**
  - Lookback: **10 minutes**
  - Threshold: **5+ failures**
- Test activity:
  - Performed multiple wrong-password sign-in attempts for **“Lab4 Test User”**
- Verification (KQL, last 24h at the time):
  - Sign-in failures were logged (multiple non-zero `ResultType` values)
- Result:
  - Sentinel generated an incident:
    - Title: **“LAB4 - Multiple Failed Sign-ins (Entra)”**
    - Status: **New**
    - Severity: **Medium**
- Issue + fix:
  - Incident showed **Entities = 0**
  - Updated the analytics rule to add entity mapping (**Account + IP**)
- Additional note:
  - First test user got locked due to repeated failures
  - Created a second test account (**Lab4 Test User 2**) and re-triggered the rule
  - Confirmed the new incident included entities (**Account/IP**)
- Saved rule query: `kql/rule-failed-signins-threshold.kql`

---

## Phase 5 – KQL & Incident Triage

- Switched incident time range to **Last 7 days** (lab was idle for a few days).
- Opened the newest incident and assigned it to myself.
- Set incident status to **Active / In progress**.
- Added an initial triage note (lab simulation).

**KQL validation**
- Confirmed failed sign-ins were concentrated in **OfficeHome** for the test users.
- Failures came from a **single repeated IP** (consistent with lab activity).
- One test account was **locked** due to repeated failed attempts; used a second test user to continue safely.

**Investigation and closure**
- Investigated the incident in Microsoft Defender XDR (incident graph showed **Account + IP**).
- Added a triage comment and marked the incident as **Benign/Test** (lab simulation).
- Updated incident status to **Resolved**.

**Saved queries**
- Saved Phase 5 triage KQL pack: `kql/triage-signinlogs.kql` (4 queries: failure summary, timeline, success check, outcome counts)

---

## Phase 6 – Wrap-up and Lessons Learned

- Created runbook: `runbooks/sentinel-triage-failed-signins.md`

### What worked well
- Entra ID connector + diagnostic settings delivered `AuditLogs` and `SigninLogs` to the workspace.
- A scheduled analytics rule detected repeated failed sign-ins and created a Sentinel incident.
- After adding entity mapping, the incident included **Account + IP**, which made triage faster.
- KQL triage queries confirmed the pattern quickly (user/app/IP concentration).

### What was confusing
- Sign-in logs initially showed **no results** until I generated real activity.
- The first test user got **locked out** quickly; a second test user was needed to continue.
- Incident entities stayed **0** until entity mapping was configured in the analytics rule.

### What I would improve in a real SOC environment
- Add more detections (password spray across multiple users, impossible travel, unfamiliar sign-in properties).
- Add automation after validating signal quality (notifications/enrichment/playbooks).
- Tune thresholds/lookback to reduce noise and match baseline.
- Track repeat offender IPs and consider Conditional Access / MFA enforcement for accounts with repeated failures.
