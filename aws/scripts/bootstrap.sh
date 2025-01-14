#!/bin/bash
#
# Run as:
# ./bootstrap.sh "AWS_REGION" "AWS_ACCOUNT" "CLUSTER_NAME" "AKS_NAMESPACE"
# ./scripts/bootstrap.sh  "eu-central-1" "105457647445" "quorum-cluster" "kube-system"
#

# Enables debugging (-x), exits on error (-e), and treats unset variables as an error (-u)
set -eux

AWS_REGION=${1:-rg}
AWS_ACCOUNT=${2:-account}
CLUSTER_NAME=${3:-cluster}
# quourum
AKS_NAMESPACE=${4:-quorum}

echo "aws get-credentials ..."
aws sts get-caller-identity
aws eks --region "${AWS_REGION}" update-kubeconfig --name "${CLUSTER_NAME}"

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install --namespace kube-system --create-namespace csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml 

# If you have deployed the above policy before, acquire its ARN:
POLICY_ARN=$(aws iam list-policies --scope Local --query 'Policies[?PolicyName==`quorum-node-secrets-mgr-policy`].Arn' --output text)

# echo policy arn value
# echo 'POLICY_ARN variable is: ' "$POLICY_ARN"

# If the policy does not exist ($? -eq 0), it creates the policy with permissions to manage secrets in AWS Secrets Manager.
if [ $? -eq 0 ] 
then
  echo "Deploy the policy"
  POLICY_ARN=$(aws --region $AWS_REGION iam create-policy --policy-name quorum-node-secrets-mgr-policy --policy-document '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "secretsmanager:CreateSecret",
            "secretsmanager:UpdateSecret",
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue",
            "secretsmanager:ReplicateSecretToRegions",
            "secretsmanager:TagResource"
          ],
          "Resource": [
            "arn:aws:secretsmanager:'"$AWS_REGION"':'"$AWS_ACCOUNT"':secret:goquorum-node-*",
            "arn:aws:secretsmanager:'"$AWS_REGION"':'"$AWS_ACCOUNT"':secret:besu-node-*"
          ]
        }
      ]
  }' --query Policy.Arn --output text)
fi

eksctl create iamserviceaccount --name quorum-sa --namespace "${AKS_NAMESPACE}" --region="${AWS_REGION}" --cluster "${CLUSTER_NAME}" --attach-policy-arn "$POLICY_ARN" --approve --override-existing-serviceaccounts
echo "Done... "
