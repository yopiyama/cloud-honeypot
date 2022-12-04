# Cloud Honeypot

AWS でサクッとハニーポットを立ててみるためのリポジトリ

## 使用する主なサービス

- Amazon ECS
- Amazon S3

## 利用するハニーポット

- [Cowrie](https://github.com/cowrie/cowrie)
- [mysql-honeypotd](https://github.com/sjinks/mysql-honeypotd)

## Installation

利用したい場合に追加・修正などするべき箇所

- AWS アカウントの用意と作業に必要な権限がある IAM User の AcessKeyID, SecretAccessKey の取得
- terraform/terraform.tfvars を作成し以下の変数を定義
  - account_id
    - リソースの配置される AWS の Accound ID
  - os_endpoint
    - 分析用の Amazon OpenSearch Serverless のドメイン
- tfstate を保存するためのバケットを手で作成
- backend.conf.sample を backend.conf へ改名し、ファイル中の bucket の値を作成したバケット名で置き換える
- terraform/log_dest.tf の aws_s3_bucket.log-bucket.bucket を任意の値に変更
- OpenSearch Serverless の構築
  - parser-lambda-role からのログ書き込みを許可する Data access policies を作成

```sh
cd terraform
terraform init -backend-config=backend.conf
terraform plan

terraform apply
```
