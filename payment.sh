#!/bin/bash

set -e

R="\e[31m"
G="\e[32m"
Y="\e[33m" 
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
mkdir -p $LOGS_FOLDER
SCRIPIT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPIT_NAME.log"
MONGODB_HOST=mongodb.heman.icu
SCRIPT_DIR=$PWD

echo "Script started executed at : $(date)" | tee -a $LOGS_FILE

USERID=$(id -u)

if [ $USERID -ne 0 ];then
    echo -e "$R Please run this script with Root Access! $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ];then
        echo -e "$R $2 ... $N Failure" | tee -a $LOGS_FILE
        exit 1
    else 
        echo -e "$G $2 ... $N Success" | tee -a $LOGS_FILE
    fi
}


dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Install Python 3"

if ! id roboshop &>>"$LOGS_FILE"; then
    useradd --system --home /app --shell /sbin/nologin \
        --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Add application User"
else
    echo -e "$Y Already Roboshop user exists ...$N Skipping" | tee -a "$LOGS_FILE"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "setup an app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "Download the application code"

cd /app 
VALIDATE $? "Move to app directory"

rm -rf /app/*
VALIDATE $? "Application files may already exist"

unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Unzip the payment code" 

npm install &>>$LOGS_FILE
VALIDATE $? "Download the dependencies" 

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE
VALIDATE $? "Setup SystemD payment Service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Load the payment service"

systemctl enable payment &>>$LOGS_FILE
VALIDATE $? "enable the payment service"

systemctl start payment &>>$LOGS_FILE
VALIDATE $? "Start the payment service"

systemctl restart payment &>>$LOGS_FILE
VALIDATE $? "Restart the payment service"