# Solution — Challenge KSA-02 (SAMA confidential AKS for payments)

> Walkthrough for `Sovereignty Summit Saudi Arabia 2026` / Challenge KSA-02.
> Primary region: `saudiarabiaeast`.

## 1. Prepare the Saudi payments platform foundation

```bash
PLATFORM_RG=rg-ksa-pay-platform
OBS_RG=rg-ksa-pay-observability
LAW_NAME=law-ksa-payments
KV_NAME=kv-ksa-pay-$RANDOM
KEY_NAME=cmk-ksa-payments
DES_NAME=des-ksa-payments
VNET_NAME=vnet-ksa-payments

az group create -n $PLATFORM_RG -l saudiarabiaeast
az group create -n $OBS_RG -l saudiarabiaeast

az monitor log-analytics workspace create   -g $OBS_RG   -n $LAW_NAME   -l saudiarabiaeast

az keyvault create   --name $KV_NAME   --resource-group $PLATFORM_RG   --location saudiarabiaeast   --sku Premium   --enable-rbac-authorization true   --enable-purge-protection true

az keyvault key create   --vault-name $KV_NAME   --name $KEY_NAME   --kty RSA-HSM   --size 3072
```

## 2. Create the segmented network

```bash
az network vnet create   -g $PLATFORM_RG   -n $VNET_NAME   -l saudiarabiaeast   --address-prefixes 10.42.0.0/16   --subnet-name snet-aks-system   --subnet-prefixes 10.42.0.0/24

az network vnet subnet create -g $PLATFORM_RG --vnet-name $VNET_NAME -n snet-aks-payments --address-prefixes 10.42.1.0/24
az network vnet subnet create -g $PLATFORM_RG --vnet-name $VNET_NAME -n snet-private-endpoints --address-prefixes 10.42.2.0/24
az network vnet subnet create -g $PLATFORM_RG --vnet-name $VNET_NAME -n snet-egress --address-prefixes 10.42.3.0/24
```

Attach NSGs so:

- `snet-aks-payments` allows inbound only from approved private ingress tiers,
- east-west access is limited to explicitly listed dependencies,
- internet ingress is denied,
- egress is forced through the approved firewall / egress path.

## 3. Create the private AKS cluster and confidential node pool

```bash
AKS_NAME=aks-ksa-payments
SYSTEM_SUBNET_ID=$(az network vnet subnet show -g $PLATFORM_RG --vnet-name $VNET_NAME -n snet-aks-system --query id -o tsv)
PAY_SUBNET_ID=$(az network vnet subnet show -g $PLATFORM_RG --vnet-name $VNET_NAME -n snet-aks-payments --query id -o tsv)

az aks create   --resource-group $PLATFORM_RG   --name $AKS_NAME   --location saudiarabiaeast   --enable-private-cluster   --enable-azure-policy   --enable-oidc-issuer   --enable-workload-identity   --network-plugin azure   --vnet-subnet-id $SYSTEM_SUBNET_ID   --node-count 1   --node-vm-size Standard_D4s_v5   --generate-ssh-keys

az aks nodepool add   --resource-group $PLATFORM_RG   --cluster-name $AKS_NAME   --name paycvm   --mode User   --node-count 1   --node-vm-size Standard_DC4as_v5   --vnet-subnet-id $PAY_SUBNET_ID   --labels workload=payments confidential=true sama-tier=regulated   --node-taints confidentiality=high:NoSchedule
```

## 4. Create a Disk Encryption Set for payment PVCs

```bash
KEY_ID=$(az keyvault key show --vault-name $KV_NAME --name $KEY_NAME --query key.kid -o tsv)

az disk-encryption-set create   --name $DES_NAME   --resource-group $PLATFORM_RG   --location saudiarabiaeast   --source-vault $KV_NAME   --key-url $KEY_ID
```

Create an Azure Disk CSI StorageClass that references the DES:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: payments-cmk-zrs
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_ZRS
  diskEncryptionSetID: /subscriptions/<sub>/resourceGroups/rg-ksa-pay-platform/providers/Microsoft.Compute/diskEncryptionSets/des-ksa-payments
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

Use this StorageClass for any stateful payment workload that creates PVCs.

## 5. Constrain workload placement and secrets

```bash
az aks get-credentials -g $PLATFORM_RG -n $AKS_NAME --admin
kubectl create namespace payments
kubectl label namespace payments sama-tier=regulated
```

Use the following pod placement fragment:

```yaml
nodeSelector:
  confidential: "true"
tolerations:
  - key: confidentiality
    operator: Equal
    value: high
    effect: NoSchedule
```

Install the Key Vault CSI driver with workload identity and create a
`SecretProviderClass` so applications read keys, certificates, and connection
strings at runtime instead of storing them in Kubernetes secrets checked into Git.

## 6. Route diagnostics only to Saudi Arabia East

```bash
LAW_ID=$(az monitor log-analytics workspace show -g $OBS_RG -n $LAW_NAME --query id -o tsv)
AKS_ID=$(az aks show -g $PLATFORM_RG -n $AKS_NAME --query id -o tsv)

az monitor diagnostic-settings create   --name aks-in-country-logs   --resource $AKS_ID   --workspace $LAW_ID   --logs '[{"category":"kube-audit","enabled":true},{"category":"cluster-autoscaler","enabled":true}]'   --metrics '[{"category":"AllMetrics","enabled":true}]'
```

Add private endpoints for Key Vault, Storage, ACR, and monitoring so the payment
platform can stay on private paths end to end.

## 7. Enforce network policy for the regulated namespace

Start with a deny-by-default posture, then allow only the paths you need:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payments-default-deny
  namespace: payments
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

Layer allow rules on top for:

- private ingress gateway to payment API,
- payment API to token vault / broker / fraud service,
- payment services to private endpoints and approved DNS,
- observability sidecars to the approved in-country sink.

## 8. Package the SAMA exit and repatriation bundle

Minimum deliverables:

1. Git-exported manifests / Helm values / Flux definitions.
2. Image escrow in a bank-controlled registry.
3. Velero backups for the `payments` namespace and any supporting state.
4. Key inventory, rotation record, and custody sign-off.
5. Contract references for audit rights, data return, and deletion on termination.

Example backup command:

```bash
velero backup create payments-smoke --include-namespaces payments
```

## 9. Verify the control story

```bash
az aks nodepool list -g $PLATFORM_RG --cluster-name $AKS_NAME -o table
az monitor diagnostic-settings list --resource $AKS_ID
kubectl get pods -n payments -o wide
```

Reviewers should be able to see all of the following immediately:

- payment pods land on the confidential node pool only,
- PVCs use the DES-backed StorageClass,
- diagnostics flow to `saudiarabiaeast` only,
- exit artifacts exist and have been rehearsal-tested.
