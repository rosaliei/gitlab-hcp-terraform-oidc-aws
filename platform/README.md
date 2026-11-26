# Platform: Istio (demo) + Prometheus + Kiali + Jaeger (install by hand)

Run everything from your Mac with the kubectl tunnel open and the right context:

```bash
kubectl config use-context open-innovation-ai
cd platform
```

Order: **Istio → sidecars → Prometheus → Kiali + Jaeger → gateway → traffic**

```
              istio-ingressgateway ──▶ frontend ──▶ backend      (mTLS between sidecars)
                       │                   │            │
      every sidecar ──▶ metrics ──▶ Prometheus ──▶ Kiali (graph), Grafana (dashboards)
                      ──▶ traces  ──▶ Jaeger
```

---

## 1. Istio (profile: demo)

Download Istio. You get `istioctl` **and** the `samples/` folder (Jaeger is used from there):

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*/ && export PATH=$PWD/bin:$PATH && export ISTIO_HOME=$PWD && cd -

istioctl x precheck                     # cluster ready for Istio?
istioctl install -f istio/istio.yaml -y # istiod + ingress gateway + egress gateway

kubectl -n istio-system get pods,svc    # istiod, istio-ingressgateway, istio-egressgateway
istioctl version
```

`istio/istio.yaml`: profile `demo` (everything on, 100% tracing, access logs),
ingress gateway as `NodePort` (no cloud LoadBalancer on RKE2).

## 2. Sidecars for the app

The Argo CD apps label `oia-dev`, `oia-qa`, `oia-prod` with `istio-injection=enabled`
(`gitops/argocd/apps.yaml`). If the namespaces existed before, label them by hand:

```bash
for ns in oia-dev oia-qa oia-prod; do kubectl label ns $ns istio-injection=enabled --overwrite; done
for ns in oia-dev oia-qa oia-prod; do kubectl -n $ns rollout restart deploy; done   # sidecars only go into NEW pods

kubectl -n oia-dev get pods             # READY 2/2 = app + istio-proxy
istioctl analyze -A                     # checks mesh config for problems
```

Strict mTLS (pods in the app namespaces only accept encrypted traffic from other sidecars):

```bash
kubectl apply -f istio/mtls-strict.yaml
```

## 3. Prometheus + Grafana (kube-prometheus-stack)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/values.yaml --wait

kubectl apply -f monitoring/istio-monitoring.yaml   # scrape istiod + every sidecar
```

## 4. Kiali (mesh graph) + Jaeger (tracing)

```bash
# Jaeger: the demo profile already sends traces to it (service "zipkin" in istio-system)
kubectl apply -f $ISTIO_HOME/samples/addons/jaeger.yaml

# Kiali: reads metrics from our Prometheus
helm repo add kiali https://kiali.org/helm-charts
helm repo update
helm install kiali-server kiali/kiali-server -n istio-system \
  --set auth.strategy=anonymous \
  --set external_services.prometheus.url=http://monitoring-kube-prometheus-prometheus.monitoring:9090 \
  --set external_services.tracing.enabled=true \
  --set external_services.tracing.internal_url=http://tracing.istio-system:16685/jaeger \
  --set external_services.tracing.use_grpc=true
```

## 5. Public URLs (nginx -> Istio gateway)

```
https://oia.kst-devops.com      nginx (TLS) -> istio-ingressgateway :30080 -> frontend (oia-dev)
https://argocd.kst-devops.com   nginx (TLS) -> istio-ingressgateway :30080 -> argocd-server
https://api.kst-devops.com:6443 nginx (TCP passthrough)                    -> Kubernetes API on the masters
```

Roll it out in this order:

```bash
# a) push, then apply in HCP: security (6443 public, 30080 nginx->nodes), compute (DNS records)

# b) nginx: wildcard cert *.kst-devops.com + new routing; RKE2: api.kst-devops.com in the API cert
cd ansible && ansible-playbook site.yml && cd -

# c) Istio gateway with fixed NodePort 30080 (re-run is fine, it updates the install)
istioctl install -f istio/istio.yaml -y
kubectl -n istio-system get svc istio-ingressgateway      # 80:30080/TCP

# d) Argo CD in http mode (nginx does TLS)
cd ansible && ansible-playbook argocd.yml && cd -

# e) host routing
kubectl apply -f istio/gateway.yaml
```

Test:

```bash
curl -s https://oia.kst-devops.com                 # <h1>Open Innovation AI</h1>...
curl -sI https://argocd.kst-devops.com | head -1   # HTTP/2 200
dig +short api.kst-devops.com                      # nginx public IP

# kubectl without the tunnel: copy the context, point it at api.kst-devops.com
kubectl config set-cluster open-innovation-ai --server=https://api.kst-devops.com:6443
kubectl get nodes
```

Argo CD CLI through nginx needs gRPC-web: `argocd login argocd.kst-devops.com --grpc-web`

## 6. Open the UIs (port-forward, one terminal each)

| UI | Command | URL |
|---|---|---|
| Kiali | `istioctl dashboard kiali` | opens browser |
| Jaeger | `istioctl dashboard jaeger` | opens browser |
| Prometheus | `kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090` | http://localhost:9090 |
| Grafana | `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80` | http://localhost:3000 (admin) |

Grafana password:

```bash
kubectl -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

What to show:

- **Kiali → Traffic Graph → namespace oia-dev**: gateway → frontend → backend, lock icons = mTLS.
- **Jaeger → service frontend.oia-dev**: one trace per request through gateway, frontend, backend.
- **Prometheus**:
  ```
  sum(rate(istio_requests_total[1m])) by (destination_service_name)
  sum(rate(istio_requests_total{response_code=~"5.."}[5m])) by (destination_service_name)
  ```

---

## Remove

```bash
kubectl delete -f istio/gateway.yaml
helm uninstall kiali-server -n istio-system
kubectl delete -f $ISTIO_HOME/samples/addons/jaeger.yaml
kubectl delete -f monitoring/istio-monitoring.yaml
helm uninstall monitoring -n monitoring
kubectl delete -f istio/mtls-strict.yaml
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```
