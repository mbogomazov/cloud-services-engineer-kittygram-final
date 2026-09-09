#!/usr/bin/env bash
# Phase 0 bootstrap for Kittygram infra. Idempotent-ish.
# Creates: service account + roles, static access key, SSH key, state + app
# buckets. Writes infra/terraform.tfvars (gitignored) and prints the values to
# put into GitHub Secrets.
#
# Run from the repo root:  ! bash infra/bootstrap.sh
set -euo pipefail

SA_NAME="kittygram-sa"
CLOUD_ID="$(yc config get cloud-id)"
FOLDER_ID="$(yc config get folder-id)"
ZONE="${ZONE:-ru-central1-d}"
TF_STATE_BUCKET="kittygram-tfstate-${FOLDER_ID}"
APP_BUCKET="kittygram-app-${FOLDER_ID}"
# Dedicated, passphrase-less key for the VM and for the CI deploy job. A
# personal key with a passphrase cannot be used by appleboy/ssh-action.
SSH_KEY="${HOME}/.ssh/kittygram_ed25519"

jqpy() { python3 -c "import sys,json;print(json.load(sys.stdin)$1)"; }

echo ">> cloud=${CLOUD_ID} folder=${FOLDER_ID} zone=${ZONE}"

# 1. Service account
echo ">> service account"
yc iam service-account create --name "$SA_NAME" >/dev/null 2>&1 || echo "   exists"
SA_ID="$(yc iam service-account get --name "$SA_NAME" --format json | jqpy '["id"]')"
echo "   SA_ID=${SA_ID}"

# 2. Roles on the folder
echo ">> roles"
for role in editor storage.editor; do
  yc resource-manager folder add-access-binding "$FOLDER_ID" \
    --role "$role" --subject "serviceAccount:${SA_ID}" >/dev/null 2>&1 \
    && echo "   +${role}" || echo "   ${role} (already?)"
done

# 3. Static access key
echo ">> static access key"
KEY_JSON="$(yc iam access-key create --service-account-name "$SA_NAME" --format json)"
ACCESS_KEY="$(echo "$KEY_JSON" | jqpy '["access_key"]["key_id"]')"
SECRET_KEY="$(echo "$KEY_JSON" | jqpy '["secret"]')"
echo "   ACCESS_KEY=${ACCESS_KEY}"

# 4. SSH key
echo ">> ssh key"
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -C "kittygram"
fi
SSH_PUB="$(cat "${SSH_KEY}.pub")"

# 5. State bucket only: it must exist before `terraform init` can use the S3
# backend. The application bucket is managed by Terraform itself, so creating
# it here would collide with yandex_storage_bucket.app on the first apply.
echo ">> state bucket"
yc storage bucket create --name "$TF_STATE_BUCKET" >/dev/null 2>&1 && echo "   +${TF_STATE_BUCKET}" || echo "   ${TF_STATE_BUCKET} (exists?)"

# 6. terraform.tfvars (gitignored)
echo ">> writing infra/terraform.tfvars"
cat > "$(dirname "$0")/terraform.tfvars" <<EOF
cloud_id        = "${CLOUD_ID}"
folder_id       = "${FOLDER_ID}"
zone            = "${ZONE}"
access_key      = "${ACCESS_KEY}"
secret_key      = "${SECRET_KEY}"
app_bucket_name = "${APP_BUCKET}"
vm_user         = "yc-user"
ssh_public_key  = "${SSH_PUB}"
gateway_port    = 9000
EOF

cat <<EOF

==================== DONE ====================
GitHub Secrets to set:
  ACCESS_KEY       = ${ACCESS_KEY}
  SECRET_KEY       = ${SECRET_KEY}
  YC_TOKEN         = \$(yc iam create-token)   # short-lived; or use SA key file
  YC_CLOUD_ID      = ${CLOUD_ID}
  YC_FOLDER_ID     = ${FOLDER_ID}
  TF_STATE_BUCKET  = ${TF_STATE_BUCKET}
  APP_BUCKET_NAME  = ${APP_BUCKET}
  SSH_PUBLIC_KEY   = ${SSH_PUB}

Deploy secrets (for deploy.yml), set after VM is up:
  HOST    = <vm external ip from: terraform output>
  USER    = yc-user
  PORT    = 22
  SSH_KEY = contents of ${SSH_KEY}   (private key)
  DOCKER_USERNAME, DOCKER_PASSWORD
  POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
  TELEGRAM_TO, TELEGRAM_TOKEN

Next:
  cd infra
  export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
  export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
  export YC_TOKEN=\$(yc iam create-token)
  terraform init -backend-config="bucket=${TF_STATE_BUCKET}"
  terraform apply
==============================================
EOF
