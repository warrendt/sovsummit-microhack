# Challenge 3 — TLS in transit between ${country.name} regulators, banks & government

[Previous Challenge](challenge-02.md) — **[Home](../Readme.md)** — Next: [Challenge 4](challenge-04.md)

## The situation

${country.scenarios.public_sector_tenant} is exposing a new citizen-facing
API. It will be called by:

- South African banks under SARB's open-banking sandbox.
- A SADC partner government, over the public internet.
- The department's own mobile app on tens of millions of devices, many on
  older Android handsets.

The SOC has already seen probing traffic on the staging endpoint trying
weak TLS 1.0 + RC4 cipher suites. Legal is nervous: a leak of citizen
records in transit would be reportable to the Information Regulator as a
**security compromise under POPIA s.22**.

You need to make sure every byte of personal information leaves Azure
**only** over a strong, current TLS channel — *and* you need to prove it
to an auditor next month, **without** breaking the older mobile app
clients that are still on TLS 1.2.

## Your mission

Set the secure-transport baseline on the data-bearing platform services,
prove that weaker clients are rejected, and stand up the monitoring that
tells you when the baseline drifts.

> **Build inside your assigned `labuser-NN` resource group.** Create your
> own Log Analytics workspace there for the KQL evidence — don't share the
> coach foundation workspace. Your Storage accounts + App Service from this
> challenge should be in the same RG so diagnostic-settings wiring is
> trivial.

## Learning objectives

By the end you should be able to:

- Distinguish between **TLS version**, **cipher suite**, and **certificate
  binding**, and which Azure service controls each.
- Force HTTPS-only (secure transfer required) on Azure Storage, App
  Service, and Key Vault.
- Set `MinimumTlsVersion = TLS 1.2` on Storage and App Service and
  enforce it across a subscription via Azure Policy with a `deny` effect.
- Use Log Analytics / KQL to discover what TLS version clients are
  actually negotiating, and identify clients that would break if you
  raised the floor to TLS 1.3.
- Explain the trade-off between "raise the floor now" and "raise the
  floor after a controlled deprecation window".

## Success criteria

- [ ] Every Storage account in the target subscription has
      `supportsHttpsTrafficOnly = true` and
      `minimumTlsVersion = TLS1_2`.
- [ ] An attempt to PUT a blob using `curl --tls-max 1.1` against any
      storage account in scope returns an error from the service
      (not from the network).
- [ ] An App Service in the target subscription has `minTlsVersion = 1.2`,
      `ftpsState = Disabled`, `httpsOnly = true`.
- [ ] An Azure Policy assignment **denies** the creation of any new
      Storage account or App Service that does not satisfy the above —
      try to create one and prove the deny works.
- [ ] A Log Analytics workspace in `${country.azure.primary_region}`
      receives `StorageBlobLogs` and you can produce a KQL query that
      answers: *"In the last 7 days, what's the distribution of
      `TlsVersion` per caller IP?"*
- [ ] You document at least one client/caller that would break if the
      minimum were raised to TLS 1.3, and propose a remediation plan
      (or evidence none exist and TLS 1.3 can be enforced today).
- [ ] Evidence pack maps each control to **POPIA s.19** (security
      safeguards) and notes **POPIA s.22** as the trigger condition for
      breach notification.

## Guiding questions

- Why is "HTTPS only" not the same as "TLS 1.2 minimum"? What attack
  does each prevent?
- Front Door / Application Gateway can terminate TLS in front of an App
  Service. Where should the policy floor be set — front door, app
  service, or both? Why?
- Some clients negotiate TLS 1.2 but with `TLS_RSA_WITH_AES_128_CBC_SHA`
  (no forward secrecy). Which Azure services let you restrict cipher
  suites, and which don't?
- You raise minTLS to 1.2 and the next morning a partner bank's CTO calls
  saying their batch job is failing. What's your incident response
  *before* you change the setting back?

## ${country.name}-specific pitfalls

- **Log Analytics region:** if you allowed the platform team to put the
  workspace in `westeurope` for cost reasons, your audit telemetry is now
  leaving South Africa and you have just created a **POPIA s.72** issue.
  Pin the workspace in `${country.azure.primary_region}` first, then enable
  diagnostics.
- **Public endpoints on data services:** Azure Storage minimum TLS only
  helps for clients that reach the *public* endpoint. Workloads behind a
  private endpoint enforce TLS at the transport but you still need to
  verify *application-level* TLS on intermediate components.
- **Older Android devices** on the South African market may negotiate
  TLS 1.2 but with broken cipher suite preferences — capture real client
  data before raising any floor.

## Regulatory anchors

- POPIA s.19 — security safeguards
- POPIA s.22 — notification of security compromises
- SARB Directive 3/2018 — cloud computing
- FSCA Joint Standard 2 of 2024 — cyber resilience
- ${country.regulatory.regulator_links}

## Stretch goals

- Add an Azure Workbook that visualises TLS version distribution per
  service per day for the past 30 days.
- Use **Azure Front Door** with a custom WAF rule that blocks any
  request whose `User-Agent` claims a known-broken legacy TLS stack.
- Pilot TLS 1.3 enforcement on one Storage account using policy `audit`
  before flipping it to `deny`.
