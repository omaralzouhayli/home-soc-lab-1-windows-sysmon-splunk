# Lab 4 – Microsoft Sentinel + Entra ID Incident Handling

## Goal
Set up a small Microsoft security monitoring environment with **Microsoft Sentinel** and practice the core workflow a junior SOC analyst does:

- Ingest identity logs (Entra ID)
- Write and save KQL queries
- Create a Sentinel analytics rule
- Generate an incident and investigate it
- Document triage decisions in a short runbook

## What I built (results)
- Ingested **Entra ID AuditLogs** and **SigninLogs** into a Log Analytics workspace.
- Created a scheduled analytics rule: **“LAB4 - Multiple Failed Sign-ins (Entra)”**.
- Generated a Sentinel incident and fixed **entity mapping** so the incident included **Account + IP** entities.
- Investigated and closed the incident as **Benign/Test** (lab simulation).
- Saved reusable KQL queries and a runbook.

## Environment
- Azure subscription: Free Trial (East US)
- Resource group: `rg-home-soc`
- Log Analytics workspace: `law-home-soc-eastus`
- Microsoft Sentinel enabled on that workspace
- Data source: Microsoft Entra ID (AuditLogs + SigninLogs)

## Repo contents
- `lab-journal.md` – timeline of what I did (by phase).
- `kql/`
  - `verify-entra.kql` – quick ingestion verification for AuditLogs/SigninLogs
  - `rule-failed-signins-threshold.kql` – analytics rule query (failed sign-ins threshold)
  - `triage-signinlogs.kql` – triage KQL pack (4 queries)
- `runbooks/`
  - `sentinel-triage-failed-signins.md` – SOC triage runbook for this alert type
- `screenshots/` – key evidence (sanitized)

## Evidence screenshots (key ones)
- Phase 2: workspace + Sentinel enabled
- Phase 3: Entra solution installed + connector connected + diagnostic setting
- Phase 4: analytics rule created + incident with entities
- Phase 5: incident triage/closure view (sanitized)

## Mapping to entry-level SOC work / SC-200
This lab matches common SC-200 tasks:
- Connect data sources to Sentinel and validate ingestion (AuditLogs/SigninLogs)
- Use KQL to confirm and summarize activity
- Create and tune analytics rules
- Investigate incidents with entities and document triage decisions
