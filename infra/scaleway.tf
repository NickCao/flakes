resource "scaleway_account_project" "storage" {
  name = "storage"
}

module "nichi_backup_par" {
  source     = "./modules/scaleway_bucket"
  project_id = scaleway_account_project.storage.id
  name       = "nichi-backup-par"
  region     = "fr-par"
}

module "nichi_backup_ams" {
  source     = "./modules/scaleway_bucket"
  project_id = scaleway_account_project.storage.id
  name       = "nichi-backup-ams"
  region     = "nl-ams"
}

data "scaleway_iam_user" "nickcao" {
  email = "nickcao@nichi.co"
}

resource "scaleway_object_bucket_policy" "nichi_backup_ams" {
  project_id = scaleway_account_project.storage.id

  bucket = module.nichi_backup_ams.id
  policy = jsonencode({
    Version : "2023-04-17",
    Id : "NichiBackupAmsBucketPolicy",
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
          module.nichi_backup_ams.name,
          "${module.nichi_backup_ams.name}/*"
        ],
      },
      {
        Sid : "Rclone",
        # https://rclone.org/s3/#s3-permissions
        Action : [
          "s3:ListBucket",
          "s3:GetObject",
        ],
        Effect : "Allow",
        Principal : {
          SCW : [
            "application_id:${scaleway_iam_application.rclone.id}"
          ]
        },
        Resource : [
          module.nichi_backup_ams.name,
          "${module.nichi_backup_ams.name}/*"
        ],
      },
      {
        Sid : "Restic",
        # https://rclone.org/s3/#s3-permissions
        Action : [
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Effect : "Allow",
        Principal : {
          SCW : [
            "application_id:${scaleway_iam_application.restic.id}"
          ]
        },
        Resource : [
          module.nichi_backup_ams.name,
          "${module.nichi_backup_ams.name}/*"
        ],
      }
    ]
  })
}

resource "scaleway_object_bucket_policy" "nichi_backup_par" {
  project_id = scaleway_account_project.storage.id

  bucket = module.nichi_backup_par.id
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
          module.nichi_backup_par.name,
          "${module.nichi_backup_par.name}/*"
        ],
      },
      {
        Sid : "Application",
        # https://rclone.org/s3/#s3-permissions
        Action : [
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Effect : "Allow",
        Principal : {
          SCW : [
            "application_id:${scaleway_iam_application.rclone.id}"
          ]
        },
        Resource : [
          module.nichi_backup_par.name,
          "${module.nichi_backup_par.name}/*"
        ],
      }
    ]
  })
}

resource "scaleway_iam_application" "restic" {
  name = "restic"
}

resource "scaleway_iam_policy" "restic" {
  name           = "restic"
  application_id = scaleway_iam_application.restic.id
  rule {
    project_ids          = [scaleway_account_project.storage.id]
    permission_set_names = ["ObjectStorageFullAccess"]
  }
}

resource "scaleway_iam_api_key" "restic" {
  application_id     = scaleway_iam_application.restic.id
  default_project_id = scaleway_account_project.storage.id
}

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
  region = module.nichi_backup_par.region
}

resource "scaleway_secret_version" "rclone_v1" {
  region    = module.nichi_backup_par.region
  secret_id = scaleway_secret.rclone.id
  data      = <<EOT
[ams]
type = s3
provider = Scaleway
env_auth = false
endpoint = s3.${module.nichi_backup_ams.region}.scw.cloud
access_key_id = ${scaleway_iam_api_key.rclone.access_key}
secret_access_key = ${scaleway_iam_api_key.rclone.secret_key}
region = ${module.nichi_backup_ams.region}
location_constraint =
acl = private
force_path_style = false
server_side_encryption =
storage_class = ONEZONE_IA

[par]
type = s3
provider = Scaleway
env_auth = false
endpoint = s3.${module.nichi_backup_par.region}.scw.cloud
access_key_id = ${scaleway_iam_api_key.rclone.access_key}
secret_access_key = ${scaleway_iam_api_key.rclone.secret_key}
region = ${module.nichi_backup_par.region}
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
  region = module.nichi_backup_par.region

  timeout                = "30m"
  cpu_limit              = 1120
  memory_limit           = 512
  local_storage_capacity = 1000

  image_uri = "ghcr.io/rclone/rclone:1.74.1"
  args = [
    "sync",
    "--s3-no-check-bucket",
    "--checksum", "--progress",
    "--transfers", "8",
    "ams:${module.nichi_backup_ams.name}",
    "par:${module.nichi_backup_par.name}",
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

data "scaleway_cockpit_sources" "metrics" {
  project_id = scaleway_account_project.storage.id

  origin = "scaleway"
  type   = "metrics"
}

resource "scaleway_cockpit_exporter" "victoriametrics" {
  project_id = scaleway_account_project.storage.id

  name   = "victoriametrics"
  region = module.nichi_backup_par.region

  datasource_id     = data.scaleway_cockpit_sources.metrics.sources[0].id
  exported_products = ["object-storage", "serverless-jobs"]

  otlp_destination {
    endpoint = "https://metrics.nichi.co/opentelemetry"
    headers = {
      Authorization = "Basic ${local.secrets.victoriametrics.basic}"
    }
  }
}
