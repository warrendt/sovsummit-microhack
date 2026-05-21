# Challenge AE-02 — Confidential AKS + CMK for a DIFC-licensed bank

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Paired region:** `${country.azure.paired_region}` (${country.azure.paired_region_display})

## Scenario

You are the cloud security architect for **${country.scenarios.financial_tenant}**.
The bank wants its next digital-onboarding and payments release to run fully in
`${country.azure.primary_region}` while satisfying three parallel expectations:

1. **DIFC Data Protection Law** for personal-data handling inside the DIFC
   legal perimeter.
2. **CBUAE Consumer Protection Regulation / Standards** for customer data,
   outsourcing controls and complaints evidence.
3. **UAE IAS** control expectations for key management, logging and privileged
   access.

The board has approved Azure only if the sensitive onboarding and fraud-scoring
workloads run on **confidential-computing infrastructure**, with customer-
managed keys kept in a **Premium Key Vault** in `${country.azure.primary_region}`.

## Objectives

- Deploy an **AKS cluster** in `${country.azure.primary_region}` with at least
  one **confidential node pool** using a supported SKU from
  `${country.azure.confidential_compute_skus}`.
- Store CMK material in a **Premium Key Vault** in `${country.azure.primary_region}`
  and use it for the storage layer that persists onboarding documents,
  screening results and payment-support evidence.
- Mount secrets into the workloads through the **Key Vault CSI provider** and
  keep signing / encryption keys outside application containers.
- Enforce an Azure Policy initiative **`DIFC Confidential Banking Baseline`**
  that requires:
  - allowed locations = `${country.azure.primary_region}` and
    `${country.azure.paired_region}`;
  - confidential-compute node pools for namespaces tagged
    `banking-tier=regulated`;
  - CMK-backed storage and purge protection on the Key Vault;
  - diagnostic settings flowing to a banking security workspace in
    `${country.azure.primary_region}`.
- Produce an evidence pack for internal audit showing that decrypted customer
  data is processed only inside confidential nodes and that key custody remains
  in-country.

## Success criteria

- [ ] `az aks show` confirms the cluster is in `${country.azure.primary_region}`
      and includes a confidential node pool.
- [ ] `az keyvault show` confirms `sku.name = ${country.azure.cmk_hsm_sku}` and
      `properties.enablePurgeProtection = true`.
- [ ] A regulated workload cannot schedule onto a non-confidential node pool.
- [ ] A storage account or disk created without CMK is denied by policy.
- [ ] Your walkthrough demonstrates how the bank would evidence DIFC + CBUAE +
      UAE IAS alignment to an auditor.

## Hints

- Use a node label / taint pattern so only regulated namespaces land on the
  confidential node pool.
- For AKS, combine confidential node pools with **Kata / isolated workload**
  settings where available in the region and cluster version you select.
- Keep the Key Vault and Log Analytics workspace in `${country.azure.primary_region}`;
  use `${country.azure.paired_region}` only for DR replicas and backup recovery.
- Map your controls back to the legal stack explicitly: DIFC DP Law for data
  handling, CBUAE for customer-protection evidence, UAE IAS for security
  baseline controls.

## Estimated duration

90 minutes.
