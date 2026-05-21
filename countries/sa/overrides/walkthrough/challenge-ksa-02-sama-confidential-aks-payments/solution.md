# Solution — Challenge KSA-02 (SAMA confidential AKS for payments)

> Walkthrough for `${country.summit_edition}` / Challenge KSA-02.
> Primary region: `${country.azure.primary_region}`.

## 1. Prepare the platform resource groups

```powershell
. ./countries/${country.iso2}/params/defaults.ps1
```

```bash
az group create -n rg-ksa-pay-platform -l ${country.azure.primary_region}
az group create -n rg-ksa-pay-observability -l ${country.azure.primary_region}

az monitor log-analytics workspace create   -g rg-ksa-pay-observability   -n law-ksa-payments   -l ${country.azure.primary_region}

az keyvault create   --name kv-ksa-pay-$RANDOM   --resource-group rg-ksa-pay-platform   --location ${country.azure.primary_region}   --sku ${country.azure.cmk_hsm_sku}   --enable-rbac-authorization true   --enable-purge-protection true
```

If the bank uses an on-prem HSM, import the wrapping key via BYOK and document
key custodians, dual control, and recovery escrow.

## 2. Create the private AKS cluster and confidential node pool

```bash
AKS_RG=rg-ksa-pay-platform
AKS_NAME=aks-ksa-payments

az aks create   --resource-group $AKS_RG   --name $AKS_NAME   --location ${country.azure.primary_region}   --enable-private-cluster   --enable-azure-policy   --enable-oidc-issuer   --enable-workload-identity   --network-plugin azure   --node-count 1   --node-vm-size Standard_D4s_v5   --generate-ssh-keys

az aks nodepool add   --resource-group $AKS_RG   --cluster-name $AKS_NAME   --name paycvm   --node-count 1   --node-vm-size Standard_DC4as_v5   --labels workload=payments confidential=true   --node-taints confidentiality=high:NoSchedule
```

## 3. Enforce payments scheduling and secret retrieval

Create the namespace and constrain it to the confidential pool:

```bash
kubectl create namespace payments
kubectl label namespace payments sama-tier=regulated
```

For the workload spec, use:

```yaml
nodeSelector:
  confidential: "true"
tolerations:
  - key: confidentiality
    operator: Equal
    value: high
    effect: NoSchedule
```

Install the Key Vault CSI driver / SecretProviderClass with workload identity so
pods read secrets at runtime instead of storing them as plaintext Kubernetes
secrets.

## 4. Keep logging and diagnostics in-country

```bash
LAW_ID=$(az monitor log-analytics workspace show -g rg-ksa-pay-observability -n law-ksa-payments --query id -o tsv)

az monitor diagnostic-settings create   --name aks-in-country-logs   --resource $(az aks show -g $AKS_RG -n $AKS_NAME --query id -o tsv)   --workspace $LAW_ID   --logs '[{"category":"kube-audit","enabled":true},{"category":"cluster-autoscaler","enabled":true}]'   --metrics '[{"category":"AllMetrics","enabled":true}]'
```

Also enable Container Insights and Defender for Containers, but point all data
collection to `law-ksa-payments` in `${country.azure.primary_region}`.

## 5. Add policy and exit controls

Minimum policy set:

| Control | Implementation |
|---|---|
| No public AKS API | Private cluster only |
| No public `LoadBalancer` services | Azure Policy for AKS / Gatekeeper deny |
| Approved registries only | Gatekeeper allowlist |
| CMK required | Disk Encryption Set + storage CMK policy |
| Exit artifacts retained | Nightly Velero backup + Git export + image escrow |

Exit package contents:

1. Flux / Helm / raw manifests in Git.
2. Container images copied to a bank-controlled registry.
3. Velero backups of `payments` namespace.
4. Key inventory and rotation procedure.
5. DNS, certificate, and cutover checklist.

## 6. Verify and rehearse repatriation

```bash
az aks nodepool list -g $AKS_RG --cluster-name $AKS_NAME -o table
az monitor diagnostic-settings list --resource $(az aks show -g $AKS_RG -n $AKS_NAME --query id -o tsv)

velero backup create payments-smoke --include-namespaces payments
```

Restore the backup into a bank-controlled target cluster (another AKS cluster in
`${country.azure.primary_region}` or an Azure Local / Arc-connected cluster)
and verify:

- Pods only schedule on confidential nodes.
- Secrets still resolve from the approved key store.
- Logs stay in-country.
- Recovery completes within the RTO/RPO documented for SAMA review.
