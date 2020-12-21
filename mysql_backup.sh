#!/bin/sh

# パラメータここから↓

# AWSプロファイル名
export AWS_PROFILE=system_backup

# aws コマンドをフルパス指定（cronだとパスが通っていない場合があるため）
# $which aws で出る
AWS_COMMAND="/usr/local/bin/aws"

# DB情報
DBHOST=localhost
DBUSER=user
DBPASSWORD=password
DATABASES="test" # スペース区切りで複数指定可

# 一時的に出力するbackupfileの場所
# パーミッションをつけておくこと
SCRIPT_DIR=$(cd $(dirname $0); pwd)
BACKUP_DIR=$SCRIPT_DIR/backup

# バックアップファイル名の先頭文字列
# 最終的にS3には以下の形で格納される
# yyyyMMdd/[PREFIX]_[DB名]_[yyyyMMdd].sql.gz
PREFIX=database_backup

# s3バケット名
REMOTE_BACKUP_DIR=s3://backup

# 保持日数
KEEP_DAYS=7

# パラメータここまで↑

TODAY=$(date "+%Y%m%d")

# バックアップとS3へのアップロード
for database in $DATABASES
do
  FILE_NAME=${PREFIX}_${database}
  BK_FILE_PATH=${BACKUP_DIR}/${FILE_NAME}_${TODAY}.sql.gz
  echo "exporting $database"
  mysqldump -u ${DBUSER} -p${DBPASSWORD} --lock-tables=false -h ${DBHOST}  ${database}  | gzip > $BK_FILE_PATH
  echo "done exporting"

  echo "uploading $BK_FILE_PATH to $REMOTE_BACKUP_DIR/${TODAY}"
  ${AWS_COMMAND} s3 cp ${BK_FILE_PATH} $REMOTE_BACKUP_DIR/${TODAY}/ --acl private
  echo "done upload"
done

# バックアップ端末上のバックアップファイルを削除
find ${BACKUP_DIR}/*.sql.gz -mtime +1 -exec rm -f {} \;

# AWS上のファイル削除
DELETE_DAY=`date '+%Y%m%d' --date "${KEEP_DAYS} days ago"`
${AWS_COMMAND} s3 rm $REMOTE_BACKUP_DIR/${DELETE_DAY} --recursive