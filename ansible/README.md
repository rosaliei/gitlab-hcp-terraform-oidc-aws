# Ansible: install RKE2 on the Terraform servers

Terraform creates the servers. Ansible installs the software on them.

```
ansible/
├── ansible.cfg                  # default settings (which inventory, where roles go)
├── requirements.yml             # role + collections to download
├── inventory/
│   ├── aws_ec2.yml              # DYNAMIC inventory: asks AWS for the server list
│   └── group_vars/
│       ├── all.yml              # ssh user, key, go through jump host
│       ├── jump.yml             # jump host: connect directly
│       └── k8s_cluster.yml      # RKE2 settings (lablabs.rke2 role)
├── templates/nginx.conf.j2      # nginx = TCP load balancer in front of RKE2
└── site.yml                     # the playbook: nginx first, then RKE2
```

## How the dynamic inventory works

Terraform puts a `Role` tag on every server (`jump`, `nginx`, `rke2-master`, `rke2-worker`).
`inventory/aws_ec2.yml` asks AWS for running servers with that tag and makes groups from it:

| Group         | Servers                        | Used by                       |
|---------------|--------------------------------|-------------------------------|
| `jump`        | hellocloud-jump                | SSH proxy for everything else |
| `nginx`       | nginx                          | load balancer play            |
| `masters`     | rke2-master-1/2/3              | lablabs.rke2 → RKE2 server    |
| `workers`     | rke2-worker-1                  | lablabs.rke2 → RKE2 agent     |
| `k8s_cluster` | masters + workers              | lablabs.rke2 runs on this     |

No IPs are written anywhere. If Terraform recreates a server, the next ansible run picks up the new IP.

Ansible connects to the jump host on its public IP. All other servers are private,
so `group_vars/all.yml` sends SSH through the jump host (`ProxyCommand`).

## How the cluster is wired

```
internet ──80/443──▶ nginx ──80/443──▶ ingress-nginx on every node
                       │
 rke2 nodes ──6443/9345──▶ nginx ──6443/9345──▶ master-1/2/3
```

`rke2_api_ip` is nginx's private IP. That is why nginx is set up first:
master-2 and master-3 join the cluster through it.

## Run it

```bash
cd ansible

# 1. AWS login (the inventory reads EC2 with your AWS credentials)
aws login --profile <your-profile>
eval "$(aws configure export-credentials --profile <your-profile> --format env)"

# 2. Download the role (once)
ansible-galaxy install -r requirements.yml

# 3. Check the inventory: you should see the 4 groups and 6 servers
ansible-inventory --graph

# 4. Check SSH to every server
ansible all -m ping

# 5. Secret token the nodes share. SAVE IT. Re-runs need the same value.
export RKE2_TOKEN=$(openssl rand -hex 32)
echo "$RKE2_TOKEN"

# 6. Install nginx + RKE2
ansible-playbook site.yml
```

When it finishes, `kubeconfig.yaml` is in this folder (gitignored).

## Use kubectl from your Mac

The API (6443) is not open to the internet. Open a tunnel through the jump host:

```bash
# terminal 1: keep this open
ssh -i ~/.ssh/open-innovation-ai.pem -L 6443:<nginx-private-ip>:6443 ubuntu@<jump-public-ip>

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
