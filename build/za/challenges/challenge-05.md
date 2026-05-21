# Challenge 5 — Confidential AKS for South Africa fraud-detection inference

[Previous Challenge](challenge-04.md) — **[Home](../Readme.md)** — Next: [Challenge 6](challenge-06.md)

## The situation

A South African tier-1 retail bank issuing virtual cards has trained a fraud-detection model
that scores card-not-present transactions in real time. The model itself is
considered a competitive asset; the features it consumes (cardholder name,
PAN, merchant category, geolocation) are POPIA personal information and
PCI cardholder data.

The data science team wants to run the scoring service on AKS so it can
scale. Risk has refused — they do not want a cluster admin to be able to
`kubectl exec` into a scoring pod and dump features from memory while the
model is running.

You have been asked to design an AKS topology where:

- The scoring pods run inside **confidential** node pools so memory is
  encrypted from the cluster operator's perspective.
- Attestation gates model decryption: the pod can only retrieve the model
  weights and the feature-decryption key after proving it is running on
  attested confidential hardware.
- Existing **non-confidential** workloads (logging, dashboards,
  observability) can run on cheaper standard node pools in the same
  cluster.

## Your mission

Stand up an AKS cluster that mixes standard and confidential node pools,
deploy the scoring workload onto the confidential pool with attestation,
and prove that even a cluster admin cannot read the in-memory features.

## Learning objectives

- Compare **confidential VM node pools** vs **confidential containers
  (Kata-CC)** on AKS — which scenario fits which workload.
- Add a confidential node pool with `--enable-encryption-at-host` and a
  CC-capable VM size to an existing AKS cluster.
- Use `nodeSelector` / `taints + tolerations` to pin a deployment to the
  confidential pool.
- Integrate the AKS workload with Microsoft Azure Attestation so the pod
  retrieves an attestation token, presents it to Key Vault via
  Secure Key Release (SKR), and only then unwraps a data-encryption key.
- Demonstrate "encryption in use" to a risk officer using observable
  evidence, not just slides.

## Success criteria

- [ ] An AKS cluster exists in `southafricanorth` with at
      least two node pools: one standard (`Standard_D*s_v5`) and one
      confidential (`Standard_DC*as_v5`).
- [ ] The confidential node pool has `enableEncryptionAtHost = true` and
      is tainted so only opted-in workloads land on it.
- [ ] A sample scoring deployment lands **only** on the confidential
      node pool (verify with `kubectl get pods -o wide`).
- [ ] The pod successfully obtains an MAA attestation token at startup
      and the token validates against the MAA provider's JWKS.
- [ ] The pod uses **Workload Identity** (not pod-managed identity) to
      authenticate to Key Vault.
- [ ] Key Vault releases a wrapped data-encryption key *only* when the
      attestation token's `x-ms-compliance-status` claim says
      `azure-compliant-cvm`; if you tamper with the token, the release
      is denied.
- [ ] Cluster admin tries to `kubectl exec` into the scoring pod and
      dump `/proc/<pid>/maps` — the pod still runs, but the in-memory
      feature buffers are not accessible in cleartext (CVM memory
      encryption boundary holds).
- [ ] Evidence pack maps the control to **POPIA s.19**, **SARB
      Directive 3/2018 §6.4** (encryption controls) and **PCI DSS v4.0
      §3.6.1** (key management for cardholder data).

## Guiding questions

- Where does the trust boundary sit in a confidential AKS pod — at the
  hypervisor, the host OS, the container, or the application?
- A teammate suggests "let's just use a confidential VM and skip AKS".
  When is that the right call, and when does AKS pay off?
- Workload Identity vs the older Azure AD Pod Identity — why is the
  former strongly preferred for a regulated workload?
- The model itself needs to be decrypted somewhere. Where in the boot
  sequence is the *latest* safe moment to decrypt it, and why?

## South Africa-specific pitfalls

- **AKS preview features:** confidential containers / Kata-CC may be in
  preview on `southafricanorth`. Stick to confidential
  *VM* node pools unless you have explicitly validated preview support
  in this region.
- **CC SKU quota** (same as Challenge 4) — request it ahead of time.
- **Workload Identity prerequisites:** OIDC issuer and Workload Identity
  must be enabled on the cluster at create time (or via `az aks update`).
  Forgetting this is the most common cause of a 4-hour "why won't my pod
  talk to Key Vault" debug session.
- **Cluster autoscaler + confidential pool:** if the autoscaler scales
  the standard pool too aggressively, dependent services may land on
  non-confidential nodes — pin them explicitly.

## Regulatory anchors

- POPIA s.19 — security safeguards
- POPIA s.20 — operator obligations
- SARB Directive 3/2018 §6.4 — encryption controls in cloud
- FSCA Joint Standard 2 of 2024 — cyber resilience
- PCI DSS v4.0 §3.6.1 — cryptographic key management
- {'name': 'Information Regulator (South Africa)', 'url': 'https://inforegulator.org.za/'}, {'name': 'South African Reserve Bank', 'url': 'https://www.resbank.co.za/'}, {'name': 'Financial Sector Conduct Authority', 'url': 'https://www.fsca.co.za/'}

## Stretch goals

- Add **Microsoft Defender for Containers** and confirm it can monitor
  the confidential pool without breaking confidentiality.
- Wrap the attestation-then-unwrap pattern into a sidecar (a "secrets
  gateway") so application teams don't have to implement it themselves.
- Run a load test and capture per-pod cost — produce a one-page memo
  recommending which other workloads in the bank justify moving to
  confidential AKS.
