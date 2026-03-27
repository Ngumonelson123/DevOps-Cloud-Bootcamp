# Troubleshooting Runbook

## How to SSH Into Private Servers

All private servers (Nginx, WordPress, Tooling) are not directly reachable.
You must jump through the Bastion host.

```bash
# Step 1 – SSH into Bastion (get EIP from terraform output or AWS Console)
ssh -i ~/.ssh/my-keypair.pem ec2-user@<BASTION_EIP>

# Step 2 – From Bastion, SSH to a private server
ssh -i ~/.ssh/my-keypair.pem ec2-user@<PRIVATE_IP>

# One-liner using ProxyJump (run from your laptop directly)
ssh -i ~/.ssh/my-keypair.pem \
    -o ProxyJump=ec2-user@<BASTION_EIP> \
    ec2-user@<PRIVATE_IP>
```

---

## Problem 1 – Health Check Failing (Targets Unhealthy in ALB)

**Symptom:** ALB target group shows 0 healthy hosts.

**Check 1 – Is the web server running?**
```bash
# For Nginx servers
sudo systemctl status nginx
sudo journalctl -u nginx -n 50

# For WordPress/Tooling servers
sudo systemctl status httpd
sudo journalctl -u httpd -n 50
```

**Check 2 – Does the health check path exist?**
```bash
curl -k https://localhost/healthstatus
# Should return: healthy
```

If it returns 404, create it:
```bash
echo "healthy" | sudo tee /var/www/html/healthstatus
# or for Nginx:
echo "healthy" | sudo tee /usr/share/nginx/html/healthstatus
```

**Check 3 – Is the security group correct?**

The ALB's security group must be allowed to reach the server on port 443.
Go to: EC2 → Target Groups → select TG → Health checks tab → verify port = 443.

**Check 4 – Check user-data script ran correctly**
```bash
sudo cat /var/log/cloud-init-output.log | tail -50
```

---

## Problem 2 – EFS Not Mounting

**Symptom:** `mount: wrong fs type` or webserver can't write files.

**Check 1 – Is the mount target in the same AZ?**
```bash
aws efs describe-mount-targets --query \
  'MountTargets[*].{AZ:AvailabilityZoneName,State:LifeCycleState}'
```
Both AZs must show `available`.

**Check 2 – Is port 2049 open?**
The data security group must allow inbound TCP 2049 from the webserver SG.

**Check 3 – Manually test the mount**
```bash
sudo mkdir -p /mnt/test-efs
sudo mount -t efs -o tls fs-XXXXXXXX:/ /mnt/test-efs

# If it hangs for >30 seconds, it's a security group issue
# If it errors immediately, it's a DNS or package issue

# Install amazon-efs-utils if missing
sudo yum install -y amazon-efs-utils
```

**Check 4 – Check fstab entry**
```bash
cat /etc/fstab | grep efs
# Should show something like:
# fs-XXXXXXXX:/wordpress /var/www/html/wordpress efs _netdev,tls 0 0

# Re-mount everything in fstab
sudo mount -a
```

---

## Problem 3 – WordPress Shows "Error Establishing Database Connection"

**Check 1 – Can the webserver reach RDS?**
```bash
# From the WordPress server (through Bastion):
telnet <rds-endpoint> 3306
# Should connect (you'll see a MySQL banner)

# Or:
nc -zv <rds-endpoint> 3306
```

**Check 2 – Are the credentials correct in wp-config.php?**
```bash
sudo grep -E "DB_HOST|DB_USER|DB_NAME|DB_PASSWORD" \
  /var/www/html/wordpress/wp-config.php
```

**Check 3 – Does the database exist?**
```bash
mysql -h <rds-endpoint> -u admin -p -e "SHOW DATABASES;"
# If wordpressdb is missing, create it:
mysql -h <rds-endpoint> -u admin -p -e "CREATE DATABASE wordpressdb;"
```

**Check 4 – Security group**
RDS security group must allow TCP 3306 inbound from the webserver security group.

---

## Problem 4 – Domain Not Resolving

**Check 1 – Are the Freenom NS records pointing to Route 53?**
```bash
# Get the 4 NS records Route 53 assigned to your hosted zone
aws route53 list-hosted-zones-by-name --dns-name yourdomain.ga \
  --query 'HostedZones[0].Id' --output text | \
  xargs -I{} aws route53 get-hosted-zone --id {} \
  --query 'DelegationSet.NameServers'

# Then check what Freenom is serving:
nslookup -type=NS yourdomain.ga 8.8.8.8
```
If they don't match → update Freenom → wait 15-30 minutes.

**Check 2 – Does the A record exist in Route 53?**
```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --query "ResourceRecordSets[?Type=='A']"
```

**Check 3 – Force DNS refresh**
```bash
# Clear local DNS cache (Linux)
sudo systemd-resolve --flush-caches

# Test with Google DNS directly
nslookup yourdomain.ga 8.8.8.8
```

---

## Problem 5 – ACM Certificate Stuck in "Pending Validation"

**Cause:** The DNS validation CNAME records haven't propagated yet,
or they were not created in Route 53.

**Check 1 – Do the CNAME records exist?**
```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --query "ResourceRecordSets[?Type=='CNAME']"
```
If empty → re-run `terraform apply` – it will recreate them.

**Check 2 – Has DNS propagated?**
```bash
# Look up the CNAME from ACM console and test it:
nslookup _abc123.yourdomain.ga 8.8.8.8
```
Wait up to 30 minutes for propagation.

---

## Problem 6 – Nginx Returns 502 Bad Gateway

**Cause:** Nginx can't reach the Internal ALB or Internal ALB has no healthy targets.

**Check 1 – Is the Internal ALB DNS resolving from Nginx?**
```bash
# From the Nginx server:
nslookup <internal-alb-dns>
curl -k https://<internal-alb-dns>/healthstatus
```

**Check 2 – Are WordPress/Tooling targets healthy?**
```bash
aws elbv2 describe-target-health \
  --target-group-arn <wordpress-tg-arn>
```

**Check 3 – Check Nginx error log**
```bash
sudo tail -50 /var/log/nginx/error.log
```

Common errors:
- `upstream timed out` → Internal ALB is slow, increase `proxy_read_timeout`
- `SSL_do_handshake() failed` → Add `proxy_ssl_verify off;` to nginx.conf
- `no resolver defined` → Add `resolver 169.254.169.253;` (AWS DNS) to nginx.conf

---

## Problem 7 – terraform apply Fails Mid-Way

**If RDS fails:** RDS takes longest. If it times out, run `terraform apply` again –
Terraform is idempotent and will pick up where it left off.

**If ACM validation times out:**
```bash
# Check certificate status
aws acm list-certificates --query 'CertificateSummaryList[*].{Domain:DomainName,Status:Status}'

# If PENDING_VALIDATION, check Route 53 CNAME records exist
# then wait and re-run apply
terraform apply
```

**If state lock error:**
```bash
# If a previous apply was killed, the lock may be stuck
terraform force-unlock <LOCK_ID>
```

**If resource already exists error:**
```bash
# Import the existing resource into state
terraform import aws_vpc.main vpc-XXXXXXXX
```

---

## Useful AWS CLI Commands for Debugging

```bash
# Get private IPs of all running EC2 instances tagged with your project
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=rproxy" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{Name:Tags[?Key==`Name`].Value|[0],IP:PrivateIpAddress,PublicIP:PublicIpAddress}' \
  --output table

# Watch ASG activity in real time
watch -n 5 'aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name rproxy-nginx-asg \
  --query "Activities[0:3].{Status:StatusCode,Desc:Description}" \
  --output table'

# Check ALB access logs (if enabled)
aws s3 ls s3://your-alb-logs-bucket/AWSLogs/ --recursive | tail -5

# Get RDS slow query log
aws rds download-db-log-file-portion \
  --db-instance-identifier rproxy-mysql \
  --log-file-name slowquery/mysql-slowquery.log \
  --output text

# Force ASG to refresh instances (rolling replace)
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name rproxy-nginx-asg \
  --preferences '{"MinHealthyPercentage": 50}'

# Check CloudWatch alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix rproxy \
  --query 'MetricAlarms[*].{Name:AlarmName,State:StateValue,Reason:StateReason}' \
  --output table
```

---

## Cost Emergency – Stop Everything Immediately

If you see unexpected AWS charges:

```bash
# Option 1 – Full destroy (recommended)
terraform destroy

# Option 2 – Stop EC2 instances immediately (keeps RDS/EFS)
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=rproxy" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | xargs aws ec2 stop-instances --instance-ids

# Option 3 – Delete NAT Gateway (biggest cost item after RDS)
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=rproxy" \
  --query 'NatGateways[*].NatGatewayId' \
  --output text | xargs -I{} aws ec2 delete-nat-gateway --nat-gateway-id {}
```

⚠️ After `terraform destroy`, always verify in the AWS Console:
- EC2 → Instances: all terminated
- RDS → Databases: all deleted
- EC2 → Load Balancers: all deleted
- VPC → NAT Gateways: all deleted
- EC2 → Elastic IPs: release any unassociated EIPs
