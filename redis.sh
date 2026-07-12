#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m" 
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
mkdir -p $LOGS_FOLDER
SCRIPIT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPIT_NAME.log"

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

dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "Diable default redis"

dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "enable redis 7 version "

dnf install redis -y  &>>$LOGS_FILE
VALIDATE $? "Install Redis"

systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "Enable redis"

systemctl start redis &>>$LOGS_FILE
VALIDATE $? "Start redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/c protected-mode no' /etc/redis/redis.conf &>>$LOGS_FILE
VALIDATE $? "Update listen address"

systemctl restart redis &>>$LOGS_FILE
VALIDATE $? "Restart the redis service"