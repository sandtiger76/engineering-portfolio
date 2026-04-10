# Runbook: User Offboarding

## Purpose

This runbook defines the exact steps to offboard a departing member of staff at QCB Homelab Consultants. It is designed to be followed in the order listed — the sequence matters. Blocking sign-in must happen before anything else. Licence removal, device wipe, and data transfer must all be confirmed before the account is deleted.

**Do not delete the account until all steps are complete.** Deleting a Microsoft 365 account immediately removes access to the mailbox and OneDrive, which may be needed for data transfer. Accounts are soft-deleted and retained for 30 days — but triggering immediate deletion removes that safety window.

Estimated time: 30–60 minutes, depending on data transfer requirements.

---

## Before You Start

Gather the following information before beginning:

| Item | Detail |
|---|---|
| Departing user's full name and UPN | e.g. casey.quinn@qcbhomelab.online |
| Last working day | The date their access should be removed |
| Line manager | Will receive access to email and OneDrive if needed |
| Outstanding data | Any files or emails that need to be transferred |
| Device type | Corporate laptop / personal iPhone (BYOD) |
| Any shared accounts or service accounts | e.g. shared mailboxes they managed |

---

## Step 1 — Block Sign-In Immediately

**Portal:** Microsoft Entra Admin Center — `https://entra.microsoft.com`

This is the first and most time-sensitive step. Block sign-in as soon as the offboarding is triggered — even before the last working day if the departure is involuntary.

1. Go to **Users** → **All users** → search for the user
2. Click the user's name → **Edit properties** (pencil icon)
3. Under **Settings**, set **Block sign in** to **Yes**
4. Click **Save**

Confirm the user is blocked:
- A blocked user icon appears next to their name in the user list
- Any active sessions will be terminated at the next token refresh (up to 1 hour)

To immediately revoke all active sessions:
1. On the user's profile page → **Revoke sessions**
2. Click **Yes** to confirm

> **Why immediately?** An employee who has been notified of termination — or who has resigned and is working their notice — may have motivation to export data, delete files, or take other harmful actions. Blocking sign-in removes that ability. The user's last working day and the block date can be the same if the departure is planned, or different if it is involuntary.

---

## Step 2 — Reset the Password

Even with sign-in blocked, reset the password as an additional control.

1. On the user's profile → **Reset password**
2. Set a new strong password (it will not be shared with anyone — this is purely to prevent the old password from being used if the block is accidentally lifted)
3. Deselect **Require this user to change their password when they first sign in**
4. Click **Reset password** → note the new password (store it securely, do not share)

---

## Step 3 — Remove from Security Groups

Remove the user from all security groups to revoke their SharePoint permissions, Conditional Access policy membership, and any other group-based access.

**Portal:** Microsoft Entra Admin Center → Groups

For each group the user is a member of:
1. Go to **Groups** → **All groups** → click the group
2. **Members** → find the user → click the **…** menu → **Remove**

Groups to check and remove from:
- GRP-Executives (if applicable)
- GRP-Managers (if applicable)
- GRP-Staff (if applicable)
- GRP-FieldWorkers (if applicable)
- GRP-AllStaff
- GRP-ManagedDevices (if applicable)

> Removing from GRP-AllStaff will trigger licence removal via group-based licensing. The licence removal is not immediate — allow 5–10 minutes for it to process.

---

## Step 4 — Remove from Teams

**Portal:** Microsoft Teams Admin Center — `https://admin.teams.microsoft.com`

Remove the user from all Teams they are a member of (other than the org-wide team, from which they will be automatically removed when their account is disabled).

For each relevant team:
1. Go to **Teams** → **Manage teams** → click the team
2. **Members** tab → find the user → click **X** to remove

---

## Step 5 — Handle the Mailbox

### Option A: Transfer to Line Manager (Recommended)

Give the line manager access to the departing user's mailbox so any emails received after the last day can be monitored and responded to.

**Portal:** Exchange Admin Center — `https://admin.exchange.microsoft.com`

1. Go to **Recipients** → **Mailboxes** → click the departing user's mailbox
2. Go to **Mailbox permissions** → **Read and manage (Full Access)**
3. Click **Edit** → **+ Add permissions** → add the line manager
4. Click **Save**

The line manager can now access the mailbox via Outlook Web App: `https://outlook.office365.com` → Open another mailbox.

### Option B: Convert to Shared Mailbox

If ongoing access to the mailbox is needed by multiple people (e.g. an info@ address or a project mailbox), convert it to a shared mailbox. Shared mailboxes do not require a licence.

1. In Exchange Admin Center → **Recipients** → **Mailboxes** → click the user's mailbox
2. Select **Convert to shared mailbox** → confirm
3. Add the required members to the shared mailbox

### Option C: Set an Out-of-Office Reply and Let It Expire

If no ongoing access is needed, set an automatic reply explaining the person has left and who to contact instead.

1. In Exchange Admin Center → click the user's mailbox → **Manage automatic replies**
2. Set a message for both internal and external senders
3. The mailbox will be soft-deleted 30 days after licence removal

---

## Step 6 — Handle OneDrive Data

The departing user's OneDrive content is retained for 30 days after the account is deleted (or until the retention period set in SharePoint Admin Center expires). During this window, the content can be transferred.

**Portal:** SharePoint Admin Center — `https://admin.sharepoint.com`

1. Go to **User profiles** → search for the departing user
2. Click **Manage personal site** → this opens their OneDrive
3. Download or move files that need to be retained
4. Alternatively, grant the line manager access to the OneDrive:
   - Click **Manage site collection administrators**
   - Add the line manager's email address → **OK**
   - The line manager can now access the OneDrive directly

---

## Step 7 — Wipe Corporate Device

### Corporate Windows Laptop

If the laptop will be reused:
1. Navigate to **Intune Admin Center** → `https://intune.microsoft.com`
2. Go to **Devices** → **All devices** → find the laptop
3. Select **Wipe** → confirm
4. The device will factory reset and return to the out-of-box state, ready for the next user

If the laptop is being returned or disposed of:
1. Select **Retire** → confirm (removes Intune management without wiping)
2. Then physically reset the device before handing it over

### Personal iPhone (BYOD — Selective Wipe)

For Casey Quinn's personal iPhone, only corporate data is removed — the device itself is not wiped.

1. Navigate to **Intune Admin Center** → **Apps** → **App protection policies** → **MAM-iOS-FieldWorker**
2. Click **App protection status** → find the user's device
3. Select the device → **Wipe**

This removes all corporate data from Outlook and Teams — emails, attachments, cached files — without touching any personal data on the device.

Alternatively, removing the Microsoft 365 licence from the user's account (which happens when they are removed from GRP-AllStaff) triggers the offline grace period (12 hours), after which corporate data is automatically wiped from the MAM-protected apps.

---

## Step 8 — Remove Licence

If not already removed via group membership in Step 3, manually remove the licence.

**Portal:** Microsoft Entra Admin Center → Users → [user] → Licences

1. Click **Assignments** → select **Microsoft 365 Business Premium** → **Remove licence**
2. Confirm removal

Removing the licence immediately disables access to Exchange Online, SharePoint, Teams, and Intune.

---

## Step 9 — Delete the Account

**Do not complete this step until all data transfer and device wipe steps are confirmed complete.**

**Portal:** Microsoft Entra Admin Center → Users

1. Go to **All users** → find the user
2. Click the checkbox next to their name → **Delete**
3. Confirm deletion

The account enters a 30-day soft-delete period. During this time, it can be restored if needed. After 30 days, it is permanently deleted.

If the account needs to be permanently and immediately deleted (e.g. for data protection reasons):
1. Go to **Deleted users** (filter in the Users view)
2. Find the user → **Delete permanently** → confirm

---

## Step 10 — Verification Checklist

Before marking offboarding as complete, confirm the following:

| Check | Method | Status |
|---|---|---|
| Sign-in blocked | Entra → Users → user shows blocked icon | ☐ |
| Sessions revoked | Entra → Users → Revoke sessions completed | ☐ |
| Password reset | Completed | ☐ |
| Removed from all groups | Entra → Groups → no group membership remains | ☐ |
| Removed from Teams | Teams Admin Center → confirmed | ☐ |
| Mailbox handled | Converted / delegated / out-of-office set | ☐ |
| OneDrive data transferred | Confirmed with line manager | ☐ |
| Corporate device wiped or retired | Intune → device status | ☐ |
| BYOD selective wipe completed | Intune → App protection status | ☐ |
| Licence removed | Entra → Users → Licences | ☐ |
| Account deleted | Entra → Users → account shows in Deleted users | ☐ |

---

## Notes

**Timing:** For planned departures, complete Steps 1–7 on the last working day. Delete the account (Step 9) 7–14 days later, after confirming all data has been transferred and no business issues have arisen.

**For involuntary departures:** Complete Step 1 (block sign-in) immediately upon decision, before notifying the employee if possible. Complete Steps 2–9 within the same working day.

**Shared accounts:** Check whether the departing user was the sole administrator of any shared mailboxes, distribution groups, or Teams. Transfer ownership before their account is deleted — group and team ownership cannot be reassigned after deletion without PowerShell intervention.

**Audit trail:** The Entra ID audit log records all offboarding actions with timestamps. If a compliance question arises later, these logs are the evidence that the offboarding was completed correctly and promptly.
