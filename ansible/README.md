# Ansible: install RKE2 on the Terraform servers

Terraform creates the servers. Ansible installs the software on them.

```
ansible/
├── ansible.cfg                  # default settings (which inventory, where roles go)
├── requirements.yml             # role + collections to download
├── inventory/
│   ├── hosts.ini                # the servers and their IPs
│   └── group_vars/
│       ├── all.yml              # ssh user, key, go through jump host
│       ├── jump.yml             # jump host: connect directly
│       ├── nginx.yml            # domain for the Let's Encrypt certificate
│       └── k8s_cluster.yml      # RKE2 settings (lablabs.rke2 role)
├── templates/nginx.conf.j2      # nginx = TCP load balancer in front of RKE2
└── site.yml                     # the playbook: nginx first, then RKE2
```

## Inventory

[inventory/hosts.ini](inventory/hosts.ini) lists every server and its IP (from the compute
workspace outputs). If Terraform recreates a server, update its IP there
(and in `group_vars/all.yml` / `group_vars/k8s_cluster.yml` if it is the jump host or nginx).

| Group         | Servers                        | Used by                       |
|---------------|--------------------------------|-------------------------------|
| `jump`        | hellocloud-jump                | SSH proxy for everything else |
| `nginx`       | nginx-lb                       | load balancer play            |
| `masters`     | rke2-master-1/2/3              | lablabs.rke2 → RKE2 server    |
| `workers`     | rke2-worker-1                  | lablabs.rke2 → RKE2 agent     |
| `k8s_cluster` | masters + workers              | lablabs.rke2 runs on this     |

Ansible connects to the jump host on its public IP. All other servers are private,
so `group_vars/all.yml` sends SSH through the jump host (`ProxyCommand`).

## How the cluster is wired

```
internet ──https──▶ nginx (TLS, Let's Encrypt) ──http:80──▶ ingress-nginx on every node
                       │
 rke2 nodes ──6443/9345──▶ nginx ──6443/9345──▶ master-1/2/3
```

`rke2_api_ip` is nginx's private IP. That is why nginx is set up first:
master-2 and master-3 join the cluster through it.

## HTTPS (Let's Encrypt)

- DNS for kst-devops.com is in Route53 (network workspace). `rancher.kst-devops.com` points to nginx (compute workspace).
- nginx has an IAM role that may only edit that Route53 zone (security workspace).
- `certbot --dns-route53` on nginx adds the `_acme-challenge` TXT record, Let's Encrypt checks it, certbot deletes it.
- `certbot.timer` renews the certificate automatically and reloads nginx. Nothing to do by hand.

Check renewal works: `ansible nginx -b -m shell -a "certbot renew --dry-run"`

## Run it

```bash
cd ansible

# 1. Download the role (once)
ansible-galaxy install -r requirements.yml

# 2. Check SSH to every server
ansible all -m ping

# 3. Secret token the nodes share. SAVE IT. Re-runs need the same value.
export RKE2_TOKEN=$(openssl rand -hex 32)
echo "$RKE2_TOKEN"

# 4. Install nginx + RKE2
ansible-playbook site.yml
```

When it finishes, `kubeconfig.yaml` is in this folder (gitignored).

## Use kubectl from your Mac

The API (6443) is not open to the internet. Open a tunnel through the jump host:

```bash
# terminal 1: keep this open
ssh -i ~/.ssh/open-innovation-ai.pem -L 6443:10.0.1.203:6443 ubuntu@47.129.101.131

# terminal 2
sed -i '' 's#server: https://.*:6443#server: https://127.0.0.1:6443#' kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get nodes
```

## Useful commands

```bash
ansible masters -m shell -a "systemctl status rke2-server --no-pager" -b   # run a command on a group
ansible-playbook site.yml --limit nginx                                     # only the nginx part
ansible-playbook site.yml --check                                           # dry run
```
