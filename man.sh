#!/bin/bash

# 1. Root user check
if [ $(id -u) -ne 0 ]; then
    echo -e "\e[31m[ERROR] Please run as root user (sudo).\e[0m"
    exit 1
fi

# 2. Setup Logs Folder
LOG_FILE="/var/log/roboshop/$(basename $0).log"
mkdir -p /var/log/roboshop

# 3. Validation function (Common for all steps)
validate() {
    if [ $1 -eq 0 ]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $2 ... \e[32mSUCCESS\e[0m" | tee -a $LOG_FILE
    else
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $2 ... \e[31mFAILURE\e[0m" | tee -a $LOG_FILE
        exit 1
    fi
}

# --- MongoDB Installation Steps ---

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copying Mongo Repo"

dnf install mongodb-org -y &>> $LOG_FILE
validate $? "Installing MongoDB"

systemctl enable --now mongod &>> $LOG_FILE
validate $? "Enabling & Starting MongoDB"

# IP ni replace cheyyadaniki direct ga standard way
sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
validate $? "Configuring Remote Access (0.0.0.0)"

systemctl restart mongod &>> $LOG_FILE
validate $? "Restarting MongoDB"