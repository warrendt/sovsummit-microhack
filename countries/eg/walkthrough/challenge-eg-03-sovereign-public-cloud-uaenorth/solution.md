# Solution — Challenge EG-03 (sovereign public cloud in UAE North)

> Walkthrough for `Sovereignty Summit Egypt 2026` / Challenge EG-03.

## 1. Start with the data split

Before you deploy anything, classify the dataset.

- If the field must remain in Egypt, keep the authoritative copy and re-ID path
  on **Azure Local**.
- If the field is permitted to leave Egypt under the PDPC file, place the cloud
  workload in `uaenorth` and document the permit,
  safeguards, and TIA reference.

A minimum tag set:

| Tag | Example |
|---|---|
| `pdpc-permit-id` | `PDPC-XB-2026-021` |
| `pdpl-data-category` | `general`, `tokenised`, `anonymised` |
| `must-stay-in-egypt` | `false` |
| `tokenisation-pattern` | `azure-local-vault-v1` |

## 2. Assign the allowed-locations initiative

Pin the public-cloud path to `uaenorth` and
`uaecentral` only.

```bash
az policy assignment create \
  --name eg-sovereign-public-cloud \
  --display-name "Egypt Sovereign Public Cloud / UAE North" \
  --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-eg \
  --policy-set-definition eg-sovereign-public-cloud \
  --params '{"allowedLocations":{"value":["uaenorth","uaecentral"]}}'
```

Pair this with deny policies for public network access on Storage, Key Vault,
SQL and app tiers.

## 3. Create the Premium Key Vault and RSA-HSM key

```bash
az keyvault create \
  --name kv-eg-uaenorth-cmk \
  --resource-group rg-eg-sovereign \
  --location uaenorth \
  --sku premium \
  --enable-rbac-authorization true \
  --enable-purge-protection true \
  --retention-days 90 \
  --public-network-access Disabled

az keyvault key create \
  --vault-name kv-eg-uaenorth-cmk \
  --name eg-storage-cmk \
  --kty RSA-HSM \
  --size 3072
```

## 4. Create the storage account with CMK, TLS 1.2 and no public access

```bash
az storage account create \
  --name steguaenorth001 \
  --resource-group rg-eg-sovereign \
  --location uaenorth \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --https-only true \
  --public-network-access Disabled

az storage account update \
  --name steguaenorth001 \
  --resource-group rg-eg-sovereign \
  --assign-identity

az storage account update \
  --name steguaenorth001 \
  --resource-group rg-eg-sovereign \
  --encryption-key-source Microsoft.Keyvault \
  --encryption-key-vault https://kv-eg-uaenorth-cmk.vault.azure.net/ \
  --encryption-key-name eg-storage-cmk
```

## 5. Use Private Link for everything

Create private endpoints for Storage and Key Vault first, then extend the same
pattern to SQL and the application tier.

```bash
az network private-endpoint create \
  --name pe-st-eg \
  --resource-group rg-eg-sovereign \
  --vnet-name vnet-eg-sovereign \
  --subnet snet-private-endpoints \
  --private-connection-resource-id $(az storage account show -n steguaenorth001 -g rg-eg-sovereign --query id -o tsv) \
  --group-id blob \
  --connection-name pe-st-eg-conn

az network private-endpoint create \
  --name pe-kv-eg \
  --resource-group rg-eg-sovereign \
  --vnet-name vnet-eg-sovereign \
  --subnet snet-private-endpoints \
  --private-connection-resource-id $(az keyvault show -n kv-eg-uaenorth-cmk -g rg-eg-sovereign --query id -o tsv) \
  --group-id vault \
  --connection-name pe-kv-eg-conn
```

## 6. Keep tokenisation in Egypt

Required pattern:

```text
Raw PDPL-restricted fields in Egypt
  -> tokeniser on Azure Local
  -> token vault + mapping table in Egypt
  -> tokenised dataset only
  -> uaenorth analytics / app tier
```

Use Azure Arc to project the Azure Local tokenisation service into the control
plane for inventory and policy evidence, but keep the mapping table and
re-identification API in-country.

## 7. Verify

```bash
az group create -n rg-eg-deny-test -l westeurope
# expected: denied by allowed-locations

az keyvault key show --vault-name kv-eg-uaenorth-cmk --name eg-storage-cmk --query key.kty
# expected: RSA-HSM

az storage account show -n steguaenorth001 -g rg-eg-sovereign \
  --query '{keySource:encryption.keySource,minTls:minimumTlsVersion,pna:publicNetworkAccess}'
# expected: Microsoft.Keyvault / TLS1_2 / Disabled
```

Run one final smoke test by sending a record with a national ID field through the
pipeline and proving that the value stored in `uaenorth` is
only a token.

## 8. Evidence pack

Capture:

- policy assignment showing only `uaenorth` /
  `uaecentral` are allowed;
- Key Vault configuration proving Premium + RSA-HSM;
- Storage configuration proving CMK + TLS 1.2 + no public access;
- private endpoint inventory;
- a before/after example showing raw restricted fields in Egypt and tokenised
  values in `uaenorth` only.
