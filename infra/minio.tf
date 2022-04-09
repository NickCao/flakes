resource "minio_s3_bucket" "offsite" {
  bucket = "offsite"
  acl    = "private"
}

resource "minio_s3_bucket" "pastebin" {
  bucket = "pastebin"
  acl    = "private"
}

resource "minio_iam_user" "meow" {
  name = "meow"
}

data "minio_iam_policy_document" "meow" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::pastebin/*",
    ]
  }
}

resource "minio_iam_policy" "meow" {
  name   = "meow"
  policy = data.minio_iam_policy_document.meow.json
}

resource "minio_iam_user_policy_attachment" "meow" {
  policy_name = minio_iam_policy.meow.name
  user_name   = minio_iam_user.meow.name
}
