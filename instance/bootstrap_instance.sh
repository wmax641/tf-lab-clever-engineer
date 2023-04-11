aws ec2 wait instance-running

sleep 2

INSTANCE_ID=`ec2-metadata  --instance-id | cut -d' ' -f2`
PUBLIC_IPV4=`ec2-metadata  --public-ipv4 | cut -d' ' -f2`
UNIQ_ID=`ec2-metadata --tags | grep uniq_id | xargs | cut -d' ' -f2` 
UNIQ_PREFIX=`ec2-metadata --tags | grep uniq_prefix | xargs | cut -d' ' -f2` 

USERNAME=`aws ssm get-parameter --name "/$UNIQ_PREFIX/username" | jq -r '.Parameter.Value'`
PASSWORD=`aws ssm get-parameter --name "/$UNIQ_PREFIX/cred" | jq -r '.Parameter.Value'`
aws ssm put-parameter --name "/$UNIQ_PREFIX/ip" --overwrite --value "$PUBLIC_IPV4"

sleep 1

sed -i -e '/^PasswordAuthentication/d' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "Banner /etc/banner" >> /etc/ssh/sshd_config

useradd $USERNAME
usermod -a -G wheel $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

sleep 1

systemctl restart sshd

