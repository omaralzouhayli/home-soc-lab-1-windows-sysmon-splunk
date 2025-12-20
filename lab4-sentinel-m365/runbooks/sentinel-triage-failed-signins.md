# Runbook – Sentinel Triage: Multiple Failed Sign-ins (Entra)

## Purpose
Triage a Sentinel incident that detects multiple failed Entra sign-ins for a single user in a short time window (possible password spraying / brute-force vs. benign user error).

## Data sources
- Microsoft Entra ID Sign-in logs (SigninLogs table in Log Analytics / Sentinel)

## When to use
- Incidents like: “Multiple Failed Sign-ins (Entra)”
- Alerts where failures occur repeatedly for one account in a short time window

## Quick triage checklist

### 1) Confirm incident context
In Microsoft Sentinel:
- Open the incident
- Assign to yourself
- Set status to **Active / In progress**
- Note: rule name, time range, severity, and number of alerts/events

### 2) Validate log evidence (SigninLogs)
Run the Phase 5 triage queries:
- `kql/triage-signinlogs.kql`

Focus on:
- **Is it concentrated to one user?**
- **Is it one IP or many IPs?**
- **Is it one application (AppDisplayName) or many apps?**
- **Any successes (ResultType == 0) from the same IP/user?**

### 3) Interpret the pattern
Common patterns:
- **One user + one IP + one app + many failures**  
  Likely benign (user mistake) OR repeated automation from one source.
- **One user + many IPs**  
  Higher suspicion (spray or distributed brute-force).
- **Many users + one/few IPs**  
  Spray attempt indicator.
- **Failures followed by success**  
  Higher risk (possible credential compromise), investigate deeper.

### 4) Decide and document
Add a short analyst note in the incident:
- What you observed (user/IP/app/time window)
- Why you believe it is benign/suspicious
- What action you took (reset password, block IP, require MFA, etc.)
- For labs: mark clearly as **Test / Simulation**

### 5) Close the incident
- Classification: **Benign / Test** (for lab)
- Status: **Resolved**
- Optional: add tags (e.g., `lab`, `test`, `failed-signin`)

## Lab notes / limitations
- This lab used synthetic failed sign-ins to generate alerts.
- Entities should appear only if entity mapping is configured in the analytics rule.
