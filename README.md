# Sovereignty Summit — MicroHack

A six-challenge, hands-on workshop that takes a fictional regulated bank from
"sovereignty is a slide" to a real, policy-enforced Azure landing zone — with
data residency, customer-managed encryption, observability, confidential
compute, sovereign AKS and Azure Local / Azure Arc on-premises sovereignty.

The reference edition is **South Africa** (POPIA + SARB). Each additional
country folder reframes the same six challenges for its own regulator(s) and
sovereignty pattern.

---

## What attendees learn

| #  | Challenge                              | Key Azure surfaces                                                |
|----|----------------------------------------|-------------------------------------------------------------------|
| 1  | **Data residency by policy**           | Azure Policy `allowedLocations`, custom initiative, deny-vs-audit |
| 2  | **Customer-managed encryption**        | Key Vault Premium, BYOK, CMK on Storage / Key Vault references    |
| 3  | **Sovereign observability**            | Log Analytics, Diagnostic Settings, policy-enforced collection    |
| 4  | **Confidential VMs + Attestation**     | DCasv5/DCesv5, Azure Attestation, secure-boot evidence            |
| 5  | **Sovereign AKS**                      | AKS w/ confidential nodes, KEDA, CVM attestation pod              |
| 6  | **Azure Arc + Azure Local on-prem**    | ArcBox + LocalBox, hybrid sovereignty, Defender for Cloud         |

Each country folder contains the **rendered, ready-to-run** material — there is
no template or build step. To read challenge 1 for South Africa, open
[`countries/za/challenges/challenge-01.md`](countries/za/challenges/challenge-01.md).

> **Attending the live lab?** Start at [`countries/za/PREREQUISITES.md`](countries/za/PREREQUISITES.md) — it's the 5-minute sign-in + env-var setup every other doc assumes you've done.

---

## Country index

| Code | Country         | Status            | Folder                                          |
|------|-----------------|-------------------|-------------------------------------------------|
| `za` | South Africa    | **Reference — fully tested** | [`countries/za/`](countries/za/)     |
| `ae` | UAE             | Preview           | [`countries/ae/`](countries/ae/)               |
| `eg` | Egypt           | Preview           | [`countries/eg/`](countries/eg/)               |
| `ng` | Nigeria         | Preview           | [`countries/ng/`](countries/ng/)               |
| `qa` | Qatar           | Preview           | [`countries/qa/`](countries/qa/)               |
| `sa` | Saudi Arabia    | Preview           | [`countries/sa/`](countries/sa/)               |

---

## Quick start (engineer mode — one subscription, one engineer)

You need: an Azure subscription you have Owner on, Azure CLI (`az`), Bicep
(`az bicep install`), and roughly 30 minutes for the first deployment.

```bash
git clone https://github.com/warrendt/sovsummit-microhack.git
cd sovsummit-microhack/countries/za/bootstrap

# Preview what gets created
./build-za.sh --what-if

# Stand it up (single-engineer mode)
./build-za.sh

# When you're done
./teardown-za.sh --apply
```

The script registers resource providers, deploys `main.bicep` at subscription
scope, and prints the resource group + Key Vault + storage account you need
for challenge 1. Then open
[`countries/za/challenges/challenge-01.md`](countries/za/challenges/challenge-01.md).

---

## Coach mode (a summit of 5-60 attendees on a shared subscription)

```bash
cd countries/za/bootstrap

./build-za.sh --coach \
    --attendees 40 \
    --lab-users-group LabUsers \
    --submit-quota-requests \
    --create-summit-group \
    --apply-ca-exclusion
```

Coach mode runs, in order:

1. `subscription-prep/2-vcpu-quotas.ps1`   — region quota check (+ optional request)
2. `subscription-prep/3-rbac.ps1`          — custom `Deployment Validator` role + group RBAC
3. `subscription-prep/4-resource-groups.ps1` — N numbered `labuser-NN` RGs + Owner
4. _(optional, requires internal helpers)_ create `Microhack Sovereignty Summit` parent group + CA exclusion
5. `main.bicep` deployment

Cleanup with `./teardown-za.sh --apply --remove-users --purge-keyvault`.

### Add-ons (off by default — they cost real money)

| Flag                  | Adds                                                                            |
|-----------------------|---------------------------------------------------------------------------------|
| `--deploy-arcbox`     | ArcBox-full into `rg-arcbox` in `swedencentral` (~30 min, ~hundreds USD/day)     |
| `--deploy-localbox`   | LocalBox host VM + Azure Local instance (~4-6 h, ~thousands USD/day)             |
| `--create-users`      | Create `N` lab + admin users + Temporary Access Passes (requires private helpers — see CONTRIBUTING) |

ArcBox + LocalBox feed **challenge 6** (the on-prem sovereignty story). They
are shared coach demos — attendees observe them; the policy posture is set up
so the residency policy does **not** block them.

---

## Repository layout

```
sovsummit-microhack/
├── README.md            # this file
├── CONTRIBUTING.md      # how to add a country (copy ZA, rename, edit)
├── LICENSE
├── .github/workflows/   # bicep + markdown lint
└── countries/
    ├── za/              # full edition — challenges, walkthroughs, bootstrap, demo VMs
    ├── ae/ eg/ ng/ qa/ sa/   # preview editions — country-specific challenges only
```

Per-country folders are independent: nothing under `countries/za/` references
any sibling country, and there is no shared `common/` directory or
template-rendering build step.

---

## Adding a country

See [`CONTRIBUTING.md`](CONTRIBUTING.md). The short version: copy `countries/za/`,
rename, and rewrite the regulator-specific language in each challenge.

---

## License

MIT — see [`LICENSE`](LICENSE). Based on the Microsoft
[Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud).
