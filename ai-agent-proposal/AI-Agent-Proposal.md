# AI-Powered Database Offboarding Agent
### Idea Proposal — Kurtosys Engineering
**Submitted by:** Lunga Ndzimande
**Role:** Database Engineer
**Date:** 2026-07-01

---

## The Problem

Kurtosys is receiving an increasing number of user offboarding requests. Every ticket
requires a database engineer to manually:

1. Investigate which clients and userIds are associated with the user
2. Determine if the client is dedicated or shared (Scenario A or B)
3. Write safety check queries across 180+ tables
4. Generate row counts and backup scripts
5. Wait for peer review
6. Run delete scripts in the correct order
7. Verify all counts are zero
8. Manually update and close the Jira ticket

This process is **time consuming, repetitive and high risk**. One wrong query on a
shared client can wipe data belonging to hundreds of real users across the UDM__
database — a database that holds ALL Kurtosys client data for global asset managers.

As offboarding requests grow, this manual approach does not scale.

---

## The Idea

Build an **AI-Powered Offboarding Agent** that automates the entire user offboarding
workflow — integrated with Jira, the Kurtosys KAPP API, and a friendly UI.

> *"The agent investigates, plans and prepares. The engineer approves. One click executes."*

---

## Why This Makes Sense for Kurtosys

Kurtosys already automates complex workflows for its clients — generating thousands
of data-driven documents, powering investor portals, and managing compliance-sensitive
financial data at scale on AWS.

This proposal applies that **same automation principle inward** — to how Kurtosys
engineers manage and maintain the platform itself.

> *"Kurtosys automates workflows for our clients. This agent automates workflows for
> our own engineers."*

Additionally:
- The platform is already **cloud-native on AWS** — the infrastructure is ready
- The platform already has a **KAPP API** — the agent calls the API, not the database directly
- Offboarding requests are **increasing** — this scales infinitely at no extra engineering effort
- The RAG knowledge base **grows smarter** with every ticket completed

---

## System Architecture — 3 Layers

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 1 — KNOWLEDGE (RAG)                              │
│                                                         │
│  • Kurtosys KAPP schema and table relationships         │
│  • Offboarding rules (Scenario A vs B)                  │
│  • Parent/child table deletion order                    │
│  • Historical offboarding tickets as examples           │
│  • Company scripts and processes                        │
│  • Grows smarter with every completed ticket            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  LAYER 2 — INTELLIGENCE (AI Agent)                      │
│                                                         │
│  • Reads Jira ticket via Jira API                       │
│  • Understands the offboarding scenario                 │
│  • Calls KAPP API (read only) to investigate            │
│  • Classifies Scenario A or B automatically             │
│  • Identifies shared clients and flags DO NOT TOUCH     │
│  • Generates full deletion plan with reasoning          │
│  • Posts plan back to Jira for review                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  LAYER 3 — EXECUTION (API + UI)                         │
│                                                         │
│  • Friendly UI to review and approve plans              │
│  • Engineer clicks Approve in UI or Jira                │
│  • Agent calls KAPP API to execute deletion             │
│  • Agent verifies all counts are zero                   │
│  • Agent auto-closes Jira ticket with audit trail       │
└─────────────────────────────────────────────────────────┘
```

---

## Full Workflow

```
1. Jira ticket created (offboarding request)
         ↓
2. Agent reads ticket via Jira REST API
         ↓
3. Agent queries RAG knowledge base
   → Understands table relationships
   → Knows Scenario A vs B rules
   → Knows parent/child deletion order
         ↓
4. Agent calls KAPP API (READ ONLY)
   → Finds all userIds and clientIds
   → Checks shared vs dedicated clients
   → Gets row counts across all relevant tables
   → Flags any users that must NOT be touched
         ↓
5. Agent generates full plan
   → Scenario classification with reasoning
   → Row counts before deletion
   → Backup plan
   → Delete scripts in correct order
   → Verification plan
         ↓
6. Plan posted to Jira as a comment
   Plan displayed in UI for review
         ↓
7. DB team reviews → clicks APPROVE in UI or Jira
   (Nothing executes without human approval)
         ↓
8. Agent executes via KAPP API
   → Triggers backup
   → Runs deletes (children first, parent last)
   → Runs verification
   → Confirms all counts = 0
         ↓
9. Agent auto-updates and closes Jira ticket
   with full audit trail
```

---

## Key Capabilities

| Capability | Description |
|------------|-------------|
| Jira Integration | Reads tickets and posts results via Jira REST API — no manual copy/paste |
| RAG Knowledge Base | Agent understands Kurtosys-specific rules, schema and processes |
| KAPP API Integration | Agent calls KAPP API — never touches the database directly |
| Read-Only Investigation | Agent investigates and reports without making any changes |
| Scenario Classification | Automatically determines Scenario A (dedicated) or B (shared) |
| Plan Generation | Human-readable deletion plan generated before any action |
| Human-in-the-Loop | No deletion without explicit DB team approval |
| One-Click Execution | After approval, agent handles backup, delete and verify |
| Audit Trail | Every action logged — who approved, what was deleted, when |
| Self-Learning | RAG knowledge base grows with every completed ticket |
| Friendly UI | Simple interface for engineers to review plans and approve |
| Scalable | 1 request or 100 requests — same engineering effort |

---

## Technology Stack

| Component | Technology | Reason |
|-----------|------------|--------|
| AI Agent | Amazon Bedrock Agents | Already on AWS, enterprise-grade |
| RAG Knowledge Base | Amazon Bedrock Knowledge Bases | Native AWS, connects to S3 |
| Knowledge Storage | Amazon S3 | Store schema docs, scripts, historical tickets |
| API Integration | KAPP REST API | Agent calls KAPP API — not DB directly |
| Ticketing | Jira REST API | Read tickets, post plans, close tickets |
| UI | React + AWS Amplify | Lightweight, fast to build for POC |
| Backend | AWS Lambda | Serverless, no infrastructure to manage |
| Approval Workflow | UI + Jira | Engineer approves in UI or directly in Jira |
| Audit Logging | Amazon CloudWatch + S3 | Full audit trail of every action |
| Security | AWS IAM + Secrets Manager | No credentials exposed to agent |

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent calls wrong API endpoint | High | Read-only mode enforced during investigation. Write APIs only called after approval |
| Agent misidentifies shared client | High | Scenario classification always shown to engineer before execution. Human must approve |
| KAPP API does not expose all needed endpoints | Medium | POC scoped to available endpoints first. Missing endpoints flagged as API enhancement requests |
| Agent hallucinates wrong userIds or clientIds | High | All findings shown to engineer in plan. Human reviews before approving |
| Jira API token expiry or permission issues | Low | Secrets Manager rotation. Fallback to manual ticket input in UI |
| RAG knowledge base returns outdated schema | Medium | Knowledge base updated whenever schema changes. Version controlled in S3 |
| Unauthorised approval | High | Approval restricted to DB team role in UI. Jira approval requires specific permission level |
| Audit trail gaps | Medium | Every API call logged to CloudWatch. S3 backup of all plans and approvals |

---

## Proof of Concept (POC) — Scope

The POC focuses on proving the core loop works end to end with minimal scope.

### POC Goal
> Prove that the agent can read a Jira ticket, investigate via KAPP API,
> generate a correct offboarding plan, and present it for approval — without
> touching the database directly.

### POC Scope

**In scope:**
- Jira ticket reading via API
- KAPP API read-only calls (find users, find clients, get counts)
- Scenario A vs B classification
- Plan generation and display in UI
- Approval button in UI
- Basic audit log

**Out of scope for POC:**
- Actual deletion execution (read-only POC only)
- Full RAG knowledge base (use hardcoded rules for POC)
- Multi-environment support (REL only for POC)
- Auto-closing Jira ticket (manual for POC)

### POC Architecture

```
┌──────────┐     ┌──────────────┐     ┌─────────────────┐
│  Jira    │────▶│  AWS Lambda  │────▶│  KAPP API       │
│  Ticket  │     │  (Agent)     │◀────│  (Read Only)    │
└──────────┘     └──────┬───────┘     └─────────────────┘
                        │
                        ▼
                ┌───────────────┐
                │  Plan Output  │
                │  (UI / Jira   │
                │   comment)    │
                └───────┬───────┘
                        │
                        ▼
                ┌───────────────┐
                │  Engineer     │
                │  Reviews +    │
                │  Approves     │
                └───────────────┘
```

### POC Milestones

| Milestone | Description | Est. Time |
|-----------|-------------|-----------|
| 1 | KAPP API exploration — identify available read endpoints | 1 week |
| 2 | Lambda function — reads Jira ticket, calls KAPP API, returns user/client data | 1 week |
| 3 | Scenario classification logic — Scenario A vs B | 3 days |
| 4 | Plan generation — structured output with reasoning | 1 week |
| 5 | Basic UI — submit ticket, view plan, approve button | 1 week |
| 6 | Demo to team | 1 day |
| **Total** | | **~5 weeks** |

---

## Future Enhancements (Post-POC)

- Full Amazon Bedrock Agent with RAG knowledge base
- Execution via KAPP API (not just read-only)
- Multi-environment support (DEV, UAT, PROD)
- Client onboarding automation (reverse of offboarding)
- Environment provisioning automation
- Data migration automation
- Slack notifications for approvals
- Dashboard showing all offboarding requests and statuses

---

## Summary

This proposal turns a manual, repetitive and high-risk database process into a
**safe, intelligent and auditable workflow** — built on Kurtosys's existing AWS
infrastructure and KAPP API.

The agent does the heavy lifting. The engineer stays in control.

As offboarding requests grow, the system scales automatically. As more tickets
are completed, the RAG knowledge base grows smarter. As the KAPP API expands,
the agent's capabilities expand with it.

This is not just an internal tool — it is a demonstration that Kurtosys can
apply the same automation and intelligence it delivers to its clients, to its
own engineering operations.

---

*Submitted for consideration — Kurtosys Engineering Innovation*
*Lunga Ndzimande — Database Engineer — 2026-07-01*
