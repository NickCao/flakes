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

resource "scaleway_object_bucket_acl" "nichi_backup_par" {
  project_id = scaleway_account_project.storage.id

  bucket = scaleway_object_bucket.nichi_backup_par.id
  acl    = "private"
}

data "scaleway_iam_user" "nickcao" {
  email = "nickcao@nichi.co"
}

resource "scaleway_object_bucket_policy" "nichi_backup_par" {
  project_id = scaleway_account_project.storage.id

  bucket = scaleway_object_bucket.nichi_backup_par.id
  policy = jsonencode({
    Version : "2023-04-17",
    Id : "NichiBackupParBucketPolicy",
    Statement : [
      {
        Sid : "User",
        Action : "*",
        Effect : "Allow",
        Principal : {
          SCW : [
            "user_id:${data.scaleway_iam_user.nickcao.id}",
          ]
        },
        Resource : [
          scaleway_object_bucket.nichi_backup_par.name
        ],
      },
      {
        Sid : "Application",
        Action : "*",
        Effect : "Allow",
        Principal : {
          SCW : [
            "application_id:${scaleway_iam_application.rclone.id}"
          ]
        },
        Resource : [
          scaleway_object_bucket.nichi_backup_par.name
        ],
      }
    ]
  })
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

resource "scaleway_iam_application" "rclone" {
  name = "rclone"
}

resource "scaleway_iam_policy" "rclone" {
  name           = "rclone"
  application_id = scaleway_iam_application.rclone.id
  rule {
    project_ids          = [scaleway_account_project.storage.id]
    permission_set_names = ["ObjectStorageFullAccess"]
  }
}

resource "scaleway_iam_api_key" "rclone" {
  application_id     = scaleway_iam_application.rclone.id
  default_project_id = scaleway_account_project.storage.id
}

resource "scaleway_secret" "rclone" {
  project_id = scaleway_account_project.storage.id

  name   = "rclone"
  region = scaleway_object_bucket.nichi_backup_par.region
}

resource "scaleway_secret_version" "rclone_v1" {
  region    = scaleway_object_bucket.nichi_backup_par.region
  secret_id = scaleway_secret.rclone.id
  data      = <<EOT
[b2]
type = b2
account = ${local.secrets.b2.account}
key = ${local.secrets.b2.key}
hard_delete = true

[scaleway]
type = s3
provider = Scaleway
env_auth = false
endpoint = s3.${scaleway_object_bucket.nichi_backup_par.region}.scw.cloud
access_key_id = ${scaleway_iam_api_key.rclone.access_key}
secret_access_key = ${scaleway_iam_api_key.rclone.secret_key}
region = ${scaleway_object_bucket.nichi_backup_par.region}
location_constraint =
acl = private
force_path_style = false
server_side_encryption =
storage_class = ONEZONE_IA
EOT
}

# TODO: add monitoring
resource "scaleway_job_definition" "rclone" {
  project_id = scaleway_account_project.storage.id

  name   = "rclone"
  region = scaleway_object_bucket.nichi_backup_par.region

  timeout                = "30m"
  cpu_limit              = 1120
  memory_limit           = 512
  local_storage_capacity = 1000

  image_uri = "ghcr.io/rclone/rclone:1.74.1"
  args = [
    "sync",
    "--checksum", "--progress",
    "--transfers", "8",
    "b2:nichi-backup", "scaleway:${scaleway_object_bucket.nichi_backup_par.name}",
  ]

  secret_reference {
    secret_id = scaleway_secret.rclone.id
    file      = "/config/rclone/rclone.conf"
  }

  cron {
    schedule = "30 1 * * *"
    timezone = "Etc/UTC"
  }
}
