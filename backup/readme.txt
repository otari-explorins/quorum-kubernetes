-----------------------
create cronjob 



create docker image and copy script into in

upload docker image to dockerhub

create cron.yaml file

kubectl create secret generic aws-credentials \
  --from-literal=aws_access_key_id=xxxxxxxxxxxxxxxx \
  --from-literal=aws_secret_access_key=xxxxxxxxxxxxxxxxxxxxx \
  --namespace=quorum

kubectl apply -f besu_backup_cron.yaml



-----------------------
add service account access to cronjob




kubectl apply -f serviceaccount.yaml

kubectl apply -f role.yaml

kubectl apply -f rolebinding.yaml

kubectl apply -f besu_backup_cron.yaml

