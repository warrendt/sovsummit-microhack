# Solution — Challenge NG-03 (Sovereign public cloud Johannesburg)

> Walkthrough for `${country.summit_edition}` / Challenge NG-03.
> Primary region: `${country.azure.primary_region}`.

## 1. Create the Nigeria sovereign public-cloud scope

Use a dedicated management group or subscription slice for the public-cloud
variant so policy evidence is easy to export.

```bash
az account management-group create --name mg-sovsummit-ng-public --display-name "Sovereignty Summit NG Public"
az account management-group subscription add --name mg-sovsummit-ng-public --subscription "$SUBSCRIPTION_ID"
```

## 2. Assign allowed-locations pinning

Use a policy initiative that allows only `${country.azure.primary_region}` and
`${country.azure.paired_region}` for this landing zone.

```bash
az policy assignment create \
  --name ng-sovereign-public-cloud-regions \
  --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-ng-public \
  --policy <allowed-locations-initiative-id> \
  --params '{"listOfAllowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

Add companion policies for:

- allowed locations for resource groups,
- deny public network access on storage / Key Vault / SQL,
- require private endpoints,
- require `ndpa-transfer-basis`, `ndpa-transfer-instrument`, and
  `ng-data-classification` tags.

## 3. Create the Premium Key Vault and HSM-backed CMK

Use stable shell variables so later commands point at the same resources:

```bash
KV_NAME="kv-ng-sovpub-$RANDOM"
ST_NAME="stngsovpub$RANDOM"
```

Provision the vault in `${country.azure.primary_region}`:

```bash
az keyvault create \
  --name "$KV_NAME" \
  --resource-group rg-ng-platform \
  --location ${country.azure.primary_region} \
  --sku ${country.azure.cmk_hsm_sku} \
  --enable-purge-protection true \
  --enable-rbac-authorization true
```

Create or import an `RSA-HSM` key:

```bash
az keyvault key create \
  --vault-name "$KV_NAME" \
  --name cmk-ng-jhb \
  --kty RSA-HSM \
  --size 3072
```

If the bank requires **BYOK**, perform the key-generation ceremony on a Nigerian
on-prem HSM, wrap the key material there, and import it into the Premium Key
Vault. Keep the ceremony record, approver list and custody chain in the evidence
pack.

## 4. Provision the storage account with CMK and network lock-down

```bash
az storage account create \
  --name "$ST_NAME" \
  --resource-group rg-ng-data \
  --location ${country.azure.primary_region} \
  --sku Standard_ZRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --public-network-access Disabled

az storage account update \
  --name "$ST_NAME" \
  --resource-group rg-ng-data \
  --assign-identity

az storage account update \
  --name "$ST_NAME" \
  --resource-group rg-ng-data \
  --encryption-key-source Microsoft.Keyvault \
  --encryption-key-vault "https://$KV_NAME.vault.azure.net/" \
  --encryption-key-name cmk-ng-jhb
```

Validate:

```bash
az storage account show -n "$ST_NAME" -g rg-ng-data \
  --query '{keySource:encryption.keySource,tls:minimumTlsVersion,public:publicNetworkAccess}'
```

## 5. Force Private Link everywhere

Create private endpoints for the storage account, Key Vault and database tier.
At minimum, verify these subresources:

- Storage blob / dfs
- Key Vault vault
- SQL server / managed instance endpoint
- Any eventing or analytics service you keep in scope

```bash
az network private-endpoint create ...
az network private-endpoint dns-zone-group create ...
```

Your deny policies should block new public endpoints after this point.

## 6. Build the Nigeria tokenisation boundary

Keep the token vault and detokenisation service in Nigeria. For the lab, you can
host it on an Arc-enabled VM or AKS workload behind Azure Local.

```text
Digital channel app in ${country.azure.primary_region}
  -> Private API call over VPN / ExpressRoute / private WAN
  -> Token service on Azure Local + Arc in Nigeria
  -> Returns surrogate token only
  -> App stores tokenised record in SQL / Storage in ${country.azure.primary_region}
```

Minimum design rules:

- raw BVN / NIN / PAN never persist in `${country.azure.primary_region}`;
- token maps and detokenisation approvals stay in Nigeria;
- if the Nigeria token vault is offline, the app may degrade, but it must not
  fall back to storing raw identifiers in public Azure.

## 7. Keep the data-classification table with the platform

Use the table below as a mandatory architecture artefact, not just workshop
notes.

| Data class | Location | Control |
|---|---|---|
| `restricted-raw` | Nigeria only | Token vault / Azure Local / Arc |
| `tokenised-operational` | `${country.azure.primary_region}` | CMK + Private Link + tags |
| `derived-analytics` | `${country.azure.primary_region}` / `${country.azure.paired_region}` | CMK + policy + DR |
| `break-glass-detokenisation` | Nigeria only | HSM-backed custody + approval workflow |

## 8. Document the cross-border legal posture honestly

Your evidence pack should include a one-page summary with these sections:

1. **Destination:** `${country.azure.primary_region}` / `${country.azure.paired_region}`.
2. **Why this region:** closest practical Azure hyperscale region for Nigeria,
   paired-region DR, better latency than Europe/US options.
3. **Transfer basis:** document the actual **NDPA s.43** basis and whether legal
   also relies on an adequacy assessment or an NDPC-recognised SCC-equivalent /
   transfer instrument.
4. **Safeguards:** CMK, Private Link, tokenisation, least privilege, logging,
   incident workflow.
5. **Registration impact:** whether the workload remains within DCPMI scope and
   how it is declared in the NDPC filing.
6. **Breach workflow:** show how the NDPC is notified within
   `${country.regulatory.breach_notification_hours}` hours and how customers are
   notified when the risk threshold is met.

## 9. Verify

```bash
az group create -n rg-ng-public-deny -l westeurope   # expect RequestDisallowedByPolicy
az keyvault key show --vault-name "$KV_NAME" --name cmk-ng-jhb --query '{type:key.kty}'
az storage account show -n "$ST_NAME" -g rg-ng-data \
  --query '{keySource:encryption.keySource,tls:minimumTlsVersion,public:publicNetworkAccess}'
```

Run one smoke test that submits a raw identifier to the token service and confirm
only the surrogate token reaches `${country.azure.primary_region}`.

## 10. Evidence mapping

Map the final design like this:

- region pinning + transfer register → **NDPA ss.41-43**
- breach workflow → **NDPA s.40**
- DPO / registration pack → **NDPA ss.32, 44, 65**
- transfer instrument detail / filing discipline → **GAID 2025**
- key custody / outsourcing governance → **CBN cybersecurity + shared-services expectations**
