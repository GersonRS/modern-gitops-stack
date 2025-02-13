resource "random_password" "loki_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "thanos_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "mlflow_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "jupyterhub_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "airflow_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "pinot_secretkey" {
  length  = 32
  special = false
}
resource "random_password" "trino_secretkey" {
  length  = 32
  special = false
}

locals {
  minio_config = {
    policies = [
      {
        name = "loki-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::loki"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::loki/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "thanos-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::thanos"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::thanos/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "mlflow-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::mlflow"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::mlflow/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "jupyterhub-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::mlflow"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::mlflow/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "airflow-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::airflow"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::airflow/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "pinot-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::pinot"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::pinot/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "trino-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::trino"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::trino/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      }
    ],
    users = [
      {
        accessKey = "loki-user"
        secretKey = random_password.loki_secretkey.result
        policy    = "loki-policy"
      },
      {
        accessKey = "thanos-user"
        secretKey = random_password.thanos_secretkey.result
        policy    = "thanos-policy"
      },
      {
        accessKey = "mlflow-user"
        secretKey = random_password.mlflow_secretkey.result
        policy    = "mlflow-policy"
      },
      {
        accessKey = "airflow-user"
        secretKey = random_password.airflow_secretkey.result
        policy    = "airflow-policy"
      },
      {
        accessKey = "jupterhub-user"
        secretKey = random_password.jupyterhub_secretkey.result
        policy    = "jupterhub-policy"
      },
      {
        accessKey = "pinot-user"
        secretKey = random_password.pinot_secretkey.result
        policy    = "pinot-policy"
      },
      {
        accessKey = "trino-user"
        secretKey = random_password.trino_secretkey.result
        policy    = "trino-policy"
      }
    ],
    buckets = [
      {
        name = "loki"
      },
      {
        name = "thanos"
      },
      {
        name = "mlflow"
      },
      {
        name = "airflow"
      },
      {
        name = "pinot"
      },
      {
        name = "trino"
      },
      {
        name = "registry"
      },
      {
        name = "landing"
      },
      {
        name = "processing"
      },
      {
        name = "curated"
      },
      {
        name = "warehouse"
      },
      {
        name = "bronze"
      },
      {
        name = "silver"
      },
      {
        name = "gold"
      }
    ]
  }
}
