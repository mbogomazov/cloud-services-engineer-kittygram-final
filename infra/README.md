# Kittygram infrastructure (Terraform + Yandex Cloud)

Provisions the cloud infrastructure for Kittygram:

- VPC network + subnet + reserved public IP
- Security group: inbound `22` (SSH) and `9000` (gateway HTTP); all outbound allowed
- Compute VM (Ubuntu 24.04 LTS) with Docker installed via cloud-init
- Object Storage bucket for the application
- Terraform state stored in a pre-created S3 bucket

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | Terraform + Yandex provider + S3 backend |
| `variables.tf` | Input variables |
| `network.tf` | VPC network, subnet, reserved public IP |
| `security_group.tf` | Firewall rules |
| `vm.tf` | Compute instance + Ubuntu image + cloud-init metadata |
| `storage.tf` | Application Object Storage bucket |
| `outputs.tf` | VM IP, app URL, bucket name |
| `cloud-init.yml` | Installs Docker + Compose plugin, creates user |
| `terraform.tfvars.example` | Template for local variables |

## One-time bootstrap (manual, outside Terraform)

The S3 backend needs its bucket to exist before `terraform init`.

1. Create a cloud + folder, activate the promo code.
2. Create a service account; grant `editor` (or `storage.editor` + `compute.editor` + `vpc.editor`).
3. Create a static access key for that account → `ACCESS_KEY` / `SECRET_KEY`.
4. Create the **state bucket** manually:
   ```bash
   yc storage bucket create --name <your-tfstate-bucket>
   ```
5. Generate an SSH keypair (`ssh-keygen -t ed25519`); use the public key as `ssh_public_key`.

## Local usage

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # fill in values
export AWS_ACCESS_KEY_ID=<ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
export YC_TOKEN=$(yc iam create-token)

terraform init -backend-config="bucket=<your-tfstate-bucket>"
terraform plan
terraform apply
terraform output            # VM IP + Kittygram URL
```

## CI usage

The `Terraform` workflow (`.github/workflows/terraform.yml`) runs manually
(`workflow_dispatch`) with action `plan` / `apply` / `destroy`.

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `ACCESS_KEY` | Object Storage static key ID (backend + provider) |
| `SECRET_KEY` | Object Storage static secret key |
| `YC_TOKEN` | Yandex Cloud IAM/OAuth token for provider auth |
| `YC_CLOUD_ID` | Cloud ID |
| `YC_FOLDER_ID` | Folder ID |
| `TF_STATE_BUCKET` | Pre-created bucket holding `tf-state.tfstate` |
| `APP_BUCKET_NAME` | Name for the application bucket |
| `SSH_PUBLIC_KEY` | SSH public key for the VM user |

## After `apply`

The public IP is a reserved `yandex_vpc_address`, so it stays the same when the
VM itself is recreated. It is released by a full teardown, so after a
teardown/apply cycle steps 2 and 3 have to be repeated with the new address.

1. Read `terraform output` → VM external IP.
2. Set deploy secret `HOST` to that IP (and `USER`, `PORT=22`, `SSH_KEY`).
3. Update `../tests.yml` `kittygram_domain` to `http://<IP>:9000`.
4. Push to `main` → the `Kittygram Deploy` workflow deploys the app.
