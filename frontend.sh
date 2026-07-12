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

dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "Disable default Nginx"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enable Nginx 1.24 version"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Install Nginx"

systemctl enable nginx &>>$LOGS_FILE
VALIDATE $? "Enable Nginx" 

systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "Start Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE
VALIDATE $? "Remove default html code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "Download frontend code"

cd /usr/share/nginx/html &>>$LOGS_FILE
VALIDATE $? "Move to the nginx htlm dir"

unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "Unzip the frontend code"

cp $SCRIPT_DIR/nginx.conf  /etc/nginx/nginx.conf &>>$LOGS_FILE
VALIDATE $? "Create Nginx Reverse Proxy Configuration"

systemctl restart nginx &>>$LOGS_FILE
VALIDATE $? "Restart nginx"