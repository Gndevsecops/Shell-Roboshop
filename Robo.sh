#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z01935802ILD7QQWZXDDI"
DOMAIN_NAME="gnyadav.shop"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $# -lt 2 ]; then
    echo -e "${R}ERROR: Minimum 2 arguments required${N}"
    echo "Usage: $0 [create|delete] [component1] [component2]"
    exit 1
fi

ACTION=$1
shift

if [[ "$ACTION" != "create" && "$ACTION" != "delete" ]]; then
    echo -e "${R}ERROR: First argument must be create or delete${N}"
    exit 1
fi

get_instance_id() {
    local name=$1

    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=roboshop-$name" \
                  "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text
}

for instance in "$@"
do
    INSTANCE_ID=$(get_instance_id "$instance")

    if [[ "$ACTION" == "create" ]]; then

        if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then

            echo "Launching Instance: roboshop-$instance"

            INSTANCE_ID=$(aws ec2 run-instances \
                --image-id "$AMI_ID" \
                --instance-type t3.micro \
                --security-groups roboshop-common \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
                --query 'Instances[0].InstanceId' \
                --output text)

            if [ $? -ne 0 ]; then
                echo -e "${R}Failed to create instance${N}"
                exit 1
            fi

            echo "Launched Instance: $INSTANCE_ID"

            aws ec2 wait instance-running \
                --instance-ids "$INSTANCE_ID"

            echo "Instance is running: $INSTANCE_ID"

        else
            echo "roboshop-$instance already running: $INSTANCE_ID"
        fi

    else

        if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then
            echo "roboshop-$instance already destroyed"
        else
            aws ec2 terminate-instances \
                --instance-ids "$INSTANCE_ID"

            echo "Terminating Instance: roboshop-$instance"
        fi

    fi
done