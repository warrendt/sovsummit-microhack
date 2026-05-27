# Challenge 6 — Sovereign hybrid for a South Africa municipality

[Previous Challenge](challenge-05.md) — **[Home](../README.md)** — Next: [Finish](finish.md)

## The situation

A large South African metropolitan municipality runs billing, water
metering, traffic and SCADA systems across dozens of sites — many in
neighbourhoods with unreliable connectivity or persistent load-shedding.
Some workloads (SCADA, CCTV) **cannot** run in a public Azure region for
operational reasons; others (billing analytics, citizen self-service)
absolutely should, because the public-region scale and reliability is the
whole point.

The Auditor-General has flagged that today the municipality has *no*
unified view of which servers are patched, which run unsupported OSes,
and which collect personal information of residents. Each site is "the
sysadmin's empire", and POPIA s.19 + s.55 obligations are effectively
unenforceable across the estate.

## Your mission

Bring the on-premises estate under a **single Azure control plane** using
**Azure Arc** and the **Azure Local + Arc Jumpstart LocalBox** pattern,
so the same Azure Policy, Defender for Cloud, Update Manager and Machine
Configuration capabilities you applied to your cloud workloads in
Challenges 1–5 now reach the sovereign on-prem estate too.

> **Shared environment — ArcBox + LocalBox are already running.**
> Both Jumpstart environments take 30 min (ArcBox) and 4–6 h (LocalBox) to
> stand up, so your coach pre-deploys **one shared** `rg-arcbox` and
> `rg-localbox` for everyone to explore. You will *not* be deploying these
> from scratch. Your contribution is to **onboard new Arc-enabled servers
> from your own `labuser-NN` resource group**, point the Challenge 1
> initiative at the shared Arc estate, and prove that Defender + Update
> Manager + Machine Configuration treat your Arc-enabled servers like
> first-class Azure citizens.
>
> Ask your coach for **Reader** access on `rg-arcbox` and `rg-localbox`
> if you can't see them yet.

## Learning objectives

- Explain the role of **Azure Arc**, **Azure Local** and **Arc-enabled
  servers** in a sovereign hybrid architecture, and where the line is
  between Microsoft-managed and customer-managed.
- Onboard a Linux **and** a Windows machine **that you deploy in your
  `labuser-NN` RG** to Azure Arc and verify they appear as
  `Microsoft.HybridCompute/machines` resources alongside the shared
  ArcBox-managed nodes.
- Apply an Azure Policy initiative (the one from Challenge 1) at a scope
  that covers both Azure-native and Arc-enabled servers, and observe
  compliance across both.
- Walk through how a municipal admin would deploy a VM onto **Azure
  Local** through the Azure portal (using the shared `rg-localbox`
  cluster) and explain when this is the right answer vs deploying to
  `southafricanorth`.
- Use **Azure Update Manager** to schedule a maintenance window across
  the hybrid estate.
- Enable **Defender for Cloud** for Arc-enabled servers and triage the
  resulting recommendations.

## Success criteria

- [ ] You can read the shared **ArcBox** environment (`rg-arcbox`) and
      confirm at least three Arc-enabled servers appear in the Azure
      portal under `Azure Arc > Servers`.
- [ ] You can read the shared **LocalBox** environment (`rg-localbox`)
      and confirm the Azure Local cluster appears under `Azure Local`.
- [ ] You have **onboarded at least one new Arc-enabled server** that
      you deployed yourself (in your `labuser-NN` RG or as a local VM
      onboarded via `azcmagent connect`) — it must appear in the same
      `Azure Arc > Servers` list with a clear name marking it as
      yours (`labuserNN-arc-linux` or similar).
- [ ] The policy initiative from Challenge 1 is assigned at a management
      group scope that includes the Arc-enabled servers, and the
      compliance dashboard reports state for **both** Azure-native and
      Arc-enabled resources.
- [ ] An **SSH Posture Control** (or equivalent Windows posture)
      assignment is in place against the Linux Arc-enabled servers,
      reporting compliance via Azure Machine Configuration.
- [ ] You have deployed (or shown how to deploy) a VM onto Azure Local
      from the Azure portal.
- [ ] **Defender for Cloud** is enabled for the Arc-enabled servers and
      you can show at least one actionable recommendation per server.
- [ ] **Azure Update Manager** shows the Arc-enabled servers, you have
      assessed pending updates, and you have a scheduled maintenance
      configuration.
- [ ] Evidence pack maps the hybrid controls to **POPIA s.19** (security
      safeguards), **POPIA s.55** (Information Officer duty to ensure
      compliance), and notes any operational-technology subset that
      remains on-prem for national-security / continuity reasons.

## Guiding questions

- Why does Microsoft treat "Arc-enabled server" as an Azure resource
  even though the OS is running in a municipal data centre? What
  changes for billing, identity, RBAC and policy?
- A municipal SCADA controller must *never* be reachable from the
  internet. How does Arc still keep it visible to Azure Policy and
  Defender without exposing it?
- The Auditor-General asks "are all your servers patched within 14 days
  of release?" How does Azure Update Manager turn that from a manual
  spreadsheet into an evidence-backed answer?
- Where do you draw the line between "this workload belongs on Azure
  Local" and "this workload belongs in `southafricanorth`"?

## South Africa-specific pitfalls

- **Connectivity from disconnected sites:** Arc agent requires outbound
  HTTPS to Azure. Some municipal sites only have intermittent
  connectivity — design the onboarding sequence and policy reporting
  cadence accordingly.
- **Load-shedding tolerance:** Azure Local clusters at sites without
  uninterruptible power must be designed for clean shutdown / restart.
- **LocalBox quotas / SKUs:** LocalBox deploys nested virtualisation;
  pick a region with enough capacity for `Standard_E*as_v5` or larger
  VMs (`westeurope` works well as a
  jumpstart region — for production, plan a true South Africa-based
  hardware footprint).
- **Identity in disconnected sites:** plan for Active Directory + Entra
  Connect resilience; an Arc-enabled server is useless to Defender if
  no identity claim can be made for it.

## Regulatory anchors

- POPIA s.19 — security safeguards
- POPIA s.55 — Information Officer duties
- POPIA s.22 — security compromise notification (still applies to
  on-prem systems!)
- National Cybersecurity Policy Framework — critical information
  infrastructure
- [Information Regulator (South Africa)](https://inforegulator.org.za/)
- [South African Reserve Bank](https://www.resbank.co.za/)
- [Financial Sector Conduct Authority](https://www.fsca.co.za/)

## Stretch goals

- Add **Azure Monitor for Hybrid** so you can visualise CPU/memory/disk
  for Arc-enabled servers in the same workbook as your Azure-native
  servers.
- Author a custom Machine Configuration policy that audits a
  municipality-specific baseline (e.g. "rsyslog must forward to the
  municipal SIEM at 10.x.y.z").
- Build a one-page architecture diagram showing which workloads live in
  `southafricanorth`, which live in
  `southafricawest` for DR, and which live on Azure Local
  at municipal sites — annotated with the regulatory driver per box.
