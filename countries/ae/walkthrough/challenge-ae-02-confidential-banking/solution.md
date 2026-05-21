# Solution — Challenge AE-02 (CBUAE confidential banking)

> Walkthrough for `Sovereignty Summit United Arab Emirates 2026` / Challenge AE-02.
> Primary region: `uaenorth`.

## 1. Build the security foundation first

Create the security resource group, Premium Key Vault and HSM-backed key:

```bash
KV_NAME="kv-ae-bank-$RANDOM"

az group create -n rg-ae-bank-security -l uaenorth

az keyvault create \
  --name "$KV_NAME" \
  --resource-group rg-ae-bank-security \
  --location uaenorth \
  --sku Premium \
  --enable-rbac-authorization true \
  --enable-purge-protection true \
  --retention-days 90

az keyvault key create \
  --vault-name "$KV_NAME" \
  --name bank-cmk \
  --kty RSA-HSM \
  --size 3072
```

Then define a rotation policy and capture the key owner, approver and emergency
revocation process in the evidence pack.

## 2. Create CMK-backed storage and disk encryption

Use the same vault for:

- a **Storage account** that will hold KYC documents, onboarding evidence and
  complaints records;
- a **Disk Encryption Set** for regulated managed disks used by stateful banking
  workloads.

That gives you a clear regulator story: the bank controls key custody, not the
application team and not the cloud platform by default.

## 3. Create the private AKS cluster and confidential node pool

```bash
az group create -n rg-ae-bank-platform -l uaenorth

az aks create \
  --resource-group rg-ae-bank-platform \
  --name aks-ae-bank \
  --location uaenorth \
  --enable-managed-identity \
  --enable-azure-rbac \
  --enable-private-cluster \
  --node-count 1 \
  --node-vm-size Standard_D4s_v5

az aks nodepool add \
  --resource-group rg-ae-bank-platform \
  --cluster-name aks-ae-bank \
  --name regcc \
  --mode User \
  --node-vm-size Standard_DC4as_v5 \
  --node-count 1 \
  --labels banking-tier=regulated confidential=true \
  --node-taints banking-tier=regulated:NoSchedule
```

Pin onboarding, sanctions-screening and payment-support namespaces to the
confidential pool with node selectors, tolerations and workload admission
controls.

## 4. Integrate workload identity and Key Vault CSI

- Enable AKS workload identity / OIDC.
- Use Key Vault CSI so application secrets, certificates and signing material
  are mounted just-in-time.
- Keep long-lived keys out of images, Kubernetes secrets and repo history.

## 5. Build the `CBUAE Confidential Banking Baseline`

Recommended controls:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | Keeps primary banking workloads in the UAE |
| Allowed locations for resource groups | Deny | Stops RG drift |
| AKS clusters should be private | Deny | Reduces attack surface |
| Storage accounts / disks must use CMK | Deny or DeployIfNotExists | Enforces bank-controlled encryption |
| Key Vault must use RBAC + purge protection | Deny | Protects key custody and recovery |
| Public network access disabled for regulated services | Deny | Prevents accidental internet exposure |
| Diagnostic settings to in-country workspace | DeployIfNotExists | Preserves audit trail |
| Custom policy: `banking-tier=regulated` workloads require confidential pool | Audit / Deny | Keeps decrypted data on confidential compute |

## 6. Verify

```bash
az aks show -g rg-ae-bank-platform -n aks-ae-bank \
  --query "agentPoolProfiles[].{name:name,vmSize:vmSize,labels:nodeLabels,taints:nodeTaints}" -o table

az keyvault show -g rg-ae-bank-security -n "$KV_NAME" \
  --query "{sku:properties.sku.name,purge:properties.enablePurgeProtection,location:location}" -o yaml
```

Negative tests:

- Deploy a regulated pod without the required node selector / toleration. It
  should remain unscheduled or be rejected by policy.
- Try to create a regulated storage account without CMK. Policy should deny it.
- Try to enable a public endpoint on a regulated data service. Policy should
  deny or flag it.

## 7. Map the evidence to CBUAE themes

| Control theme | Evidence |
|---|---|
| Governance | Architecture approval, role assignments, named service owner |
| Materiality | Risk assessment showing onboarding / payments are material cloud workloads |
| Data protection | CMK, private cluster, confidential node pool, Key Vault CSI |
| Auditability | Policy state, AKS / Key Vault / Storage diagnostics, deployment logs |
| Business continuity | `uaecentral` recovery design and tested procedures |
| Exit planning | Backup / restore, key revocation, migration runbook |
| Consumer protection | Secure storage and retrieval of complaints / customer records |

That produces a CBUAE-ready platform story: confidential compute for live
processing, CMK for key custody, and auditable controls for cloud outsourcing.
