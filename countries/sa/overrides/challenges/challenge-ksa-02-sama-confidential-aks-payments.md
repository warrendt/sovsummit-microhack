# Challenge KSA-02 — SAMA confidential AKS for an instant-payments platform

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Confidential compute family:** DCasv5 / ECasv5 (`${country.azure.confidential_compute_skus}`)

## Scenario

You are the cloud architect for **${country.scenarios.financial_tenant}**. The bank is
modernizing its instant-payments stack (tokenization API, payment switch adapter,
fraud microservice, reconciliation worker) onto AKS. SAMA has given conditional
approval only if the design proves all of the following:

1. The `payments` namespace runs exclusively on **confidential AKS nodes** in
   `${country.azure.primary_region}`.
2. Persistent volumes use **customer-managed encryption keys** backed by an
   HSM-controlled key in `${country.azure.primary_region}`.
3. The network is segmented so only approved ingress, east-west, and egress flows
   are possible for the payment workloads.
4. Logs, audit trails, secrets, certificates, and break-glass procedures remain
   auditable for SAMA review.
5. The bank can exercise a clean **exit / repatriation** to another bank-controlled
   platform without losing keys, manifests, or recovery evidence.

## Target architecture

### Namespaces and node pools

- `kube-system` and shared platform add-ons run on a standard private system pool.
- `payments` runs on a **DCasv5 confidential user pool** only.
- `fraud-batch` can use confidential or standard compute depending on data class,
  but cardholder data and payment authorization services stay on confidential
  nodes.

### Network zones

| Subnet | Purpose | Key controls |
|---|---|---|
| `snet-aks-system` | AKS system pool / platform add-ons | Private cluster, restricted egress |
| `snet-aks-payments` | Confidential payments node pool | NSG denies internet ingress, limits east-west |
| `snet-private-endpoints` | Key Vault, Storage, ACR, monitoring private endpoints | Private Link only |
| `snet-egress` | Azure Firewall / controlled outbound | FQDN allowlist, logging |

### Mandatory design rules

- The AKS API is **private only**.
- Public `LoadBalancer` services are not allowed for `payments`.
- Persistent volumes for stateful components use Azure Disk CSI with a
  **Disk Encryption Set** backed by a `${country.azure.cmk_hsm_sku}` key.
- Secrets are delivered via **workload identity + Key Vault CSI driver**, not as
  plaintext Kubernetes secrets in Git.
- All diagnostics target a Log Analytics workspace in `${country.azure.primary_region}`.

## Objectives

By the end of this challenge you will have:

- Built a **private AKS cluster** in `${country.azure.primary_region}` with a dedicated
  confidential payments node pool based on the DCasv5 family.
- Configured **CMK-encrypted persistent volumes** by linking the Azure Disk CSI
  StorageClass to a Disk Encryption Set backed by an HSM-controlled key.
- Applied **NSG and Kubernetes network-policy segmentation** so only approved
  traffic paths exist between ingress, payment APIs, message brokers, data stores,
  and observability services.
- Routed **Azure Monitor, Container Insights, kube-audit, and Activity Logs** only
  to `${country.azure.primary_region}`.
- Produced a **SAMA evidence pack** covering cloud approval, vendor oversight,
  audit rights, data location, exit, and recovery rehearsal.

## Success criteria

- [ ] `az aks nodepool list` shows a confidential user pool using one of
      `${country.azure.confidential_compute_skus}`.
- [ ] `kubectl get pods -n payments -o wide` shows payment workloads scheduling only
      to the confidential node pool via labels / taints / tolerations.
- [ ] The cluster is private; no public AKS API endpoint or public `LoadBalancer`
      service is exposed for the regulated namespace.
- [ ] Payment PVCs resolve to managed disks encrypted through a Disk Encryption Set
      whose key lives in `${country.azure.primary_region}`.
- [ ] NSGs and network policies enforce ingress, east-west, and egress separation.
- [ ] Diagnostics and audit data flow only to `${country.azure.primary_region}`.
- [ ] A repatriation drill restores manifests, images, backups, and keys to a
      bank-controlled target while meeting the documented RTO/RPO.

## Guided work plan

### 1) Create the Saudi payment platform foundation

Stand up a private networking baseline, an in-country Log Analytics workspace,
and a `${country.azure.cmk_hsm_sku}` key store in `${country.azure.primary_region}`.
Decide whether the bank will use Azure HSM-backed custody or import a bank-owned
key via BYOK.

### 2) Build the private AKS cluster

Create a standard system pool first, then add a confidential DCasv5 node pool for
`payments`. Use taints and labels so regulated pods have a deterministic placement
story you can show to SAMA reviewers.

### 3) Enforce encrypted state

Create a Disk Encryption Set that references the HSM-backed key, then use an Azure
Disk CSI StorageClass for payment PVCs. This makes the **persistent volumes**, not
just the cluster, part of your CMK story.

### 4) Segment the network

Use NSGs for subnet-level controls and Kubernetes network policies for namespace-
level traffic. A good starting pattern is:

- ingress only from an approved internal gateway / private front end,
- east-west traffic only between explicitly listed services,
- egress only to approved private endpoints, bank DNS, and update channels.

### 5) Keep secrets and logs in-country

Use workload identity + Key Vault CSI driver for runtime secret retrieval. Point
AKS diagnostics, Activity Logs, and Defender / Container Insights to a workspace in
`${country.azure.primary_region}` and deny any alternate sink.

### 6) Rehearse exit and repatriation

Package the following as a mandatory deliverable:

1. Kubernetes manifests / Helm / Flux definitions.
2. Image escrow in a bank-controlled registry.
3. Velero or equivalent encrypted backups.
4. Key inventory, rotation process, and custody sign-off.
5. DNS, certificate, and cutover plan for target-platform recovery.

## KSA-specific pitfalls

- **“Confidential AKS” is not enough on its own:** you still need node-pool
  isolation, namespace placement controls, and PVC encryption evidence.
- **NSGs and network policies solve different problems:** subnet-level and pod-level
  controls should complement each other.
- **Private endpoints matter:** a private cluster with public Key Vault / ACR access
  still leaves an unnecessary exposure surface.
- **Audit rights must be contractually real:** SAMA expects review, audit, and exit
  terms to exist in the cloud-provider and vendor-management process, not just in
  architecture slides.
- **Exit planning is part of the initial approval:** treat image escrow, manifest
  export, and key return/destruction as day-one controls.

## SAMA control mapping

| Technical control | Implementation expectation | SAMA mapping | Evidence to collect |
|---|---|---|---|
| Board-approved payment-cloud pattern | Architecture, risk, and approval package for the workload | CSF 3.1 governance and policy | Approval memo, architecture review record |
| Cloud provider due diligence | Security / resilience assessment before go-live | CSF 3.4.1 contract & vendor management; 3.4.3 cloud computing | Due-diligence checklist, contract clauses |
| Saudi data location | AKS, keys, logs, backups in `${country.azure.primary_region}` by default | CSF 3.4.3(b) data location | Region inventory, workspace + key locations |
| Confidential compute for regulated namespace | DCasv5 confidential node pool with taints / tolerations | CSF operations & technology protection objectives | Nodepool list, workload placement export |
| CMK-encrypted persistent volumes | Disk Encryption Set + HSM-backed key for payment PVCs | CSF policy requirement to classify and protect information; 3.4.3(d) security | DES config, StorageClass, PVC / disk evidence |
| NSG + network-policy segmentation | Restricted ingress, east-west, and egress for payments subnet and namespace | CSF operations / network security expectations | NSG rules, network-policy YAML, flow logs |
| In-country logging and auditability | AKS diagnostics and Activity Logs to Saudi workspace only | CSF monitoring / review objectives; 3.4.3(g) audit, review and monitoring | Diagnostic settings export, workspace location |
| Exit and repatriation package | Data return, deletion, manifest export, image escrow, restore drill | CSF 3.4.1 vendor exit clauses; 3.4.3(h) exit | Exit runbook, backup/restore report, deletion attestation |
| Material outsourcing approval | Formal SAMA approval before production use | CSF 3.4.2 outsourcing; 3.4.3(a)(2) cloud approval | Approval ID, risk assessment, committee minutes |

## Regulator references

${country.regulatory.regulator_links}

## Stretch goals

- Add Gatekeeper constraints that deny privileged pods, hostPath mounts, and
  public `LoadBalancer` services for the `payments` namespace.
- Require private endpoints for Key Vault, ACR, Storage, and monitoring before the
  cluster is marked production-ready.
- Run a quarterly repatriation exercise to a second bank-controlled AKS or Azure
  Local target and record the evidence pack for SAMA review.
- Extend the design with token vaulting and PCI DSS evidence if your payment flow
  stores or processes PAN data directly.
