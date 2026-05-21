# Challenge 6 — Sovereign hybrid for a South Africa municipality

[Previous Challenge](challenge-05.md) — **[Home](../Readme.md)** — Next: [Finish](finish.md)

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

## Learning objectives

- Explain the role of **Azure Arc**, **Azure Local** and **Arc-enabled
  servers** in a sovereign hybrid architecture, and where the line is
  between Microsoft-managed and customer-managed.
- Onboard a Linux and a Windows machine to Azure Arc and verify they
  appear as `Microsoft.HybridCompute/machines` resources.
- Apply an Azure Policy initiative (the one from Challenge 1) at a scope
  that covers both Azure-native and Arc-enabled servers, and observe
  compliance across both.
- Deploy a VM on Azure Local through the Azure portal and explain when
  this is the right answer vs deploying to `southafricanorth`.
- Use **Azure Update Manager** to schedule a maintenance window across
  the hybrid estate.
- Enable **Defender for Cloud** for Arc-enabled servers and triage the
  resulting recommendations.

## Success criteria

- [ ] At least one **ArcBox** or equivalent jumpstart environment is
      running and at least three Arc-enabled servers appear in the Azure
      portal under `Azure Arc > Servers`.
- [ ] At least one **LocalBox** (or your own Azure Local deployment) is
      running and visible under `Azure Local`.
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
- {'name': 'Information Regulator (South Africa)', 'url': 'https://inforegulator.org.za/'}, {'name': 'South African Reserve Bank', 'url': 'https://www.resbank.co.za/'}, {'name': 'Financial Sector Conduct Authority', 'url': 'https://www.fsca.co.za/'}

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
