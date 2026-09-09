# Application bucket in Object Storage. Created with the static access key of a
# service account that has the storage.editor role. This is separate from the
# pre-created bucket that holds the Terraform state.
resource "yandex_storage_bucket" "app" {
  access_key = var.access_key
  secret_key = var.secret_key
  bucket     = var.app_bucket_name
}
