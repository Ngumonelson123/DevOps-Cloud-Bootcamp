#!/bin/bash
# ============================================================
#  scripts/test-all.sh
#  Run this after terraform apply + ansible to verify
#  everything is working end-to-end.
#
#  Usage: ./scripts/test-all.sh mycompany.ga
# ============================================================

DOMAIN="${1:-mycompany.ga}"
TOOLING="tooling.$DOMAIN"
PASS=0
FAIL=0
WARN=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}  ✓ PASS${NC} – $1"; ((PASS++)); }
fail() { echo -e "${RED}  ✗ FAIL${NC} – $1"; ((FAIL++)); }
warn() { echo -e "${YELLOW}  ⚠ WARN${NC} – $1"; ((WARN++)); }
header() { echo -e "\n${YELLOW}══ $1 ══${NC}"; }

# ── 1. DNS Resolution ─────────────────────────────────────────
header "DNS Resolution"

if host "$DOMAIN" > /dev/null 2>&1; then
  pass "Root domain $DOMAIN resolves"
else
  fail "Root domain $DOMAIN does NOT resolve – check Route 53 + Freenom NS records"
fi

if host "$TOOLING" > /dev/null 2>&1; then
  pass "Tooling subdomain $TOOLING resolves"
else
  fail "Tooling subdomain $TOOLING does NOT resolve"
fi

# ── 2. HTTP → HTTPS Redirect ──────────────────────────────────
header "HTTP → HTTPS Redirect"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" --max-time 10)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
  pass "HTTP redirects to HTTPS (got $HTTP_CODE)"
else
  fail "HTTP redirect failed – got $HTTP_CODE (expected 301/302)"
fi

# ── 3. WordPress HTTPS ────────────────────────────────────────
header "WordPress Website"

WP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --max-time 15 -k)
if [ "$WP_CODE" = "200" ] || [ "$WP_CODE" = "302" ]; then
  pass "WordPress homepage responds ($WP_CODE)"
else
  fail "WordPress homepage failed – got $WP_CODE"
fi

WP_HEALTH=$(curl -s "https://$DOMAIN/healthstatus" --max-time 10 -k)
if [ "$WP_HEALTH" = "healthy" ]; then
  pass "WordPress health check endpoint returns 'healthy'"
else
  fail "WordPress health check failed – got: '$WP_HEALTH'"
fi

# ── 4. Tooling HTTPS ──────────────────────────────────────────
header "Tooling Website"

TOOL_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TOOLING" --max-time 15 -k)
if [ "$TOOL_CODE" = "200" ] || [ "$TOOL_CODE" = "302" ]; then
  pass "Tooling homepage responds ($TOOL_CODE)"
else
  fail "Tooling homepage failed – got $TOOL_CODE"
fi

TOOL_HEALTH=$(curl -s "https://$TOOLING/healthstatus" --max-time 10 -k)
if [ "$TOOL_HEALTH" = "healthy" ]; then
  pass "Tooling health check returns 'healthy'"
else
  fail "Tooling health check failed – got: '$TOOL_HEALTH'"
fi

# ── 5. TLS Certificate ────────────────────────────────────────
header "TLS Certificate"

CERT_DOMAIN=$(echo | openssl s_client -servername "$DOMAIN" \
  -connect "$DOMAIN":443 2>/dev/null | \
  openssl x509 -noout -subject 2>/dev/null | \
  grep -o 'CN=.*' | cut -d= -f2)

if echo "$CERT_DOMAIN" | grep -q "$DOMAIN"; then
  pass "TLS certificate domain matches ($CERT_DOMAIN)"
else
  warn "TLS cert domain mismatch: got '$CERT_DOMAIN', expected '*.$DOMAIN'"
fi

CERT_EXPIRY=$(echo | openssl s_client -servername "$DOMAIN" \
  -connect "$DOMAIN":443 2>/dev/null | \
  openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
pass "TLS certificate expires: $CERT_EXPIRY"

# ── 6. AWS Resource Checks ────────────────────────────────────
header "AWS Infrastructure"

# Check ALBs are active
EXT_ALB_STATE=$(aws elbv2 describe-load-balancers \
  --names rproxy-ext-alb \
  --query 'LoadBalancers[0].State.Code' \
  --output text 2>/dev/null)

if [ "$EXT_ALB_STATE" = "active" ]; then
  pass "External ALB is active"
else
  fail "External ALB state: $EXT_ALB_STATE"
fi

INT_ALB_STATE=$(aws elbv2 describe-load-balancers \
  --names rproxy-int-alb \
  --query 'LoadBalancers[0].State.Code' \
  --output text 2>/dev/null)

if [ "$INT_ALB_STATE" = "active" ]; then
  pass "Internal ALB is active"
else
  fail "Internal ALB state: $INT_ALB_STATE"
fi

# Check RDS is available
RDS_STATUS=$(aws rds describe-db-instances \
  --db-instance-identifier rproxy-mysql \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text 2>/dev/null)

if [ "$RDS_STATUS" = "available" ]; then
  pass "RDS MySQL instance is available"
else
  fail "RDS status: $RDS_STATUS"
fi

# Check EFS mount targets
EFS_TARGETS=$(aws efs describe-mount-targets \
  --query 'MountTargets[?LifeCycleState==`available`] | length(@)' \
  --output text 2>/dev/null)

if [ "$EFS_TARGETS" -ge "2" ] 2>/dev/null; then
  pass "EFS has $EFS_TARGETS available mount targets"
else
  fail "EFS mount targets not ready (found: $EFS_TARGETS)"
fi

# Check ASG instance counts
for ASG in rproxy-nginx-asg rproxy-wordpress-asg rproxy-tooling-asg; do
  INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG" \
    --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`] | length(@)' \
    --output text 2>/dev/null)

  if [ "$INSTANCES" -ge "1" ] 2>/dev/null; then
    pass "$ASG has $INSTANCES healthy instance(s)"
  else
    fail "$ASG has no InService instances (count: $INSTANCES)"
  fi
done

# ── 7. Target Group Health ────────────────────────────────────
header "ALB Target Group Health"

for TG_NAME in rproxy-nginx-tg rproxy-wordpress-tg rproxy-tooling-tg; do
  TG_ARN=$(aws elbv2 describe-target-groups \
    --names "$TG_NAME" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>/dev/null)

  if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    HEALTHY=$(aws elbv2 describe-target-health \
      --target-group-arn "$TG_ARN" \
      --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
      --output text 2>/dev/null)

    if [ "$HEALTHY" -ge "1" ] 2>/dev/null; then
      pass "$TG_NAME: $HEALTHY healthy target(s)"
    else
      fail "$TG_NAME: no healthy targets (check health check path /healthstatus)"
    fi
  else
    warn "Could not find target group: $TG_NAME"
  fi
done

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════"
echo -e "  Results: ${GREEN}$PASS passed${NC}  ${RED}$FAIL failed${NC}  ${YELLOW}$WARN warnings${NC}"
echo "══════════════════════════════════════"

if [ "$FAIL" -gt "0" ]; then
  echo ""
  echo "Some checks failed. Common fixes:"
  echo "  - DNS: Wait 10-15 min after updating Freenom nameservers"
  echo "  - Health checks: SSH to instances and check 'systemctl status httpd'"
  echo "  - RDS: Verify security group allows port 3306 from webserver SG"
  echo "  - EFS: Verify security group allows port 2049 from all server SGs"
  exit 1
fi

echo ""
echo "All checks passed! Your infrastructure is healthy."
exit 0
