# CI/CD + GitOps flow

```
PR ──▶ CI: gitleaks · test · build · trivy           (nothing pushed)
 │
merge to main
 │
 ▼
CI: build · trivy · push to ghcr.io · cosign sign · SBOM (syft) attached with cosign
 │
 ▼
commit image digest ──▶ gitops/envs/dev   ──▶ Argo CD syncs oia-dev
 │
 ▼
copy digest         ──▶ gitops/envs/qa    ──▶ Argo CD syncs oia-qa
 │
 ▼   ⏸  approval (GitHub environment "prod", required reviewer)
copy digest         ──▶ gitops/envs/prod  ──▶ Argo CD syncs oia-prod
```

## Where things are

| Path | What |
|---|---|
| `app/backend` | Flask API: `/api/hello`, `/healthz` + pytest |
| `app/frontend` | Flask page that calls the backend + pytest |
| `.github/workflows/ci.yml` | the whole pipeline |
| `gitops/base` | Deployment + Service for backend and frontend |
| `gitops/envs/{dev,qa,prod}` | namespace + image **digest** per environment (CI writes it) |
| `gitops/argocd/apps.yaml` | 3 Argo CD apps, one per environment |
| `ansible/argocd.yml` | installs Argo CD and the 3 apps on the RKE2 cluster |

## Why each step

- **Gitleaks**: stop secrets (keys, tokens) from getting into the repo.
- **Tests**: pytest for both apps.
- **Distroless image**: multi-stage build. Dependencies are installed in `python:3.11-slim`, then only the app + its packages
  are copied into `gcr.io/distroless/python3-debian12:nonroot`. No shell, no apt, no pip, non-root user:
  fewer packages = fewer CVEs for Trivy to find and less for an attacker to use.
- **Trivy**: scan the image, fail on HIGH/CRITICAL CVEs that have a fix.
- **Digest, not tag**: `image@sha256:...` can never change; a tag like `latest` can. What was tested in dev is byte-for-byte what goes to prod.
- **Cosign (keyless)**: signs the image with GitHub's OIDC identity. No signing keys to store.
  Verify: `cosign verify ghcr.io/rosaliei/oia-backend@sha256:... --certificate-identity-regexp 'github.com/rosaliei' --certificate-oidc-issuer https://token.actions.githubusercontent.com`
- **SBOM**: list of every package inside the image (syft, SPDX), attached to the image with cosign and kept as a build artifact.
- **GitOps**: the cluster is never changed by CI directly. CI only commits to git; Argo CD pulls from git. Git history = deploy history, rollback = `git revert`.
- **Promotion = copy the digest** from one env file to the next. Same image moves dev → qa → prod.
- **Approval gate**: the `promote-prod` job uses the GitHub environment `prod` with a required reviewer, so it waits until someone clicks *Approve*.

## Same repo: app code + GitOps

Fine for a small project. The usual problem is CI committing to the repo and triggering itself again in a loop.
That does not happen here: commits pushed with `GITHUB_TOKEN` do not start new workflow runs,
and CI only runs on changes under `app/`.
Bigger teams often split the GitOps repo so app developers cannot change prod manifests.

## One-time setup

1. GitHub → Settings → Environments → create `qa` and `prod`. On `prod` add yourself under *Required reviewers*.
2. Merge to `main` (the Argo CD apps watch `main`).
3. After the first run: GitHub → Packages → `oia-backend` and `oia-frontend` → make them **public**,
   so the cluster can pull them without a password.
4. `cd ansible && ansible-playbook argocd.yml`

Argo CD UI (through the kubectl tunnel):

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
# open https://localhost:8080  user: admin
```

See the app:

```bash
kubectl -n oia-dev port-forward svc/frontend 8081:80   # open http://localhost:8081
```
