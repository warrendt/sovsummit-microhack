# Solution — Challenge AE-02 (DIFC confidential banking)

> Walkthrough for `${country.summit_edition}` / Challenge AE-02.
> Primary region: `${country.azure.primary_region}`.

## 1. Provision the Premium Key Vault

```bash
az keyvault create
  --name kv-sovsummit-ae-$RANDOM
  --resource-group rg-ae-bank-platform
  --location ${country.azure.primary_region}
  --sku ${country.azure.cmk_hsm_sku}
  --enable-rbac-authorization true
  --enable-purge-protection true
  --retention-days 90
```

Create or import the CMK that will protect banking storage accounts, disks and
selected database services.

## 2. Create the AKS cluster and confidential node pool

Create the control plane in `${country.azure.primary_region}`, then add a
regulated node pool backed by one of `${country.azure.confidential_compute_skus}`.
In the lab, pin regulated workloads with labels / taints such as
`banking-tier=regulated`.

```bash
az aks create
  --resource-group rg-ae-bank-app
  --name aks-ae-bank
  --location ${country.azure.primary_region}
  --enable-managed-identity
  --node-count 1
  --node-vm-size Standard_D4s_v5

az aks nodepool add
  --resource-group rg-ae-bank-app
  --cluster-name aks-ae-bank
  --name regcc
  --node-vm-size Standard_DC4as_v5
  --node-count 1
  --labels banking-tier=regulated workload=confidential
  --node-taints banking-tier=regulated:NoSchedule
```

If your lab subscription exposes AKS confidential-container settings, enable the
confidential workload runtime on this pool and reserve it for onboarding,
fraud-screening and payment-support namespaces only.

## 3. Wire storage to CMK and Key Vault CSI

- Create the storage account in `${country.azure.primary_region}` with
  `encryption.keySource = Microsoft.Keyvault`.
- Grant the AKS workload identity access to read secrets / certificates from the
  Key Vault CSI provider.
- Keep application secrets, signing keys and TLS certificates in the vault; the
  containers receive short-lived mounts, not raw key files baked into images.

## 4. `DIFC Confidential Banking Baseline` initiative

Recommended controls:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | Banking workloads stay in-country. |
| Storage accounts should use customer-managed key | DeployIfNotExists / Deny | Enforce CMK-backed storage. |
| Key vaults should have purge protection enabled | Deny | Prevent destructive key loss. |
| Kubernetes clusters should restrict privileged containers | Deny | Reduce blast radius on the cluster. |
| Custom policy: regulated namespaces require confidential node pool label | Audit / Deny | Forces the regulated tier onto confidential compute. |
| Diagnostic settings to Log Analytics in `${country.azure.primary_region}` | DeployIfNotExists | Supports DIFC, CBUAE and UAE IAS evidence. |

## 5. Verify

```bash
az aks show -g rg-ae-bank-app -n aks-ae-bank --query "agentPoolProfiles[].{name:name,vmSize:vmSize,nodeLabels:nodeLabels}" -o table
az keyvault show -g rg-ae-bank-platform -n kv-sovsummit-ae-1234 --query "{sku:properties.sku.name,purge:properties.enablePurgeProtection,location:location}"
```

Negative tests:

- Try to deploy a regulated pod without the required toleration / node selector;
  it should remain unscheduled.
- Try to create a storage account without CMK; policy should deny or mark it
  non-compliant immediately.

## 6. Audit mapping

Document the evidence as:

- **DIFC DP Law:** lawful handling of customer personal data, controller / processor segregation.
- **CBUAE Consumer Protection Regulation / Standards:** customer-data protection, outsourcing evidence, complaints traceability.
- **UAE IAS:** key management, logging, privileged access and incident evidence.

That gives the bank an auditor-ready story without moving data outside the UAE.
