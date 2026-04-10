# 12 — Access Governance & Monitoring

## In Plain English

Configuring security controls is the first step. Knowing whether they are working, and catching problems before they become incidents, is the ongoing work. Access governance is about making sure the right people have the right access — and that you can prove it.

Three things matter here. Access reviews periodically check whether group memberships are still appropriate — does Alex Carter still need to be in the Executives group? Has Casey Quinn's role changed? Should any group memberships be removed? Audit logs record everything that happens in the tenant — who created a user, who changed a permission, who signed in from an unusual location. Sign-in logs specifically show every authentication attempt, whether MFA was completed, and which Conditional Access policies applied.

For a professional services firm handling client data, being able to demonstrate that access is regularly reviewed, monitored, and documented is a compliance requirement — not just a security best practice.

---

## Why This Matters

Access tends to accumulate over time. A user who needed temporary access to a project folder never has it removed. An admin account created for a one-off task is never decommissioned. Over months and years, the gap between what access exists and what access is actually needed grows — creating risk.

Monitoring catches what governance misses. Even with the right access controls in place, compromised accounts still sign in, admin actions still happen, and suspicious patterns still emerge. Reviewing sign-in logs and audit activity on a regular cadence means problems are caught quickly, not discovered months later during an incident investigation.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Security groups and users configured | Completed in workstream 01 |
| MFA and Conditional Access active | Completed in workstreams 02 and 03 |
| Microsoft Entra ID P1 licence | Included in Microsoft 365 Business Premium — required for access reviews |
| Access to Entra Admin Center | https://entra.microsoft.com |

---

## Phase 1 — Access Review

### Step 1 — Create an Access Review for the Executives Group

An access review periodically asks a designated reviewer — in this case, `m365admin` — to confirm that each member of the Executives group still requires that membership. If the reviewer approves, nothing changes. If they deny, the user is automatically removed from the group.

1. Navigate to **Entra Admin Center** → **Identity Governance** → **Access reviews** → **+ New access review**
2. Configure:

**Review type:**

| Field | Value |
|---|---|
| Select what to review | Teams + Groups |
| Review scope | Select Teams + Groups |
| Group | GRP-Executives |
| Scope | All members |

**Reviews:**

| Field | Value |
|---|---|
| Reviewers | Selected user(s): m365admin@qcbhomelab.online |
| Review recurrence | Monthly |
| Duration | 7 days |
| Start date | Today |

**Settings:**

| Field | Value |
|---|---|
| Auto apply results to resource | Enable |
| If reviewers don't respond | Remove access |
| At end of review, send notification to | m365admin@qcbhomelab.online |
| Show recommendations | Enable |
| Require reason on approval | Enable |

3. Click **Start**

> **Why monthly for a 5-person company?** In a real organisation with hundreds of group members, quarterly reviews are more practical. Monthly reviews for a small, high-privilege group like Executives demonstrate that the review process exists and is active — which is exactly the right behaviour for the highest-risk group in the environment.

> **If reviewers don't respond → Remove access** is the correct and security-conscious setting. It means inaction is treated as denial, not as approval. A reviewer who does not respond to the review within 7 days triggers automatic removal.

### Step 2 — Complete the Review

After creating the review, it will appear in the reviewer's My Access portal:

1. Navigate to `https://myaccess.microsoft.com`
2. Sign in as `m365admin@qcbhomelab.online`
3. Click **Access reviews** → select the GRP-Executives review
4. For each member, click **Approve** or **Deny**
5. If approving, enter a reason: `Confirmed executive status — no change required`
6. Click **Submit**

---

## Phase 2 — Audit Log Review

The audit log records administrative actions across the Microsoft 365 tenant. User creation, licence assignment, permission changes, policy modifications — every significant action is logged with the actor's identity, timestamp, and details.

### Step 3 — Search the Audit Log

1. Navigate to **Microsoft Defender portal** → `https://security.microsoft.com`
2. Go to **Audit** (under the Solutions section in the left menu)
3. If audit log search has not been enabled, click **Start recording user and admin activity**

Run a basic audit search:

| Field | Value |
|---|---|
| Date range | Last 7 days |
| Activities | Leave blank (all activities) |
| Users | Leave blank (all users) |

4. Click **Search**
5. Review the results — note the **Activity**, **User**, **Date**, and **Item** columns

Run a targeted search — find all changes made by `m365admin`:

| Field | Value |
|---|---|
| Date range | Last 30 days |
| Users | m365admin@qcbhomelab.online |

6. Review the actions recorded for the admin account — every configuration change made during this project should appear here

### Step 4 — Search for Specific Activity Types

Run the following targeted searches and review the results:

**Find all user creations:**

| Field | Value |
|---|---|
| Activities | Added user |
| Date range | Last 30 days |

Expected results: 5 user creation events (one for each staff user created in workstream 01)

**Find all Conditional Access changes:**

| Field | Value |
|---|---|
| Activities | Added conditional access policy, Updated conditional access policy |
| Date range | Last 30 days |

Expected results: 4 events — one for each CA policy created in workstream 02

**Export results:**
1. After running a search, click **Export** → **Download all results**
2. The results are exported as a CSV file
3. Review the CSV — this is the format used in compliance investigations and audit evidence

---

## Phase 3 — Sign-In Log Review

Sign-in logs show every authentication attempt — successful and failed — with details about the user, device, location, MFA result, and which Conditional Access policies applied.

### Step 5 — Review Sign-In Logs

1. Navigate to **Entra Admin Center** → **Users** → **Sign-in logs** (or **Monitoring** → **Sign-in logs**)
2. Review the recent sign-in events

For each sign-in, examine:

| Field | What It Shows |
|---|---|
| User | Who signed in |
| Application | What they were accessing |
| IP address | Where they signed in from |
| Location | Country/city based on IP |
| Authentication requirement | Single-factor or Multifactor |
| Status | Success or Failure |
| Conditional Access | Which policies applied and what result |
| Device | Device name and compliance state |

### Step 6 — Identify Specific Sign-In Patterns

Run the following filtered views and review results:

**Confirm MFA is firing for all users:**

1. Click **Add filters** → **Authentication requirement** → **Multifactor authentication**
2. Confirm all recent successful sign-ins show MFA as the authentication requirement
3. Any sign-in showing **Single-factor authentication** should be investigated

**Check for failed sign-ins:**

1. Click **Add filters** → **Status** → **Failure**
2. Review any failed sign-ins — note whether they are expected (e.g. user typed wrong password) or unexpected (unfamiliar IP address, unfamiliar location)
3. Multiple failed sign-ins from the same IP with different usernames may indicate a credential stuffing attack

**Review the break-glass account:**

1. Search for sign-ins from the break-glass account: `qcb-az@[tenant].onmicrosoft.com`
2. This account should have **no sign-in activity** — it is only used in emergencies
3. Any sign-in from the break-glass account should be treated as significant and investigated

### Step 7 — Review Conditional Access Insights

1. Navigate to **Entra Admin Center** → **Protection** → **Conditional Access** → **Insights and Reporting**
2. This dashboard shows how Conditional Access policies are performing:
   - How many sign-ins each policy was applied to
   - How many were granted, blocked, or required MFA
   - Which users triggered which policies
3. Confirm CA-01 is applying to all user sign-ins
4. Confirm CA-02 is blocking legacy authentication attempts (if any exist)
5. Confirm CA-04 is granting access to compliant device sign-ins

---

## Phase 4 — Establish Regular Review Cadence

### Step 8 — Document the Review Schedule

Good governance requires a regular cadence. Document the following schedule:

| Review | Frequency | Reviewer | Method |
|---|---|---|---|
| GRP-Executives access review | Monthly | m365admin | Entra ID Access Reviews |
| Sign-in log review — failed sign-ins | Weekly | m365admin | Entra Admin Center → Sign-in logs |
| Sign-in log review — MFA compliance | Monthly | m365admin | Entra Admin Center → CA Insights |
| Audit log review — admin actions | Monthly | m365admin | Microsoft Defender → Audit |
| Defender for Business — active alerts | Weekly | m365admin | security.microsoft.com → Active alerts |
| Quarantine review — Safe Attachments | Weekly | m365admin | security.microsoft.com → Quarantine |
| DMARC aggregate reports | Monthly | m365admin | Emails to m365admin@qcbhomelab.online |

> In a production environment, these reviews would be formally documented — with a record of who completed the review, what was found, and what action was taken. A simple spreadsheet or shared document updated after each review provides an audit trail that demonstrates active governance.

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Access review created | Entra → Identity Governance → Access reviews | GRP-Executives review listed, Active |
| Review completed | myaccess.microsoft.com | Approval recorded for Alex Carter |
| Audit logging enabled | Defender portal → Audit | Recording active |
| User creation events in audit | Audit search — Added user | 5 events visible |
| CA policy events in audit | Audit search — CA changes | 4 events visible |
| MFA visible in sign-in logs | Sign-in logs → filter MFA | All sign-ins show Multifactor |
| No break-glass sign-ins | Sign-in logs → qcb-az account | No sign-in activity |
| Audit export working | Export results → download CSV | CSV downloads with correct data |

---

## Summary

This workstream delivered:

- **Access review** created for GRP-Executives — monthly cadence, auto-remove on no response
- **Audit log** enabled and searched — administrative actions confirmed visible and exportable
- **Sign-in log** reviewed — MFA confirmed firing, no unexpected sign-in patterns
- **Conditional Access insights** reviewed — policies confirmed applying correctly
- **Review schedule** documented — regular cadence established for ongoing governance

Access governance is not a one-time task — it is an ongoing practice. The controls configured in this workstream provide the visibility and process needed to maintain the security posture over time, catch problems early, and demonstrate to clients and auditors that access is actively managed.

**Next:** [13 — Lessons Learned](./13-lessons-learned.md)
