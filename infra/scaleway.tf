resource "scaleway_account_project" "storage" {
  name = "storage"
}

resource "scaleway_object_bucket" "nichi_backup_par" {
  project_id = scaleway_account_project.storage.id

  name   = "nichi-backup-par"
  region = "fr-par"

  lifecycle_rule {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
  }
}

# FIXME: enable manually
# https://github.com/scaleway/terraform-provider-scaleway/issues/3985
# resource "scaleway_object_bucket_server_side_encryption_configuration" "nichi_backup_par" {
#   bucket = scaleway_object_bucket.nichi_backup_par.name
#
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
