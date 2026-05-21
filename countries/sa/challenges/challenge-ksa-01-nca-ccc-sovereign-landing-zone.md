# Challenge KSA-01 — NCA CCC sovereign landing zone for a Saudi government platform

> **Country:** Saudi Arabia
> **Edition:** Sovereignty Summit Saudi Arabia 2026
> **Primary region:** `saudiarabiaeast` (Saudi Arabia East)
> **DR exception region:** `qatarcentral` (Qatar Central)

## Scenario

You are the sovereign platform lead for **A Saudi Vision 2030 government entity operating a national licensing and permits platform**.
The architecture board will only approve Azure if the landing zone proves four
things at design-review time:

1. The tenant structure uses a **management-group hierarchy** that cleanly
   separates platform services, production workloads, and any cross-border
   disaster-recovery exception scope.
2. The default policy position is **Saudi Arabia East only**. `qatarcentral`
   can be used **only** for regulator-approved DR resources, not as a general
   secondary region.
3. Customer-managed keys, signing keys, backup keys, and operational telemetry
   stay in `saudiarabiaeast`, with HSM-backed custody and auditable
   separation of duties.
4. Every Azure guardrail can be traced to the **NCA Cloud Cybersecurity Controls
   (CCC – 2: 2024)**, with inherited baseline obligations from **ECC-2:2024** and
   PDPL transfer governance.

## What you are building

### Target hierarchy

```text
Tenant Root
└── mg-sovsummit-ksa
    ├── mg-ksa-platform
    │   ├── logging
    │   ├── identity
    │   └── key-custody
    ├── mg-ksa-workloads
    │   ├── shared-services
    │   └── prod-landingzones
    └── mg-ksa-dr-exception
        └── approved-cross-border-recovery-only
```

### Design rules for this challenge

- `mg-sovsummit-ksa` and `mg-ksa-workloads` allow **only** `saudiarabiaeast`.
- `mg-ksa-dr-exception` allows `saudiarabiaeast` plus
  `qatarcentral`, but resources in `qatarcentral` must
  be tagged `ksa-dr-approved=true` and recorded in a DR exception register.
- The policy-assignment managed identity, Log Analytics workspace, Key Vault, and
  HSM-backed keys all live in `saudiarabiaeast`.
- Zonal resilience inside `saudiarabiaeast` is the default HA posture;
  cross-border recovery is a board-level exception path.

## Objectives

By the end of this challenge you will have:

- Created a **Saudi sovereign landing-zone hierarchy** with separate `platform`,
  `workloads`, and `dr-exception` management groups.
- Built an **NCA CCC initiative** that combines built-in and custom policies to:
  - deny non-approved locations,
  - require a DR approval tag for `qatarcentral` resources,
  - enforce HSM-backed CMK for storage, SQL, and managed disks,
  - deploy diagnostics to a Log Analytics workspace in `saudiarabiaeast`,
  - require mandatory metadata tags such as `ksa-data-classification`,
    `ksa-regulator`, and `ksa-service-owner`.
- Provisioned a **Premium Key Vault / HSM-backed key store** in
  `saudiarabiaeast` with purge protection, soft delete, private access,
  and role-separated key administration.
- Documented a **control-evidence pack** that maps each guardrail to NCA CCC / ECC
  themes and the relevant PDPL cross-border-transfer obligation.

## Success criteria

- [ ] `az policy state list --management-group <mg>` returns zero `NonCompliant`
      resources for the KSA sovereign initiative after remediation.
- [ ] A test deployment to `uaenorth` or `westeurope` is **denied** at create time.
- [ ] A test DR resource in `qatarcentral` is denied unless it is
      placed under the DR-exception scope **and** tagged `ksa-dr-approved=true`.
- [ ] `az keyvault show` confirms the vault is in `saudiarabiaeast`,
      uses `Premium`, and has soft delete + purge protection.
- [ ] Activity Logs, resource logs, and platform diagnostics land only in
      `saudiarabiaeast`.
- [ ] Your evidence pack includes an explicit NCA CCC mapping table and a DR
      exception register entry for every non-Kingdom resource.

## Guided work plan

### 1) Establish the hierarchy

Create the management-group structure first. The policy model becomes much easier
when the exception scope is structurally separate from normal workloads.

### 2) Pin the geography

Assign `Allowed locations` and `Allowed locations for resource groups` at the root
or workload scope so `saudiarabiaeast` is the only normal target.
Then use a dedicated DR-exception assignment that allows `qatarcentral`
**only** under `mg-ksa-dr-exception`.

### 3) Build Saudi key custody

Use a `Premium` Key Vault in `saudiarabiaeast` or a
customer-owned HSM imported with BYOK. Separate the **Key Vault Administrator**,
**Key Vault Crypto Officer**, and workload identities so no single operator can both
create and misuse production keys.

### 4) Keep telemetry in-country

Create a Log Analytics workspace in `saudiarabiaeast` and use
`deployIfNotExists` / `modify` policies to steer Activity Logs and resource-level
monitoring there. Your design is incomplete if a developer can still point a
resource at a foreign workspace.

### 5) Prepare the DR exception path

Document the only allowed non-Kingdom pattern:

- approved recovery scope,
- approved data class,
- explicit regulator approval,
- transfer-risk assessment,
- evidence of key-handling and logging design,
- exit date or annual re-approval trigger.

## KSA-specific pitfalls

- **No implicit region pair:** `qatarcentral` is a workshop design
  assumption, not an official Microsoft region pairing. Treat it as a governed
  exception path.
- **Location policy alone is not enough:** without the companion resource-group
  policy, teams can create a compliant RG and drift later.
- **CMK without role separation is weak evidence:** auditors will ask who can
  create, wrap, rotate, disable, and purge keys.
- **Diagnostic settings can leak data:** the landing zone is non-sovereign if
  developers can attach a workspace or event stream outside `saudiarabiaeast`.
- **Policy remediation identities need rights:** `deployIfNotExists` and `modify`
  controls fail silently without the correct managed-identity RBAC.

## NCA CCC / ECC / PDPL control mapping

| Azure guardrail | Implementation expectation | NCA / PDPL mapping | Evidence to collect |
|---|---|---|---|
| Management-group separation | Dedicated `platform`, `workloads`, and `dr-exception` scopes | CCC governance and cloud-responsibility segregation; ECC governance baseline | Management-group tree, assignment scopes |
| Allowed locations = `saudiarabiaeast` | Deny at MG scope for resources and resource groups | CCC data-localization objective; PDPL transfer governance | Deny screenshot / CLI error |
| `qatarcentral` only by exception | Separate assignment + `ksa-dr-approved=true` + exception register | CCC cloud governance, continuity, and third-party control themes; PDPL Art. 29 transfer control | DR register, approval memo, tagged resource export |
| HSM-backed CMK in `saudiarabiaeast` | `Premium` Key Vault / BYOK, purge protection, RBAC separation | CCC cryptography and key-management themes; ECC protection of information assets | `az keyvault show`, key inventory, RBAC export |
| Diagnostic settings pinned in-country | Log Analytics workspace in `saudiarabiaeast` for Activity Logs and resource logs | CCC logging / monitoring themes; ECC monitoring baseline; PDPL accountability | Workspace location, diagnostic settings export |
| Mandatory data-classification tags | `ksa-data-classification`, `ksa-regulator`, `ksa-service-owner` | CCC data handling and governance themes | Resource graph / CSV export |
| CMK on storage, SQL, and disks | Policy-backed enforcement and remediation | CCC protection of cloud-hosted data; ECC asset-protection baseline | Policy compliance report, encryption settings |
| Evidence pack + periodic attestation | Exportable compliance bundle for auditors | CCC assurance and continuous-compliance expectation | CSV, screenshots, signed attestation |

## Regulator references

{'name': 'SDAIA / Personal Data Protection resources', 'url': 'https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/'}, {'name': 'Saudi Central Bank (SAMA) Rulebook', 'url': 'https://rulebook.sama.gov.sa/en/'}, {'name': 'National Cybersecurity Authority (NCA)', 'url': 'https://nca.gov.sa/en/regulatory-documents/'}

## Stretch goals

- Publish the initiative as Bicep and fail CI if a `deny` effect is weakened.
- Add a custom policy that denies Key Vault creation outside `saudiarabiaeast`.
- Create a quarterly attestation template for the agency CISO covering DR
  exceptions, key rotation, and logging integrity.
- Add an Azure Policy exemption workflow that forces approver name, expiry date,
  and PDPL transfer-risk-assessment ID.
