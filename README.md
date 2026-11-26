# Open Innovation AI — Runbook

RKE2 on AWS, built with Terraform (HCP) + Ansible, apps shipped with GitHub Actions + Argo CD.

```
                     internet
                        │
        https *.kst-devops.com  +  api.kst-devops.com:6443
                        │
                ┌───────▼────────┐        ┌──────────────┐
                │ nginx (public) │        │ jump (public)│── SSH to everything
                └───────┬────────┘        └──────────────┘
   rancher ──▶ ingress-nginx :80
   argocd, oia ──▶ istio gateway :30080
   api :6443, join :9345 ──▶ masters
                        │
     ┌──────────────────▼───────────────────┐
     │ RKE2 (private subnets)               │
     │ master-1 / master-2 / master-3 (HA)  │
     │ worker-1                             │
     └──────────────────────────────────────┘
```

| Folder | What |
|---|---|
| `network/` `security/` `compute/` | Terraform, one HCP workspace each |
| `ansible/` | nginx + Let's Encrypt, RKE2, Argo CD |
| `app/` | Python backend + frontend |
| `gitops/` | what Argo CD deploys (dev / qa / prod) |
| `.github/workflows/ci.yml` | CI/CD pipeline |
| `platform/` | Istio, Prometheus, Kiali, Jaeger (manual install) |
| `platform/demo/` | HPA / PDB / traffic demos |

---

## Step 1 — Infrastructure (HCP Terraform)

Workspaces in org `kst-cie`, all on branch `open-innovation-ai`. Apply **in this order**:

1. **network** → VPC, subnets, NAT gateway, Route53 zone `kst-devops.com`
2. **security** → security groups + IAM role for nginx (certbot)
3. **compute** → 6 servers, SSH key, DNS records (`rancher`, `api`, `argocd`, `oia`)

Notes:
- Each workspace reads the outputs of the one before, so the order matters.
- `security` is excluded from the policy set `hce-policy` (the jump host allows SSH from `0.0.0.0/0`).
- The `runner` workspace is disabled.

## Step 2 — DNS (once)

Copy the 4 `name_servers` from the **network** outputs into Namecheap → kst-devops.com → Nameservers → **Custom DNS**.

```bash
dig +short NS kst-devops.com        # should show awsdns-...
dig +short api.kst-devops.com       # should show the nginx public IP
```

## Step 3 — SSH key

HCP → compute → States → download the latest state, then:

```bash
jq -r '.outputs.private_key.value' state.json > ~/.ssh/open-innovation-ai.pem
chmod 400 ~/.ssh/open-innovation-ai.pem
rm state.json
```

Server IPs are in the compute **Outputs** (`public_ips`, `private_ips`).

## Step 4 — Ansible: nginx + RKE2

If servers were recreated, update the IPs in `ansible/inventory/hosts.ini`
(and the jump / nginx IPs in `group_vars/all.yml` and `group_vars/k8s_cluster.yml`).

```bash
cd ansible
ansible-galaxy install -r requirements.yml
ansible all -m ping                          # 6 x pong

export RKE2_TOKEN=$(openssl rand -hex 32)    # first install only. SAVE IT. UPPERCASE name.
ansible-playbook site.yml
```

`site.yml` does:
1. nginx: certbot gets a wildcard cert `*.kst-devops.com` (DNS challenge in Route53), nginx config
2. RKE2: 3 masters (HA) + 1 worker, API name `api.kst-devops.com`

Re-running later? Use the **same** token:

```bash
export RKE2_TOKEN=$(ansible rke2-master-1 -b -m shell -a "cat /var/lib/rancher/rke2/server/token" | tail -1)
```

## Step 5 — kubectl

`site.yml` saves `ansible/kubeconfig.yaml`. Add it to your kube config as context `open-innovation-ai`:

```bash
sed -e 's/: default$/: open-innovation-ai/' -e 's/^- name: default$/- name: open-innovation-ai/' \
    kubeconfig.yaml > /tmp/oia.yaml
KUBECONFIG=~/.kube/config:/tmp/oia.yaml kubectl config view --flatten > /tmp/merged.yaml
mv /tmp/merged.yaml ~/.kube/config && rm /tmp/oia.yaml

kubectl config set-cluster open-innovation-ai --server=https://api.kst-devops.com:6443
kubectl config use-context open-innovation-ai
kubectl get nodes                            # 4 x Ready
```

## Step 6 — Argo CD

```bash
cd ansible && ansible-playbook argocd.yml
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

Creates 3 apps: `oia-dev`, `oia-qa`, `oia-prod` (watch `gitops/envs/<env>` on `main`).
UI: https://argocd.kst-devops.com (after Step 8), user `admin`.

## Step 7 — CI/CD

```
PR    ──▶ gitleaks · pytest · docker build · trivy                    (nothing pushed)
main  ──▶ same + push ghcr.io · cosign sign · SBOM
      ──▶ digest -> gitops/envs/dev ──▶ qa ──▶ ⏸ approval ──▶ prod      (Argo CD syncs each)
```

One-time setup in GitHub:
1. Settings → Environments → create `qa` and `prod`. On `prod` add yourself as **Required reviewer**.
2. After the first run on `main`: Packages → `oia-backend`, `oia-frontend` → make **public**.

Then: open a PR → checks run → merge → watch Actions → approve `prod`.

Key points:
- Images are **distroless** (`gcr.io/distroless/python3-debian13:nonroot`): no shell, non-root.
- Deploy by **digest** (`@sha256:...`), so dev, qa and prod run byte-for-byte the same image.
- CI never touches the cluster. It commits to git, Argo CD pulls.

Verify a signature:

```bash
cosign verify ghcr.io/rosaliei/oia-backend@sha256:<digest> \
  --certificate-identity-regexp 'github.com/rosaliei' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Step 8 — Istio, Prometheus, Kiali, Jaeger

Follow [platform/README.md](platform/README.md). Short version:

```bash
cd platform
istioctl install -f istio/istio.yaml -y                 # demo profile, gateway NodePort 30080
kubectl apply -f istio/mtls-strict.yaml
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/values.yaml
kubectl apply -f monitoring/istio-monitoring.yaml
kubectl apply -f istio/gateway.yaml                     # oia + argocd hosts
```

## Step 9 — Demos

Follow [platform/demo/README.md](platform/demo/README.md):

```bash
cd platform/demo
kubectl apply -f hpa-pdb.yaml
./load.sh hpa      # HPA scales 2 -> 6
./load.sh app      # traffic to oia.kst-devops.com -> see it in Kiali
./load.sh stop
```

---

## URLs

| URL | Goes to |
|---|---|
| https://oia.kst-devops.com | app (oia-dev) via Istio gateway |
| https://argocd.kst-devops.com | Argo CD via Istio gateway |
| https://rancher.kst-devops.com | ingress-nginx (for Rancher later) |
| https://api.kst-devops.com:6443 | Kubernetes API (kubectl) |

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| security/compute: `Unsupported attribute "vpc_id"` | network not applied yet (or HCP running old code) | push, apply network first |
| `Provider configuration not present` | old resources in state use a provider that was removed | add the provider back for one apply, then remove it |
| security run blocked by `deny-public-ssh` | OPA policy | security workspace is excluded in `hce-policy` |
| `ansible-playbook site.yml` hangs | `RKE2_TOKEN` empty / lowercase → nodes get `token: ""` | export the real token (Step 4), re-run, then `systemctl restart rke2-agent` on the worker |
| `kubectl` TLS handshake timeout | old SSH tunnel stuck | use `api.kst-devops.com:6443` (Step 5) |
| CI: Trivy fails | base image has fixed HIGH/CRITICAL CVEs | rebuild; use a maintained base (distroless **debian13**, not debian12) |
| pods stuck `Init` with Istio | `runAsNonRoot` at pod level blocks `istio-init` | keep it on the container only (already done) |
| pods `Pending` | 4 GB nodes are full | worker → `t3.large` in `compute/terraform.tfvars` |

## Tear down

1. HCP: destroy **compute → security → network** (reverse order).
2. Namecheap: set nameservers back to Namecheap BasicDNS if you still need the domain elsewhere.

## Not production-ready (on purpose, interview demo)

- One nginx = single point of failure → AWS NLB or 2 nginx.
- SSH (22) and API (6443) open to `0.0.0.0/0` → restrict to your IP.
- nginx has no Elastic IP → public IP changes on stop/start.
- `RKE2_TOKEN` lives in your shell → `ansible-vault` or a secret manager.

---

HCP Terraform + AWS OIDC + Jira/Slack change workflow: [docs/hcp-oidc-workflow.md](docs/hcp-oidc-workflow.md)
