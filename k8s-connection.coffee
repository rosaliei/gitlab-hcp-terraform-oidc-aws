# terminal 1: keep this open
ssh -i ~/.ssh/open-innovation-ai.pem \
  -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/open-innovation-ai.pem ubuntu@47.129.101.131" \
  -L 6443:127.0.0.1:6443 ubuntu@10.0.1.203

# terminal 2
kubectl config use-context open-innovation-ai
kubectl get nodes