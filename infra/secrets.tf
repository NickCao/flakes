data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

locals {
  secrets = yamldecode(data.sops_file.secrets.raw)
}

provider "vultr" {
  api_key = local.secrets.vultr.api_key
}

provider "gandi" {
  key = local.secrets.gandi.key
}

provider "minio" {
  minio_ssl        = true
  minio_server     = "s3.nichi.co"
  minio_region     = "us-east-1"
  minio_access_key = local.secrets.minio.access_key
  minio_secret_key = local.secrets.minio.secret_key
}
