# Attendee Prerequisites — Sovereignty Summit South Africa MicroHack

**Read this once before Challenge 1.** Five minutes of setup here saves you
an hour of confusion later. If anything below doesn't match what you see on
your screen, flag a coach immediately.

## What the coach gave you

Your coach handed you (in person or in a sealed envelope):

- A **lab user sign-in**: `LabUser-NN@MngEnvMCAP263177.onmicrosoft.com`
  where `NN` is your two-digit attendee number (`01` … `40`).
- A **Temporary Access Pass (TAP)** for first sign-in.
- Your **attendee number** on a sticker — write it down, you'll use it
  constantly.

> **First sign-in:** browse to <https://portal.azure.com>, enter your
> lab-user sign-in, paste the TAP when prompted. The coach will walk you
> through the MFA / authenticator-app registration. After that you're
> on your own.

## What's already provisioned for you

When you signed in to the Azure portal you will see **one subscription**
shared by every attendee: `Sovereignity Summit MicroHacks 26`. Inside it,
you have **`Contributor`** on exactly one resource group:

```
labuser-NN          (replace NN with your number — e.g. labuser-07)
```

That's your sandbox. **Do not touch any other resource group** — they
belong to the other 39 attendees, the demo VMs (`rg-arcbox`,
`rg-localbox`), or the platform baseline. The subscription is policy-locked
to South Africa regions, so even if you wanted to deploy in `westeurope`,
it would be denied.

## One-time environment-variable setup

Every walkthrough assumes four environment variables are set. Set them
**once at the start of the day** in Azure Cloud Shell (the easiest path) or
in any local terminal where you've signed in with `az login`.

### Replace `NN` with your attendee number in every block below.

### Bash / zsh / Cloud Shell (Bash)

```bash
# Open Cloud Shell -> choose Bash, then paste:

ATTENDEE_ID="labuser-NN"                # <-- change NN
RESOURCE_GROUP="$ATTENDEE_ID"
LOCATION="southafricanorth"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# Persist for the rest of your Cloud Shell session:
export ATTENDEE_ID RESOURCE_GROUP LOCATION SUBSCRIPTION_ID

# (Optional) make them survive a Cloud Shell reconnect — append to ~/.bashrc:
cat >> ~/.bashrc <<EOF
export ATTENDEE_ID="$ATTENDEE_ID"
export RESOURCE_GROUP="$RESOURCE_GROUP"
export LOCATION="$LOCATION"
export SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
EOF
```

### PowerShell / Cloud Shell (PowerShell)

```powershell
# Open Cloud Shell -> choose PowerShell, then paste:

$env:ATTENDEE_ID     = 'labuser-NN'      # <-- change NN
$env:RESOURCE_GROUP  = $env:ATTENDEE_ID
$env:LOCATION        = 'southafricanorth'
$env:SUBSCRIPTION_ID = (az account show --query id -o tsv)

# (Optional) make them survive a Cloud Shell reconnect:
Add-Content $PROFILE @"
`$env:ATTENDEE_ID     = '$($env:ATTENDEE_ID)'
`$env:RESOURCE_GROUP  = '$($env:RESOURCE_GROUP)'
`$env:LOCATION        = '$($env:LOCATION)'
`$env:SUBSCRIPTION_ID = '$($env:SUBSCRIPTION_ID)'
"@
```

## Verify your setup

Run this one command — it should print your attendee ID, your RG, the
South Africa region, and one line of resource group metadata:

```bash
echo "Attendee: $ATTENDEE_ID  |  RG: $RESOURCE_GROUP  |  Region: $LOCATION" \
  && az group show -n "$RESOURCE_GROUP" --query "{name:name, location:location, provisioningState:properties.provisioningState}" -o table
```

Expected output:

```
Attendee: labuser-07  |  RG: labuser-07  |  Region: southafricanorth
Name        Location          ProvisioningState
----------  ----------------  ------------------
labuser-07  southafricanorth  Succeeded
```

If `az group show` returns *"ResourceGroupNotFound"* you set `NN` wrong,
or you're signed in to the wrong account. Fix that before continuing —
don't proceed to Challenge 1 until the verify command works.

## Tooling you'll need (already in Cloud Shell)

If you choose to work locally instead of in Cloud Shell:

| Tool | Minimum | Install |
|---|---|---|
| Azure CLI | 2.54+ | <https://learn.microsoft.com/cli/azure/install-azure-cli> |
| PowerShell | 7.4+ | <https://learn.microsoft.com/powershell/scripting/install/installing-powershell> |
| `bicep` | latest | `az bicep install` |
| `kubectl` | 1.28+ (Challenge 5 only) | <https://kubernetes.io/docs/tasks/tools/> |

**Recommended:** just use Azure Cloud Shell. Everything is pre-installed
and signed in.

## Naming convention used throughout

Every resource you create should be scoped to **your** attendee ID so that
40 attendees do not collide:

| Resource | Pattern | Example (attendee 07) |
|---|---|---|
| Resource group | `$ATTENDEE_ID` (already exists) | `labuser-07` |
| Storage account | `${ATTENDEE_ID//-/}sa<n>` (no hyphens, 3-24 chars) | `labuser07sa1` |
| Key Vault | `kv-${ATTENDEE_ID}-<n>` | `kv-labuser-07-1` |
| Policy assignments | `${ATTENDEE_ID}-<policy>` | `labuser-07-restrict-to-sovereign-regions` |
| Custom RBAC role | `${ATTENDEE_ID}-<role>` | `labuser-07-sovereignty-auditor` |

The walkthroughs use these patterns by default — substitute your
`ATTENDEE_ID` and the rest writes itself.

## Where to find help during the lab

- **Coach:** raise your hand or shout. Coaches are wearing the Sovereignty
  Summit lanyard.
- **Challenges** (the *what*): [`challenges/`](challenges/)
- **Walkthroughs** (the *how*): [`walkthrough/`](walkthrough/)
- **Architecture / region rationale:** [`README.md`](README.md)

You're ready. Go to [Challenge 1](challenges/challenge-01.md). 🇿🇦
