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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disable current module"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enable required module"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install NodeJS"

if ! id roboshop &>>"$LOGS_FILE"; then
    useradd --system --home /app --shell /sbin/nologin \
        --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Add application User"
else
    echo -e "$Y Already Roboshop user exists ...$N Skipping" | tee -a "$LOGS_FILE"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "setup an app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOGS_FILE
VALIDATE $? "Download the application code"

cd /app 
VALIDATE $? "Move to app directory"

rm -rf /app/*
VALIDATE $? "Application files may already exist"

unzip /tmp/user.zip &>>$LOGS_FILE
VALIDATE $? "Unzip the user code" 

npm install &>>$LOGS_FILE
VALIDATE $? "Download the dependencies" 

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOGS_FILE
VALIDATE $? "Setup SystemD user Service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Load the user service"

systemctl enable user &>>$LOGS_FILE
VALIDATE $? "enable the user service"

systemctl start user &>>$LOGS_FILE
VALIDATE $? "Start the user service"

systemctl restart user &>>$LOGS_FILE
VALIDATE $? "Restart the user service"