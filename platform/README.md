# Platform: Istio + Prometheus (install by hand)

Run these from your Mac with the kubectl tunnel open and the right context:

```bash
kubectl config use-context open-innovation-ai
cd platform
```

Install **Istio first**, then **Prometheus**, then `istio-monitoring.yaml` (it needs both).

---

## 1. Istio (service mesh, sidecar mode) with istioctl

```bash
brew install istioctl                   # or: curl -L https://istio.io/downloadIstio | sh -

istioctl x precheck                     # checks the cluster is ready for Istio
istioctl install -f istio/istio.yaml -y # installs istiod (profile: minimal)

kubectl -n istio-system get pods        # istiod should be Running
istioctl version                        # client and control plane versions
```

`istio/istio.yaml` is the whole config: profile `minimal` (only istiod, no ingress gateway,
because traffic already comes in through nginx + ingress-nginx), access logs on, small resource requests.

### Add sidecars to the app

The Argo CD apps already label `oia-dev`, `oia-qa`, `oia-prod` with `istio-injection=enabled`
(`gitops/argocd/apps.yaml`). If they were created before that, label them by hand:

```bash
for ns in oia-dev oia-qa oia-prod; do kubectl label ns $ns istio-injection=enabled --overwrite; done
```

Sidecars are only added to **new** pods, so restart them:

```bash
for ns in oia-dev oia-qa oia-prod; do kubectl -n $ns rollout restart deploy; done
kubectl -n oia-dev get pods              # READY 2/2 = app + istio-proxy
istioctl analyze -A                      # checks the mesh config for problems
```

### mTLS strict (optional, good to show)

```bash
kubectl apply -f istio/mtls-strict.yaml
```

Now pods in those namespaces only accept encrypted, authenticated (mTLS) traffic from other sidecars.

---

## 2. Prometheus + Grafana (kube-prometheus-stack)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/values.yaml --wait

kubectl -n monitoring get pods
```

### Scrape Istio

```bash
kubectl apply -f monitoring/istio-monitoring.yaml
```

### Open the UIs

```bash
# Prometheus  -> http://localhost:9090  (Status -> Targets: istiod + envoy-sidecars should be UP)
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090

# Grafana     -> http://localhost:3000  user: admin
kubectl -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

Useful queries in Prometheus:

```
# requests per second per service (from the sidecars)
sum(rate(istio_requests_total[1m])) by (destination_service_name)

# 5xx errors
sum(rate(istio_requests_total{response_code=~"5.."}[5m])) by (destination_service_name)
```

Make some traffic first:

```bash
kubectl -n oia-dev port-forward svc/frontend 8081:80
for i in $(seq 1 50); do curl -s localhost:8081 >/dev/null; done
```

---

## Remove

```bash
kubectl delete -f monitoring/istio-monitoring.yaml
helm uninstall monitoring -n monitoring
kubectl delete -f istio/mtls-strict.yaml
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```
