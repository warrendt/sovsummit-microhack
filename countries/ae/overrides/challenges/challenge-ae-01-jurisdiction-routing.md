# Challenge AE-01 — Route workloads to the correct UAE legal perimeter

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Paired region:** `${country.azure.paired_region}` (${country.azure.paired_region_display})

## The situation

You are the platform lead for **${country.scenarios.public_sector_tenant}**.
The programme has three legally distinct processing boundaries that all want to
share the same Azure estate:

1. An **onshore UAE operating entity** that runs the case-management platform.
2. A **DIFC booking / treasury function** that handles refunds and escrow.
3. An **ADGM analytics affiliate** that receives curated fraud and performance
   datasets.

The trap is that all three can technically deploy into
`${country.azure.primary_region}`. The Azure region is the same, but the legal
perimeter is not.

Your legal team wants a decision tree that answers, for every workload,
**which law applies, where data may land, and whether free-zone status changes
the answer**.

## Your mission

Build a jurisdiction-aware landing zone and regulator decision record that lets
an engineer classify a workload in minutes, not after a month of legal email.
The answer must distinguish between:

- **Federal PDPL + Executive Regulations** for onshore private-sector
  controllers/processors.
- **DIFC Data Protection Law** for DIFC-established processing.
- **ADGM Data Protection Regulations 2021** for ADGM-established processing.
- **Public-sector / government-data carve-outs** that do **not** automatically
  fall into federal PDPL and therefore require explicit legal sign-off.
- **Sector overlays** such as **CBUAE**, **DHA** and **TDRA** that sit on top of
  the main perimeter rather than replacing it.

## Learning objectives

By the end of this challenge you should be able to:

- Decide whether a workload belongs in the `federal-pdpl`, `difc`, `adgm`, or
  `public-sector-exception` decision path.
- Explain why **same-country hosting** does not remove the need to classify
  **which legal establishment** is acting as controller or processor.
- Encode that decision in Azure landing-zone structure, tags, policy, and
  exception workflow.
- Produce an evidence matrix that a legal, audit or regulator stakeholder can
  review without reverse-engineering your cloud estate.

## Decision tree you must implement

Work through these questions in order for **each processing boundary**, not just
for the overall programme:

1. **Is the controller / processor a UAE government authority or handling
   government data under a separate public-sector rule?**
   - If **yes**, do **not** assume federal PDPL applies.
   - Route to `public-sector-exception`, capture the governing law / mandate,
     and require legal sign-off before deployment.
2. **If not, is the controller / processor established in DIFC?**
   - If **yes**, route to `difc`.
3. **If not, is the controller / processor established in ADGM?**
   - If **yes**, route to `adgm`.
4. **If none of the above, is the controller / processor established onshore in
   the UAE mainland or another non-financial free zone?**
   - If **yes**, route to `federal-pdpl`.
5. **After the primary perimeter is set, which sector overlay applies?**
   - `cbuae-bank`, `dha-health`, `tdra-telecom`, or `none`.
6. **Where does the data land?**
   - Approved hosting locations are `${country.azure.primary_region}` and
     `${country.azure.paired_region}` only.
   - If data leaves those regions, raise a residency exception.
   - If data stays in-country but crosses from one legal perimeter to another,
     raise an **inter-perimeter transfer review**; same region does not collapse
     DIFC, ADGM and federal law into one regime.

## Build requirements

Create a landing-zone design with at least these scopes:

- `mg-ae-federal`
- `mg-ae-difc`
- `mg-ae-adgm`
- `mg-ae-exceptions` (or an equivalent documented exception register for public
  sector / government-data cases)

Enforce the following mandatory metadata:

| Tag | Allowed values | Why |
|---|---|---|
| `uae-regulatory-regime` | `federal-pdpl`, `difc`, `adgm`, `public-sector-exception` | Primary legal perimeter |
| `sector-overlay` | `none`, `cbuae-bank`, `dha-health`, `tdra-telecom` | Sector regulator overlay |
| `data-controller` | legal entity / authority name | Identifies who answers to the regulator |
| `data-processing-establishment` | `onshore`, `difc`, `adgm`, `government` | Encodes the decision-tree answer |
| `interperimeter-transfer` | `yes`, `no` | Flags perimeter-to-perimeter sharing |
| `exception-ticket` | change / legal approval ID | Mandatory for exception paths |

Build a policy initiative named **`UAE Jurisdiction Routing`** that:

- denies deployments outside `${country.azure.primary_region}` and
  `${country.azure.paired_region}`;
- denies any resource missing `uae-regulatory-regime`, `sector-overlay`,
  `data-controller`, and `data-processing-establishment`;
- denies a resource tagged `uae-regulatory-regime=difc` unless it lands in the
  DIFC scope;
- denies a resource tagged `uae-regulatory-regime=adgm` unless it lands in the
  ADGM scope;
- denies `public-sector-exception` workloads unless an `exception-ticket` is
  present;
- audits or denies `interperimeter-transfer=yes` workloads unless they are in an
  approved transfer scope / exception list.

## Success criteria

- [ ] A deployment to `westeurope` is denied at create time.
- [ ] A resource tagged `uae-regulatory-regime=difc` is denied in the federal
      scope.
- [ ] A resource tagged `uae-regulatory-regime=adgm` is denied in the DIFC
      scope.
- [ ] A resource tagged `public-sector-exception` is denied unless an
      `exception-ticket` is supplied.
- [ ] Your evidence matrix clearly distinguishes: legal establishment,
      applicable law, Azure landing zone, approved data location, and sector
      overlay for each sample workload.
- [ ] Your walkthrough explains why **DIFC/ADGM free-zone status changes the
      governing law even when the workload still runs in the same Azure UAE
      region**.

## Guiding questions

- When a DIFC business unit uses a shared onshore platform service, who is the
  controller and who is the processor at that boundary?
- If the dataset never leaves `${country.azure.primary_region}` but is shared
  from an onshore entity to an ADGM affiliate, why is that still a legal
  transfer question?
- Which cases deserve a hard `deny` and which deserve an auditable legal
  exception workflow?
- If a Dubai health workload sits in the federal perimeter, which obligations
  come from PDPL and which come from health-sector rules?

## UAE-specific pitfalls

- **Government data is not a free pass into PDPL.** Pure government-authority
  processing generally sits outside federal PDPL and needs a documented
  alternate legal basis.
- **Free-zone status follows the legal establishment, not the subnet.** Running a
  DIFC workload in `${country.azure.primary_region}` does not convert it into an
  onshore federal-PDPL workload.
- **Shared services are the hardest boundary.** A central logging, integration or
  analytics service can create inter-perimeter transfers even if the workload
  topology looks simple on an Azure diagram.
- **Sector overlays stack.** A banking workload can be `federal-pdpl + cbuae-bank`;
  a Dubai health workload can be `federal-pdpl + dha-health`.

## Regulator evidence table

Your evidence pack should include at least these columns:

| Workload | Controller / processor establishment | Primary perimeter | Sector overlay | Azure scope | Approved region(s) | Inter-perimeter transfer? | Legal ticket |
|---|---|---|---|---|---|---|---|
| Case-management API | Onshore | Federal PDPL | None / TDRA | `mg-ae-federal` | `${country.azure.primary_region}`, `${country.azure.paired_region}` | No | N/A |
| Refunds / treasury app | DIFC | DIFC DP Law | Financial-sector review as applicable | `mg-ae-difc` | `${country.azure.primary_region}`, `${country.azure.paired_region}` | Yes | Required |
| Analytics workspace | ADGM | ADGM DPR 2021 | None | `mg-ae-adgm` | `${country.azure.primary_region}`, `${country.azure.paired_region}` | Yes | Required |

## Regulator references

- [UAE Government data protection overview](https://u.ae/en/about-the-uae/digital-uae/data/data-protection-laws)
- [DIFC data protection](https://www.difc.ae/business/laws-regulations/data-protection/)
- [ADGM Office of Data Protection](https://www.adgm.com/operating-in-adgm/office-of-data-protection)
- [CBUAE Rulebook](https://rulebook.centralbank.ae/)
- [TDRA](https://tdra.gov.ae/)
- [Dubai Health Authority](https://www.dha.gov.ae/)

## Stretch goals

- Automate the decision tree in an intake form that writes the required tags
  before a subscription is approved.
- Export policy state daily to an in-country workspace and legal review queue.
- Add a custom policy that forces shared services (integration, logging,
  analytics) to declare `interperimeter-transfer=yes|no` explicitly.
