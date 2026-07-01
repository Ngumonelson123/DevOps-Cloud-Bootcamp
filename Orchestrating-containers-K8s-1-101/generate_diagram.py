import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

fig, ax = plt.subplots(figsize=(20, 26))
ax.set_xlim(0, 20)
ax.set_ylim(0, 26)
ax.axis('off')
fig.patch.set_facecolor('#0f1117')

# ── Helpers ────────────────────────────────────────────────────────────────

def box(ax, x, y, w, h, facecolor, edgecolor, radius=0.3, lw=1.5, alpha=1.0):
    rect = FancyBboxPatch((x, y), w, h,
                          boxstyle=f"round,pad=0,rounding_size={radius}",
                          facecolor=facecolor, edgecolor=edgecolor,
                          linewidth=lw, alpha=alpha)
    ax.add_patch(rect)

def txt(ax, x, y, s, size=9, color='#e2e8f0', ha='center', va='center',
        bold=False, mono=False):
    family = 'monospace' if mono else 'sans-serif'
    weight = 'bold' if bold else 'normal'
    ax.text(x, y, s, fontsize=size, color=color, ha=ha, va=va,
            fontfamily=family, fontweight=weight)

def arrow(ax, x, y1, y2, color='#6366f1', lw=2):
    ax.annotate('', xy=(x, y2), xytext=(x, y1),
                arrowprops=dict(arrowstyle='->', color=color,
                                lw=lw, mutation_scale=16))

def harrow(ax, x1, x2, y, color='#6366f1', lw=1.5):
    ax.annotate('', xy=(x2, y), xytext=(x1, y),
                arrowprops=dict(arrowstyle='<->', color=color,
                                lw=lw, mutation_scale=12))

def dot(ax, x, y, color):
    ax.plot(x, y, 'o', color=color, markersize=6, zorder=5)

def component(ax, x, y, w, h, label, dot_color, bg, fg='#e2e8f0'):
    box(ax, x, y, w, h, bg, bg, radius=0.15, lw=0)
    dot(ax, x + 0.22, y + h/2, dot_color)
    txt(ax, x + 0.45, y + h/2, label, size=7.5, color=fg, ha='left')

# ══════════════════════════════════════════════════════════════════════════
# TITLE
# ══════════════════════════════════════════════════════════════════════════
txt(ax, 10, 25.3, 'Kubernetes From Ground Up', size=18, color='#f8fafc', bold=True)
txt(ax, 10, 24.85, 'Manual cluster on AWS EC2  ·  us-east-1  ·  v1.21.0  ·  3 Masters + 3 Workers',
    size=9, color='#64748b')

# ══════════════════════════════════════════════════════════════════════════
# LOCAL MACHINE
# ══════════════════════════════════════════════════════════════════════════
box(ax, 5.5, 23.6, 9, 0.9, '#1e293b', '#334155', radius=0.25)
txt(ax, 10, 24.3, 'LOCAL MACHINE', size=7, color='#475569', bold=True)
for i, tool in enumerate(['kubectl', 'cfssl', 'aws cli', 'run-all.sh']):
    bx = 6.2 + i * 2.1
    box(ax, bx, 23.65, 1.8, 0.55, '#0f172a', '#334155', radius=0.15)
    txt(ax, bx + 0.9, 23.93, tool, size=8, color='#94a3b8', mono=True)

# ══════════════════════════════════════════════════════════════════════════
# ARROW: local → NLB
# ══════════════════════════════════════════════════════════════════════════
arrow(ax, 10, 23.6, 23.1, color='#3b82f6')
txt(ax, 10.35, 23.35, 'HTTPS :6443', size=7.5, color='#3b82f6', ha='left')

# ══════════════════════════════════════════════════════════════════════════
# NLB
# ══════════════════════════════════════════════════════════════════════════
box(ax, 3.5, 22.1, 13, 0.95, '#1e3a5f', '#3b82f6', radius=0.3, lw=2)
txt(ax, 10, 22.78, 'AWS NETWORK LOAD BALANCER', size=8, color='#3b82f6', bold=True)
txt(ax, 10, 22.42,
    'k8s-cluster-from-ground-up-b214173e4e23275c.elb.us-east-1.amazonaws.com  ·  TCP :6443',
    size=7.5, color='#93c5fd', mono=True)

# ══════════════════════════════════════════════════════════════════════════
# ARROWS: NLB → 3 masters
# ══════════════════════════════════════════════════════════════════════════
for mx in [3.6, 10.0, 16.4]:
    arrow(ax, mx, 22.1, 21.55, color='#6366f1')

txt(ax, 10, 21.75, 'forwards to all 3 masters', size=7.5, color='#6366f1')

# ══════════════════════════════════════════════════════════════════════════
# MASTERS
# ══════════════════════════════════════════════════════════════════════════
txt(ax, 10, 21.45, 'CONTROL PLANE  —  Masters (t3.small · Ubuntu 20.04)', size=7.5, color='#475569', bold=True)

masters = [
    ('master-0', '172.31.0.10', 'etcd-0'),
    ('master-1', '172.31.0.11', 'etcd-1'),
    ('master-2', '172.31.0.12', 'etcd-2'),
]

master_xs = [0.4, 7.1, 13.8]
master_w  = 6.0
master_top = 21.2

for (name, ip, etcd), mx in zip(masters, master_xs):
    # card border
    box(ax, mx, master_top - 4.2, master_w, 4.2, '#1a1f2e', '#4f46e5', radius=0.3, lw=2)
    # header
    box(ax, mx, master_top - 0.55, master_w, 0.55, '#2d2060', '#4f46e5', radius=0.25, lw=0)
    txt(ax, mx + 1.5, master_top - 0.27, name, size=9.5, color='#f1f5f9', bold=True, ha='left')
    txt(ax, mx + master_w - 0.15, master_top - 0.27, ip, size=8, color='#a5b4fc', ha='right', mono=True)

    cy = master_top - 0.75
    gap = 0.62
    component(ax, mx+0.15, cy,          master_w-0.3, 0.5, 'kube-apiserver  :6443', '#818cf8', '#1e1b4b', '#a5b4fc')
    component(ax, mx+0.15, cy - gap,    master_w-0.3, 0.5, 'kube-scheduler',        '#6b7280', '#1c1917', '#d6d3d1')
    component(ax, mx+0.15, cy - gap*2,  master_w-0.3, 0.5, 'kube-controller-manager','#6b7280','#1c1917','#d6d3d1')
    # divider
    ax.plot([mx+0.2, mx+master_w-0.2], [cy - gap*2 - 0.12, cy - gap*2 - 0.12],
            color='#1e293b', lw=1)
    component(ax, mx+0.15, cy - gap*3,  master_w-0.3, 0.5, f'{etcd}  :2379  (Raft)', '#818cf8', '#1a1a2e', '#818cf8')

# etcd peer arrows between masters
etcd_y = master_top - 0.75 - 0.62*3 + 0.25
harrow(ax, master_xs[0]+master_w, master_xs[1], etcd_y, color='#4f46e5', lw=1.2)
harrow(ax, master_xs[1]+master_w, master_xs[2], etcd_y, color='#4f46e5', lw=1.2)
txt(ax, 7.1, etcd_y - 0.22, 'Raft consensus', size=6.5, color='#4f46e5')
txt(ax, 13.8, etcd_y - 0.22, 'Raft consensus', size=6.5, color='#4f46e5')

# ══════════════════════════════════════════════════════════════════════════
# ARROWS: masters → workers
# ══════════════════════════════════════════════════════════════════════════
worker_top = master_top - 4.2 - 0.7
for mx in [3.4, 10.0, 16.6]:
    arrow(ax, mx, master_top - 4.2, worker_top + 3.65, color='#059669')

txt(ax, 10, worker_top + 3.8, 'kubelet registration  ·  pod scheduling', size=7.5, color='#059669')
txt(ax, 10, worker_top + 3.55, 'DATA PLANE  —  Workers (t3.small · Ubuntu 20.04)', size=7.5, color='#475569', bold=True)

# ══════════════════════════════════════════════════════════════════════════
# WORKERS
# ══════════════════════════════════════════════════════════════════════════
workers = [
    ('worker-0', '172.31.0.20', '172.20.0.0/24'),
    ('worker-1', '172.31.0.21', '172.20.1.0/24'),
    ('worker-2', '172.31.0.22', '172.20.2.0/24'),
]

worker_xs = [0.4, 7.1, 13.8]
worker_h  = 3.5

for (name, ip, cidr), wx in zip(workers, worker_xs):
    box(ax, wx, worker_top - worker_h + 0.35, master_w, worker_h, '#1a1f2e', '#059669', radius=0.3, lw=2)
    box(ax, wx, worker_top - 0.2 + 0.35, master_w, 0.55, '#064e3b', '#059669', radius=0.25, lw=0)
    txt(ax, wx + 1.5, worker_top + 0.1, name, size=9.5, color='#f1f5f9', bold=True, ha='left')
    txt(ax, wx + master_w - 0.15, worker_top + 0.1, ip, size=8, color='#6ee7b7', ha='right', mono=True)

    cy = worker_top - 0.4
    gap = 0.62
    component(ax, wx+0.15, cy,         master_w-0.3, 0.5, 'kubelet  v1.21.0',       '#34d399', '#022c22', '#6ee7b7')
    component(ax, wx+0.15, cy-gap,     master_w-0.3, 0.5, 'kube-proxy  (iptables)', '#6b7280', '#1c1917', '#d6d3d1')
    component(ax, wx+0.15, cy-gap*2,   master_w-0.3, 0.5, 'containerd  v1.4.4',     '#60a5fa', '#1a1a2e', '#93c5fd')
    ax.plot([wx+0.2, wx+master_w-0.2], [cy-gap*2-0.12, cy-gap*2-0.12], color='#1e293b', lw=1)
    component(ax, wx+0.15, cy-gap*3,   master_w-0.3, 0.5, f'CNI bridge  ·  {cidr}', '#fbbf24', '#1f2937', '#fbbf24')

# ══════════════════════════════════════════════════════════════════════════
# TLS SECTION
# ══════════════════════════════════════════════════════════════════════════
tls_y = worker_top - worker_h - 0.25
box(ax, 0.4, tls_y - 1.3, 19.2, 1.55, '#1a1f2e', '#334155', radius=0.3)
txt(ax, 1.0, tls_y + 0.1, 'TLS PKI  —  Mutual TLS across all components', size=8.5, color='#f59e0b', bold=True, ha='left')

certs = ['ca.pem (Root CA)', 'master-kubernetes.pem', 'kube-scheduler.pem',
         'kube-controller-manager.pem', 'kube-proxy.pem',
         'admin.pem', 'service-account.pem', 'worker-0.pem', 'worker-1.pem', 'worker-2.pem']

cols, rows = 5, 2
cw, ch = 3.6, 0.38
for i, cert in enumerate(certs):
    col = i % cols
    row = i // cols
    cx = 0.65 + col * (cw + 0.15)
    cy = tls_y - 0.25 - row * (ch + 0.12)
    fc = '#451a03' if 'Root' in cert else '#1c1917'
    ec = '#92400e' if 'Root' in cert else '#44403c'
    fc_txt = '#fbbf24' if 'Root' in cert else '#fcd34d'
    box(ax, cx, cy, cw, ch, fc, ec, radius=0.12, lw=1)
    txt(ax, cx + cw/2, cy + ch/2, cert, size=7.2, color=fc_txt, mono=True)

# ══════════════════════════════════════════════════════════════════════════
# AWS INFRA SECTION
# ══════════════════════════════════════════════════════════════════════════
aws_y = tls_y - 1.3 - 0.2
box(ax, 0.4, aws_y - 1.1, 19.2, 1.3, '#1a1f2e', '#334155', radius=0.3)
txt(ax, 1.0, aws_y + 0.05, 'AWS Infrastructure  —  us-east-1', size=8.5, color='#f97316', bold=True, ha='left')

infra = [
    ('VPC', '172.31.0.0/16'),
    ('Subnet', '172.31.0.0/24 · us-east-1a'),
    ('Internet Gateway', 'igw-0592ed969ca0198bb'),
    ('Security Group', ':22 · :6443 · :2379-2380 · :30000-32767'),
    ('etcd Encryption', 'AES-CBC 256-bit at rest'),
    ('RBAC', 'system:kube-apiserver-to-kubelet'),
]

iw = 3.0
for i, (k, v) in enumerate(infra):
    col = i % 3
    row = i // 3
    ix = 0.65 + col * (iw + 2.75)
    iy = aws_y - 0.22 - row * 0.52
    txt(ax, ix, iy,        k, size=6.5, color='#94a3b8', ha='left', bold=True)
    txt(ax, ix, iy - 0.22, v, size=7,   color='#e2e8f0', ha='left', mono=True)

# ══════════════════════════════════════════════════════════════════════════
# STATUS PILLS at bottom
# ══════════════════════════════════════════════════════════════════════════
statuses = ['worker-0 ✓ Ready', 'worker-1 ✓ Ready', 'worker-2 ✓ Ready',
            'etcd-0/1/2 ✓ Healthy', 'scheduler ✓ Healthy', 'controller-manager ✓ Healthy']

pill_y = aws_y - 1.1 - 0.35
pw = 2.9
gap_p = 0.25
total_w = len(statuses) * pw + (len(statuses)-1) * gap_p
start_x = (20 - total_w) / 2

for i, s in enumerate(statuses):
    px = start_x + i * (pw + gap_p)
    box(ax, px, pill_y - 0.28, pw, 0.38, '#0f2a1a', '#166534', radius=0.19, lw=1)
    dot(ax, px + 0.25, pill_y - 0.09, '#4ade80')
    txt(ax, px + 0.45, pill_y - 0.09, s, size=7, color='#4ade80', ha='left')

plt.tight_layout(pad=0)
plt.savefig('architecture.png', dpi=150, bbox_inches='tight',
            facecolor='#0f1117', edgecolor='none')
print("✅ architecture.png saved")
