# Dry-Run Handoff — Sovereignty Summit (ZA)

> **Internal.** Stripped from the public mirror by `tools/publish.sh`.

This is the exact command sequence to run for tomorrow's 40-attendee dry run.
You (the coach) must run these locally — the device-code prompts in
`Connect-AzAccount` cannot be automated.

## 0. Prerequisites (5 min)

| Need | How |
|------|-----|
| Azure CLI ≥ 2.60 | `brew install azure-cli` or `winget install Microsoft.AzureCLI` |
| PowerShell 7.4+  | `brew install --cask powershell` or `winget install Microsoft.PowerShell` |
| `Az` PowerShell  | `Install-Module Az -Scope CurrentUser -Force` |
| `Microsoft.Graph` | `Install-Module Microsoft.Graph -Scope CurrentUser -Force` |
| Tenant role      | **Global Administrator** OR (User Administrator + Groups Administrator + Conditional Access Administrator) |
| Sub role         | **Owner** on the target subscription |

## 1. The one-liner (40 attendees + ArcBox + LocalBox)

```bash
git clone https://github.com/warrendt/sovsummit-microhack
cd sovsummit-microhack/build/za/bootstrap

./build-za.sh --coach \
              --create-users \
              --attendees 40 \
              --event-start-date 2026-05-22 \
              --admin-password 'ChangeMe!ForSummit2026' \
              --create-summit-group \
              --apply-ca-exclusion \
              --deploy-arcbox \
              --deploy-localbox \
              --demo-admin-password 'ChangeMe!Demo2026'
```

You will see **one** device-code prompt at the top — sign in with the coach
account (Global Admin). The script then runs unattended until LocalBox kicks
off (LocalBox takes 4–6 h to finish provisioning; the script returns once the
deployment is *started*, not *complete*).

## 2. What gets created (and where)

| Resource | Location | Approx cost / day |
|----------|----------|-------------------|
| 40 × labuser-NN resource groups | `southafricanorth` | $0 idle |
| LabUsers + AdminUsers groups, nested in "Microhack Sovereignty Summit" | tenant | — |
| 40 × Temporary Access Passes (24 h) | tenant — exported to `TemporaryAccessPasses.xlsx` | — |
| `rg-arcbox` + ArcBox-Client | `swedencentral` | ~$7 |
| `rg-localbox` + LocalBox-Client | `swedencentral` | ~$40 |
| **Total event** (3 days of demo + 40 attendees) | | **~$1,000** |

Conditional Access policy **"Security info registration for Microsoft
partners and vendors"** gets the "Microhack Sovereignty Summit" group added
to its `excludeGroups`. If the Graph token lacks
`Policy.ReadWrite.ConditionalAccess`, the script prints the manual portal
steps and continues.

## 3. Verify before sending invites

```bash
# Lab user creation
az ad group member list --group LabUsers -o table | wc -l   # should print 40+

# Resource groups
az group list --query "[?starts_with(name,'labuser-')].name" -o tsv | wc -l   # 40

# TAP export
ls -la TemporaryAccessPasses.xlsx   # exists, last-modified today

# Demo VMs (ArcBox returns fast; LocalBox keeps deploying)
az vm show -g rg-arcbox  -n ArcBox-Client  --query powerState -o tsv
az group show -n rg-localbox --query tags.CostControl -o tsv   # "Ignore"
```

## 4. Distribute credentials

`TemporaryAccessPasses.xlsx` contains four columns:
`UserPrincipalName | DisplayName | TAP | ResourceGroup`

Mail-merge into an Outlook template — see
`common/resources/preparation-helpers/MAIL_MERGE_TEMPLATE.txt`.

## 5. Teardown after the event

```bash
./teardown-za.sh --coach --attendees 40 \
                 --delete-arcbox --delete-localbox \
                 --delete-summit-group
```

This removes resource groups, deletes the lab users (NOT the admin users),
detaches the summit group from the CA exclusion, then deletes the group.

## 6. Known issues

- LocalBox deploy occasionally hits a transient Azure Local registration
  retry. Re-run `deploy-localbox.ps1` with `-Resume` to pick up where it left
  off.
- The CA exclusion PATCH returns `403` if the Graph token lacks
  `Policy.ReadWrite.ConditionalAccess`. Coach can either:
  1. Run `Connect-MgGraph -Scopes Policy.ReadWrite.ConditionalAccess` first,
     OR
  2. Apply the exclusion manually in Entra portal → Conditional Access →
     "Security info registration for Microsoft partners and vendors" →
     Assignments → Exclude → "Microhack Sovereignty Summit".

---

_Last updated: this dry-run prep cycle._
