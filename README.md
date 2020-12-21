# MySQL AWS S3 バックアップ

## 前提

- ubuntu18.04  
- MySQL5.7
- `mysqldump`コマンドで出力したバックアップをS3に保存するだけのシェル

## 導入手順

### AWS側作業

1. AWSで「プログラムによるアクセス」を許可したシステム用[IAMユーザー作成](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_users_create.html)

2. 上記ユーザーの[アクセスキーを作成](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_credentials_access-keys.html)

3. S3でバックアップ用の[バケットを作成](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/user-guide/create-bucket.html)

4. 作成したバケットへのアクセス権限ポリシーを作成し、1で作成したIAMユーザーに付与する  

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::backup",
                "arn:aws:s3:::backup/*"
            ]
        }
    ]
}
```

### ubuntu側作業

1. AWS CLIインストール確認

```
$ aws --version
```

2. AWS CLIがなければインストール
```
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
```

3. AWSプロファイルの作成
```
$ aws configure --profile system_backup
  AWS Access Key ID [None]: AKIXXXXXXXXXXXXXXXX
  AWS Secret Access Key [None]: ***********************             
  Default region name [None]: ap-northeast-1
  Default output format [None]: json
```

4. 各パラメータを調整した.shを適当なところに置いて動くか確認
```
$ /bin/sh /usr/local/sbin/mysql_backup.sh
```

5. `/etc/cron.d` にcronファイル作成する
```
# m h dom mon dow user  command
# 毎日3時に実行する
0 3 * * * user /bin/sh /usr/local/sbin/mysql_backup.sh
```

6. cron設定反映
```
$ sudo service cron restart
```