#!/bin/bash
sudo apt-get update
sudo apt-get install -y unzip curl jq

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Retrieve DB Password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${db_password_secret_name} --region ${aws_region} --query SecretString --output text | tr -d '"')

# Retrieve Email Service Credentials from Secrets Manager
EMAIL_SECRET=$(aws secretsmanager get-secret-value --secret-id ${email_service_secret_name} --region ${aws_region} --query SecretString --output text)
EMAIL_USERNAME=$(echo $EMAIL_SECRET | jq -r .username)
EMAIL_PASSWORD=$(echo $EMAIL_SECRET | jq -r .password)

echo "DB_HOST=${db_host}" >> /etc/environment
echo "DB_PORT=5432" >> /etc/environment
echo "DB_NAME=${db_name}" >> /etc/environment
echo "DB_USERNAME=${db_username}" >> /etc/environment
echo "DB_PASSWORD=$DB_PASSWORD" >> /etc/environment
echo "S3_BUCKET_NAME=${s3_bucket}" >> /etc/environment
echo "AWS_REGION=${aws_region}" >> /etc/environment
echo "APP_PORT=${app_port}" >> /etc/environment

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json \
  -s

if ! systemctl is-active --quiet amazon-cloudwatch-agent; then
  echo "CloudWatch Agent failed to start" >&2
  exit 1
fi

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

sudo systemctl restart csye6225.service
