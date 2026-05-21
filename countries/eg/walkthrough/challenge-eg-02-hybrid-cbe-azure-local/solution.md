# Solution — Challenge EG-02 (CBE hybrid Azure Local + Arc)

> Walkthrough for `Sovereignty Summit Egypt 2026` / Challenge EG-02.

## 1. Stand up the in-country tier

Use the LocalBox helper to simulate the Azure Local environment. Keep the
registration plane near the lab in `uaenorth`
while the **regulated workload boundary** remains conceptually inside Egypt.

```powershell
. ./countries/eg/params/defaults.ps1
./demo-vms/deploy-localbox.ps1 `
  -ResourceGroupName rg-eg-localbox `
  -Location $Global:DefaultLocation `
  -AzureLocalInstanceLocation $Global:DefaultAzureLocalInstanceLoc
```

Register the cluster and validate Arc visibility:

```bash
az stack-hci cluster show -g rg-eg-localbox --name eg-cluster
az connectedmachine list -g rg-eg-arc -o table
```

## 2. Split scopes by data class

Use two scopes (subscriptions or resource groups in the lab):

- `sub-eg-regulated` → Azure Local / Arc only. Holds customer master, token
  vault, re-identification services, and the most sensitive telemetry.
- `sub-eg-derived` → `uaenorth` /
  `uaecentral` only. Holds tokenised analytics,
  non-identifying backups, and permitted management services.

## 3. Build the `CBE Hybrid Landing Zone` initiative

Recommended controls:

| Policy | Scope | Effect |
|---|---|---|
| Allowed locations = `uaenorth, uaecentral` | `sub-eg-derived` | Deny |
| Deny `cbe-tier=regulated` resources in `uaenorth` | `sub-eg-derived` | Deny |
| Storage must use CMK (`encryption.keySource = Microsoft.Keyvault`) | `sub-eg-derived` | Deny or DeployIfNotExists |
| Require tags `cbe-tier`, `pdpc-permit-id`, `tokenisation-pattern` | both | Deny |
| Audit Arc machines missing `azure-arc-eg-data-centre` | `sub-eg-regulated` | Audit |
| Defender for Cloud baseline on storage + SQL + Arc | both | DeployIfNotExists |

## 4. Keep the token vault in Egypt

Deploy Presidio or another tokeniser on the regulated Azure Local tier.
The required pattern is:

```text
PII source in Egypt
  -> tokeniser on Azure Local
  -> token vault + re-ID service on Azure Local
  -> tokenised stream only
  -> Event Hubs / Storage / analytics in uaenorth
```

The master mapping table and re-identification path must never move to
`uaenorth`.

## 5. Encryption and key custody

- Use a **Premium Key Vault** in `uaenorth` for derived-data
  services that need CMK.
- Generate or wrap the master key material from an **in-country HSM / vault**.
- Document exactly which key material never leaves Egypt and who controls
  revocation, recovery and destruction.

## 6. Telemetry split

- Regulated workloads → AMA / Arc → in-country syslog / SIEM.
- Derived workloads → Log Analytics workspace in `uaenorth`.

If telemetry contains identifiers, treat it as regulated and keep it in Egypt.

## 7. Verify

```bash
# expected: denied, because regulated workloads cannot be placed in the public-cloud tier
az storage account create -n stregulated -g rg-eg-derived \
  -l uaenorth --tags cbe-tier=regulated

# expected: token value only, not the original identifier
kubectl -n tokeniser run smoke --image=ghcr.io/sovsummit/tokeniser-smoke -- \
  --pii "01099887766" --expect-token-prefix EG-TOK-
```

Run a DR drill by restoring a tokenised backup in `uaecentral`
and confirm the dataset is still non-identifying without the in-country token
vault.

## 8. Evidence pack

Capture:

- Arc-connected machine evidence for the in-country estate;
- policy denies for any attempted `cbe-tier=regulated` deployment in
  `uaenorth`;
- proof that the token vault and re-identification service remain in-country;
- a DR restore showing operational continuity without raw identity exposure;
- the CBE / PDPL mapping used by legal and audit.
