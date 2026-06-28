terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
}

variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

output "id" {
  value = scaleway_object_bucket.main.id
}

output "name" {
  value = var.name
}

output "region" {
  value = var.region
}

resource "scaleway_object_bucket" "main" {
  project_id = var.project_id

  name   = var.name
  region = var.region

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1

    noncurrent_version_expiration {
      noncurrent_days = 15
    }
  }
}

resource "scaleway_object_bucket_acl" "main" {
  project_id = var.project_id

  bucket = scaleway_object_bucket.main.id
  acl    = "private"
}

# FIXME: set IAM key preferred project to storage
# https://github.com/scaleway/terraform-provider-scaleway/issues/3985
resource "scaleway_object_bucket_server_side_encryption_configuration" "main" {
  bucket = var.name
  region = var.region

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
