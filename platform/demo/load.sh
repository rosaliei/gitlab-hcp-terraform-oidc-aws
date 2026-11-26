#!/usr/bin/env bash
# Generate load for the demos.
#   ./load.sh hpa     -> hammer php-apache from inside the cluster (HPA demo)
#   ./load.sh app     -> 300 requests to https://oia.kst-devops.com (Istio / Kiali demo)
#   ./load.sh stop    -> stop the HPA load
set -e

case "$1" in
  hpa)
    kubectl -n default run load-generator --image=busybox:1.36 --restart=Never -- \
      /bin/sh -c "while true; do wget -q -O- http://php-apache >/dev/null; done"
    echo "load started. watch: kubectl -n default get hpa php-apache -w"
    ;;
  app)
    for i in $(seq 1 300); do
      curl -s -o /dev/null -w "%{http_code} " https://oia.kst-devops.com
      sleep 0.2
    done
    echo
    ;;
  stop)
    kubectl -n default delete pod load-generator
    ;;
  *)
    echo "usage: $0 hpa | app | stop"
    exit 1
    ;;
esac
