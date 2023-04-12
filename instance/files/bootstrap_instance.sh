#!/usr/bin/sh

sleep 3

INSTANCE_ID=`ec2-metadata  --instance-id | cut -d' ' -f2`
PUBLIC_IPV4=`ec2-metadata  --public-ipv4 | cut -d' ' -f2`
UNIQ_ID=`ec2-metadata --tags | grep uniq_id | xargs | cut -d' ' -f2` 
UNIQ_PREFIX=`ec2-metadata --tags | grep uniq_prefix | xargs | cut -d' ' -f2` 

USERNAME=`aws ssm get-parameter --name "/$UNIQ_PREFIX/username" | jq -r '.Parameter.Value'`
PASSWORD=`aws ssm get-parameter --name "/$UNIQ_PREFIX/cred" | jq -r '.Parameter.Value'`
KEY_PARAM=`echo "$UNIQ_PREFIX" | rev | cut -d '-' -f2- | rev`
KEY_PARAM="${KEY_PARAM}-key"
KEY=`aws ssm get-parameter --name "$KEY_PARAM" | jq -r '.Parameter.Value'`

aws ssm put-parameter --name "/$UNIQ_PREFIX/ip" --overwrite --value "$PUBLIC_IPV4"

useradd $USERNAME
usermod -a -G wheel $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

SUSS="suspicious-user"
useradd $SUSS -user
usermod -a -G wheel $SUSS
mkdir /home/$SUSS/.ssh
echo "$KEY" > /home/$SUSS/.ssh/authorized_keys

