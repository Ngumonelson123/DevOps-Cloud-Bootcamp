# Orchestrating Containers Across Multiple Virtual Servers with Kubernetes 1-101

A complete, manual, from-scratch Kubernetes cluster on AWS EC2 — no kubeadm, no managed service.

---

## Cluster Details

| Component         | Value                                                                 |
|-------------------|-----------------------------------------------------------------------|
| Kubernetes        | v1.21.0                                                               |
| etcd              | v3.4.15                                                               |
| containerd        | v1.4.4                                                                |
| OS                | Ubuntu 20.04 (Focal)                                                  |
| Masters           | 3 × t3.small (172.31.0.10–12)                                        |
| Workers           | 3 × t3.small (172.31.0.20–22)                                        |
| Region            | us-east-1                                                             |
| NLB DNS           | k8s-cluster-from-ground-up-b214173e4e23275c.elb.us-east-1.amazonaws.com |

---

## Project Structure

```
Orchestrating-containers-K8s-1-101/
│
├── env.sh                          # Source this first — project-wide env vars
├── run-all.sh                      # SSH helpers: ssh_master, run_on_all_masters, etc.
│
├── ssh/
│   └── k8s-cluster-from-ground-up.id_rsa   # SSH key (auto-generated in Step 2)
│
├── configs/
│   ├── network-ids.sh              # Auto-generated: VPC/subnet/SG/NLB IDs
│   ├── certificates/               # All .pem files (CA, API server, kubelet…)
│   └── kubeconfigs/                # All .kubeconfig files
│
└── scripts/
    ├── 01-network/
    │   └── 01-network.sh           # VPC, Subnet, IGW, Route Table, SG, NLB
    ├── 02-compute/
    │   └── 02-compute.sh           # 3 Master + 3 Worker EC2 instances
    ├── 03-certificates/
    │   ├── 03-certificates.sh      # Generate all TLS certs with cfssl
    │   └── 03b-distribute-certs.sh # SCP certs to nodes
    ├── 04-kubeconfigs/
    │   ├── 04-kubeconfigs.sh       # Generate kubeconfig files
    │   └── 04b-distribute-kubeconfigs.sh
    ├── 05-encryption/
    │   └── 05-encryption.sh        # etcd at-rest encryption config + distribute
    ├── 06-etcd/
    │   └── 06-etcd-on-master.sh    # Bootstrap etcd (runs on each master)
    ├── 07-control-plane/
    │   ├── 07-control-plane-on-master.sh  # Bootstrap control plane (runs on each master)
    │   └── 07b-rbac.sh             # RBAC for kubelet — run from local machine
    └── 08-worker-nodes/
        └── 08-worker-on-node.sh    # Bootstrap workers (runs on each worker)
```

---

## Prerequisites

Install these tools on your local machine before starting:

```bash
# AWS CLI v2
aws --version

# kubectl v1.21+
kubectl version --client

# cfssl + cfssljson v1.6.4
wget -q https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64
wget -q https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64
chmod +x cfssl_1.6.4_linux_amd64 cfssljson_1.6.4_linux_amd64
sudo mv cfssl_1.6.4_linux_amd64 /usr/local/bin/cfssl
sudo mv cfssljson_1.6.4_linux_amd64 /usr/local/bin/cfssljson

# jq
sudo apt-get install -y jq
```

Configure your AWS profile:

```bash
export AWS_PROFILE=kubestronaut
export AWS_REGION=us-east-1
aws sts get-caller-identity   # confirm auth works
```

---

## Execution Order

```bash
# 0. Load environment
source env.sh

# 1. Network Infrastructure (VPC, Subnet, IGW, SG, NLB)
bash scripts/01-network/01-network.sh

# 2. EC2 Instances (3 masters + 3 workers)
bash scripts/02-compute/02-compute.sh

# 3. TLS Certificates
bash scripts/03-certificates/03-certificates.sh
bash scripts/03-certificates/03b-distribute-certs.sh

# 4. Kubeconfig Files
bash scripts/04-kubeconfigs/04-kubeconfigs.sh
bash scripts/04-kubeconfigs/04b-distribute-kubeconfigs.sh

# 5. etcd Encryption (also distributes NLB address to masters)
bash scripts/05-encryption/05-encryption.sh

# 6. Bootstrap etcd on all masters
source run-all.sh
run_on_all_masters scripts/06-etcd/06-etcd-on-master.sh

# 7. Bootstrap Control Plane on all masters
run_on_all_masters scripts/07-control-plane/07-control-plane-on-master.sh

# 7b. Configure RBAC (run from local machine)
bash scripts/07-control-plane/07b-rbac.sh

# 8. Bootstrap Worker Nodes
run_on_all_workers scripts/08-worker-nodes/08-worker-on-node.sh
```

---

## Verify the Cluster

```bash
kubectl get nodes --kubeconfig configs/kubeconfigs/admin.kubeconfig
# Expected: all 3 workers show STATUS: Ready

kubectl get componentstatuses --kubeconfig configs/kubeconfigs/admin.kubeconfig
# Expected: scheduler, controller-manager, etcd-0/1/2 all Healthy

kubectl cluster-info --kubeconfig configs/kubeconfigs/admin.kubeconfig
```

Set kubeconfig for convenience:

```bash
export KUBECONFIG=configs/kubeconfigs/admin.kubeconfig
kubectl get nodes
```

---

## Architecture

```
                    ┌─────────────────────────────┐
                    │   Network Load Balancer       │
                    │   (port 6443)                 │
                    └──────────┬──────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │ master-0 │    │ master-1 │    │ master-2 │
        │172.31.0.10│   │172.31.0.11│   │172.31.0.12│
        │ etcd     │    │ etcd     │    │ etcd     │
        │ api-svr  │    │ api-svr  │    │ api-svr  │
        │ ctrl-mgr │    │ ctrl-mgr │    │ ctrl-mgr │
        │ scheduler│    │ scheduler│    │ scheduler│
        └──────────┘    └──────────┘    └──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │ worker-0 │    │ worker-1 │    │ worker-2 │
        │172.31.0.20│   │172.31.0.21│   │172.31.0.22│
        │ kubelet  │    │ kubelet  │    │ kubelet  │
        │kube-proxy│    │kube-proxy│    │kube-proxy│
        │containerd│    │containerd│    │containerd│
        └──────────┘    └──────────┘    └──────────┘
```

---

## Known Issues & Fixes Applied

**1. `env.sh` source path was wrong in all scripts**
Scripts are two levels deep (`scripts/XX-name/`), so `env.sh` at the project root
requires `../../env.sh`, not `../env.sh`. Fixed in all scripts.

**2. `env.sh` was overwriting network IDs with empty strings**
Removed blank variable exports from `env.sh` so `configs/network-ids.sh` values
are not clobbered when sourced after it.

**3. Hardcoded fake API server address in step 7**
`07-control-plane-on-master.sh` had `k8s-api-server.svc.steghub.com` hardcoded.
Fixed: `05-encryption.sh` now also writes `~/kubernetes-public-address.txt` (the
real NLB DNS) to each master, and step 7 reads it from there.

**4. Ubuntu 16.04 (Xenial) is EOL**
Updated `02-compute.sh` to use Ubuntu 20.04 (Focal).

**5. Instance type restricted to free-tier**
`t3.medium` is not free-tier eligible on this account. Changed to `t3.small`
for both masters and workers.

**6. SSH "Too many authentication failures"**
Added `-o IdentitiesOnly=yes` to all `scp` and `ssh` calls in distribute scripts
and `run-all.sh` to force use of only the cluster key.

**7. `encryption-config.yaml` YAML syntax error**
`head -c 64 /dev/urandom | base64` produced a key that wrapped across two lines,
breaking YAML parsing in kube-apiserver. Fixed by using `head -c 32` and
`tr -d '\n'` to guarantee a single-line base64 value.

**8. Missing security group rules**
`01-network.sh` failed partway through SG rule creation. SSH (22), API (6443),
NodePort range (30000–32767), ICMP, and all-internal-traffic rules were added
manually and are now correctly applied by the script.

---

## Troubleshooting

```bash
# Check service logs on a node
sudo journalctl -u kube-apiserver -f
sudo journalctl -u etcd -f
sudo journalctl -u kubelet -f

# Check etcd cluster health (on any master)
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/master-kubernetes.pem \
  --key=/etc/etcd/master-kubernetes-key.pem

# SSH into a node manually
source run-all.sh
ssh_master 0    # SSH into master-0
ssh_worker 1    # SSH into worker-1

# Restart control plane services on a master
sudo systemctl restart kube-apiserver kube-controller-manager kube-scheduler

# Restart worker services on a worker
sudo systemctl restart kubelet kube-proxy containerd
```
