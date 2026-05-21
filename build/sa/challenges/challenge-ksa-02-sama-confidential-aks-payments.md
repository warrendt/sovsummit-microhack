# Challenge KSA-02 — SAMA confidential AKS for a payments workload with in-country logging and exit plan

> **Country:** Saudi Arabia
> **Edition:** Sovereignty Summit Saudi Arabia 2026
> **Primary region:** `saudiarabiaeast` (Saudi Arabia East)
> **Confidential compute SKUs in scope:** Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5

## Scenario

You are the chief cloud architect for **A SAMA-regulated bank running instant payments and digital-wallet services**.
The bank's regulator has approved a container platform for payment services only
if you can prove the following:

1. The payments workload runs on **confidential AKS worker nodes** in
   `saudiarabiaeast`.
2. Disk keys, application secrets, and signing material stay under **bank
   custody in the Kingdom**, using a bank-owned HSM or a
   `Premium` Key Vault / Managed HSM with strict RBAC.
3. All security logs, audit records, and container diagnostics stay in-country.
4. The bank can **exit or repatriate** the workload without vendor lock-in:
   manifests, images, encrypted backups, and key-rotation procedures must be
   exportable to a bank-controlled target platform.

Regulatory context: **Saudi Central Bank (SAMA)** for the
bank, plus PDPL and the NCA baseline controls.

## Objectives

- Deploy a **private AKS cluster** in `saudiarabiaeast` with a
  dedicated confidential node pool for the `payments` namespace.
- Enforce **CMK everywhere**: node OS disks, storage accounts, and any stateful
  component backing the payments workload.
- Retrieve secrets through **workload identity + CSI driver** instead of
  embedding secrets in Kubernetes manifests.
- Send **Azure Monitor / Container Insights / Activity Logs** only to a Log
  Analytics workspace in `saudiarabiaeast`.
- Produce an **exit and repatriation runbook** covering manifest export, image
  escrow, Velero backups, key rotation, and restore to a bank-controlled target
  cluster.

## Success criteria

- [ ] `az aks nodepool list` shows a payments node pool using one of
      `Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5`.
- [ ] The cluster is **private**, and payments pods schedule only to the
      confidential node pool using labels / taints.
- [ ] `az aks show` / `az monitor diagnostic-settings list` show logs flowing
      only to `saudiarabiaeast`.
- [ ] Secrets and encryption keys are sourced from bank-controlled key custody
      in `saudiarabiaeast`; no plaintext Kubernetes secrets are
      committed to Git.
- [ ] A repatriation drill restores the application from backup and exported
      manifests into a bank-controlled target while preserving the documented
      RTO/RPO.

## Hints

- Use a standard system pool for cluster services, then add a **confidential
  user node pool** sized from `Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5`.
- Pair **Azure Policy for AKS** with Gatekeeper constraints to deny public load
  balancers, privileged pods, and unapproved registries.
- For key custody, model either:
  - Bank-owned HSM → BYOK into Azure Key Vault / Managed HSM, or
  - Managed HSM in `saudiarabiaeast` with customer-exclusive RBAC.
- Exit planning should cover **images, manifests, secrets, certificates,
  database backups, and DNS cutover** — not just Kubernetes YAML.

## Estimated duration
120 minutes.
