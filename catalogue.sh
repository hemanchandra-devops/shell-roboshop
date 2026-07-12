#!/bin/bash

set -euo pipefail

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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disable current module"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enable required module"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install NodeJS"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ];then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Add application User"
else
    echo -e "$Y Already Roboshop user exists ...$N Skipping" | tee -a $LOGS_FILE
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "setup an app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Download the application code"

cd /app 
VALIDATE $? "Move to app directory"

rm -rf /app/*
VALIDATE $? "Application files may already exist"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Unzip the catalogue code" 

npm install &>>$LOGS_FILE
VALIDATE $? "Download the dependencies" 

cp catalogue.service /etc/systemd/system/catalogue.service &>>$LOGS_FILE
VALIDATE $? "Setup SystemD Catalogue Service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Load the catalogue service"

systemctl enable catalogue &>>$LOGS_FILE
VALIDATE $? "enable the catalogue service"

systemctl start catalogue &>>$LOGS_FILE
VALIDATE $? "Start the catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "setup MongoDB repo service"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "install mongodb-client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
VALIDATE $? "Load Master Data of the List of products"

systemctl restart catalogue &>>$LOGS_FILE
VALIDATE $? "Restart the catalogue service"