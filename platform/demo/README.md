# Demos: what to run and what you should see

Kube context `open-innovation-ai` with the tunnel open (or `api.kst-devops.com`, see `platform/README.md`).

## 1. HPA (autoscaling)

```bash
kubectl apply -f hpa-pdb.yaml
kubectl -n default get hpa php-apache          # TARGETS cpu: 0%/50%, REPLICAS 2

./load.sh hpa                                  # start load
kubectl -n default get hpa php-apache -w       # watch
```

Expect:
- after ~30-60s CPU goes above 50% (e.g. `cpu: 130%/50%`)
- REPLICAS goes 2 -> up to 6
- CPU per pod drops back near 50% because load is spread over more pods

```bash
./load.sh stop
kubectl -n default get hpa php-apache -w       # after ~5 min REPLICAS back to 2 (scale-down delay)
```

## 2. PDB (pod disruption budget)

```bash
kubectl -n default get pdb php-apache          # MIN AVAILABLE 1, ALLOWED DISRUPTIONS = pods - 1
kubectl -n default get pods -l app=php-apache -o wide     # which node each pod is on

# pretend to drain a node that has a php-apache pod (nothing really happens with --dry-run=server)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --dry-run=server
```

Expect: the drain is allowed while ALLOWED DISRUPTIONS > 0.
Scale to 1 pod and try again -> ALLOWED DISRUPTIONS 0 -> the eviction is refused:

```bash
kubectl -n default delete hpa php-apache
kubectl -n default scale deploy php-apache --replicas=1
kubectl -n default get pdb php-apache          # ALLOWED DISRUPTIONS 0
kubectl drain <node-with-the-pod> --ignore-daemonsets --delete-emptydir-data --dry-run=server
# -> "Cannot evict pod as it would violate the pod's disruption budget"
```

## 3. App through Istio (oia.kst-devops.com)

```bash
curl -s https://oia.kst-devops.com              # <h1>Open Innovation AI</h1><p>Hello from backend</p>
./load.sh app                                   # 300 requests, prints status codes (expect 200s)
```

Then:
- **Kiali** (`istioctl dashboard kiali`) -> Traffic Graph -> namespace `oia-dev`:
  istio-ingressgateway -> frontend -> backend, lock icons = mTLS
- **Jaeger** (`istioctl dashboard jaeger`) -> service `frontend.oia-dev` -> traces with 3 hops
- **Prometheus**: `sum(rate(istio_requests_total{destination_service_namespace="oia-dev"}[1m])) by (destination_service_name)`

## Clean up

```bash
./load.sh stop
kubectl delete -f hpa-pdb.yaml
```
