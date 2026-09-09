terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
  }

  # Terraform state is stored in a pre-created Object Storage (S3) bucket.
  # The bucket name is supplied at init time via -backend-config to avoid
  # hardcoding it here, e.g.:
  #   terraform init -backend-config="bucket=<your-tfstate-bucket>"
  # Credentials come from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars.
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    region = "ru-central1"
    key    = "tf-state.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
  # Authentication is taken from the YC_TOKEN env var (OAuth/IAM token) or a
  # service account key file referenced by YC_SERVICE_ACCOUNT_KEY_FILE.
}
