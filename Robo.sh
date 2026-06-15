#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="YOUR_ZONE_ID"
DOMAIN_NAME="yourdomain.shop"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Validation

if [ $# -lt 2 ]; then
echo -e "${R}ERROR: Minimum 2 arguments required${N}"
echo "Usage: $0 [create|delete] [component1] [component2]"
exit 1
fi

ACTION=$1
shift

get_instance_id() {
COMPONENT=$1

```
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=roboshop-$COMPONENT" \
              "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text
```

}

for COMPONENT in $@
do
INSTANCE_ID=$(get_instance_id $COMPONENT)

```
if [ "$ACTION" == "create" ]; then

    if [ "$INSTANCE_ID" == "None" ]; then

        echo "Launching roboshop-$COMPONENT"

        INSTANCE_ID=$(aws ec2 run-instances \
            --image-id $AMI_ID \
            --instance-type t3.micro \
            --security-groups roboshop-common \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$COMPONENT}]" \
            --query 'Instances[0].InstanceId' \
            --output text)

        echo "Created Instance: $INSTANCE_ID"

        aws ec2 wait instance-running \
            --instance-ids $INSTANCE_ID

        echo "Instance Running"

    else
        echo "roboshop-$COMPONENT already running: $INSTANCE_ID"
    fi

elif [ "$ACTION" == "delete" ]; then

    if [ "$INSTANCE_ID" == "None" ]; then
        echo "roboshop-$COMPONENT already deleted"

    else
        aws ec2 terminate-instances \
            --instance-ids $INSTANCE_ID

        echo "Terminated roboshop-$COMPONENT"
    fi

fi
```

done
