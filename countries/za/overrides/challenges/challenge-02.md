# Challenge 2 — Customer-managed keys for ${country.name} cardholder data

[Previous Challenge](challenge-01.md) — **[Home](../Readme.md)** — Next: [Challenge 3](challenge-03.md)

> **Primary region:** `${country.azure.primary_region}`
> **Key Vault SKU in scope:** `${country.azure.cmk_hsm_sku}` (HSM-backed)

## The situation

You have moved across to **${country.scenarios.financial_tenant}**. The bank
issues virtual cards through a new Azure-hosted platform. The CISO has
committed to the South African Reserve Bank (SARB) and the Payment Card
Industry Security Standards Council that:

- The bank — **not Microsoft** — controls the encryption keys for any
  storage that holds cardholder data, customer PII, or transaction journals.
- Keys are stored in an HSM the bank can prove is geographically located in
  ${country.name} and is destroyable on demand.
- Loss of access to the key results in loss of access to the data — i.e.
  a verifiable **cryptographic erasure** capability.

Your team owns the Azure platform. The product team is shipping in two
weeks. They need a Storage account, a SQL database, and a Service Bus
namespace ready to receive cardholder PII, all encrypted with bank-owned
keys.

## Your mission

Stand up a key management foundation that the SARB inspector would accept,
then onboard the three data services to it. The goal is not just "CMK on" —
it is **provable customer control**, with key rotation, recovery and
revocation procedures that work.

> **Build everything inside your assigned `labuser-NN` resource group.**
> You have Owner + Key Vault Administrator + Storage Account Contributor at
> that scope, which is enough for this challenge. The `rg-sovza-foundation`
> RG you may hear coaches reference is the *coach reference implementation*
> — you don't have access to it on purpose. Build your own CMK pipeline
> from scratch so the rotation/revocation evidence is yours.

## Learning objectives

You should leave this challenge able to:

- Articulate the difference between Microsoft-managed keys, customer-managed
  keys (CMK) in Key Vault standard, CMK in Key Vault Premium (HSM-backed)
  and Azure Managed HSM — and which one each regulator typically expects.
- Provision a `${country.azure.cmk_hsm_sku}` Key Vault with **purge
  protection** and **soft delete** enabled, and explain why both are
  non-negotiable for production CMK.
- Configure CMK on Azure Storage so the data plane fails closed when the
  key is unavailable.
- Rotate a key without taking the application offline.
- Demonstrate a controlled "cryptographic erase" in a non-prod environment.

## Success criteria

- [ ] A `${country.azure.cmk_hsm_sku}` Key Vault exists in
      `${country.azure.primary_region}` with `purgeProtection = true`,
      `softDeleteRetentionInDays >= 90` and the RBAC permission model
      enabled (not access policies).
- [ ] At least one key in the vault is HSM-protected
      (`kty = RSA-HSM` or `oct-HSM` as appropriate) and has an
      explicit **rotation policy** (rotate every N days, notify before
      expiry).
- [ ] A Storage account in `${country.azure.primary_region}` has
      `encryption.keySource = Microsoft.Keyvault`, references the HSM key
      version-less, and uses a **user-assigned managed identity** for
      key access (so identity lifecycle is decoupled from the storage
      account).
- [ ] A SQL Database or SQL Managed Instance uses TDE with CMK from the
      same vault.
- [ ] You can demonstrate **key rotation**: rotate the key, then write a
      new blob and verify the storage account is healthy and uses the new
      key version (`az storage account show -n <sa> --expand
      keyExpirationStatus`).
- [ ] You can demonstrate **revocation**: in a sandbox, disable the key
      and confirm reads fail with a `KeyVaultEncryptionKeyNotFound`-class
      error — then restore access and confirm recovery.
- [ ] Your evidence pack records the procedure for emergency key
      destruction and links it to **POPIA s.19** and **SARB Directive
      3/2018**.

## Guiding questions

- Why does Microsoft strongly recommend assigning Key Vault access via
  **RBAC** rather than access policies for new vaults?
- A junior engineer suggests storing the key in the *same* subscription as
  the storage account "for simplicity". What's the operational risk, and
  how would you split responsibilities instead?
- Soft delete and purge protection together mean a deleted key can be
  recovered for 90+ days. How does this *help* a cryptographic-erase
  story, and how does it *hurt* it?
- What happens to a storage account that uses CMK if the Key Vault is
  in a different region and that region becomes unavailable?

## ${country.name}-specific pitfalls

- **Premium Key Vault availability:** `${country.azure.cmk_hsm_sku}` Key
  Vault is available in `${country.azure.primary_region}`, but Azure
  Managed HSM is **not** in every region — confirm before promising it to
  the SARB inspector.
- **HSM key types:** CMK on Storage requires `RSA` or `RSA-HSM` keys of
  size 2048, 3072 or 4096. A symmetric `oct-HSM` key will not work for
  Storage even though it works for other services.
- **Soft delete cannot be disabled** on new vaults — design the recovery
  procedure assuming a 90-day retention window.

## Regulatory anchors

- POPIA s.19 — security safeguards (confidentiality, integrity)
- POPIA s.20 — Information processed by operator or person acting under
  authority
- SARB Directive 3/2018 — cloud computing and offshoring of data
- FSCA Joint Standard 2 of 2024 — cybersecurity and cyber resilience
- PCI DSS v4.0 §3.5 — cryptographic key management
- ${country.regulatory.regulator_links}

## Stretch goals

- Add Azure Backup with a vault-encrypted backup of the Storage account
  and prove the backup is also encrypted with the same CMK.
- Build an Azure Policy that **denies** any new Storage account in the
  bank's management group that does not declare a CMK at create time.
- Add an Azure Monitor alert on `KeyVault.Vault.Delete` and
  `KeyVault.Key.Disable` operations, routed to the SOC.
