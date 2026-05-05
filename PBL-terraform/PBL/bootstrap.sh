#!/usr/bin/env bash
# ============================================================
#  bootstrap.sh
#  Run ONCE before `terraform init` to create:
#    - S3 bucket for Terraform state
#    - DynamoDB table for state locking
#    - EC2 Key Pair (saved to devops-key.pem)
#
#  Usage: chmod +x bootstrap.sh && ./bootstrap.sh
# ============================================================

set -euo pipefail

# ── Configuration — edit these ───────────────────────────────
REGION="us-east-1"
BUCKET_NAME="pbl-terraform-state-$(aws sts get-caller-identity --query Account --output text)-2026"
DYNAMO_TABLE="terraform-state-lock"
KEY_PAIR_NAME="devops-key"
KEY_FILE="devops-key.pem"

echo ""
echo "========================================"
echo "  PBL Terraform Bootstrap"
echo "========================================"
echo "Region       : $REGION"
echo "S3 Bucket    : $BUCKET_NAME"
echo "DynamoDB     : $DYNAMO_TABLE"
echo "Key Pair     : $KEY_PAIR_NAME"
echo ""

# ── S3 Bucket ────────────────────────────────────────────────
echo "[1/5] Creating S3 bucket for Terraform state..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "  ✔ Bucket already exists: $BUCKET_NAME"
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "  ✔ Created bucket: $BUCKET_NAME"
fi

echo "[2/5] Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled
echo "  ✔ Versioning enabled"

echo "[3/5] Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo "  ✔ Encryption enabled"

# ── DynamoDB Table ───────────────────────────────────────────
echo "[4/5] Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --region "$REGION" 2>/dev/null; then
  echo "  ✔ DynamoDB table already exists: $DYNAMO_TABLE"
else
  aws dynamodb create-table \
    --table-name "$DYNAMO_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "  ✔ Created DynamoDB table: $DYNAMO_TABLE"
fi

# ── EC2 Key Pair ─────────────────────────────────────────────
echo "[5/5] Creating EC2 Key Pair..."
if [ -f "$KEY_FILE" ]; then
  echo "  ✔ Key file already exists locally: $KEY_FILE"
else
  aws ec2 create-key-pair \
    --key-name "$KEY_PAIR_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$KEY_FILE"
  chmod 400 "$KEY_FILE"
  echo "  ✔ Key pair created and saved to: $KEY_FILE"
fi

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Bootstrap Complete!"
echo "========================================"
echo ""
echo "  Next: update backends.tf with your bucket name:"
echo ""
echo "    bucket = \"$BUCKET_NAME\""
echo ""
echo "  Then run:"
echo "    terraform init"
echo "    terraform plan"
echo "    terraform apply"
echo ""
