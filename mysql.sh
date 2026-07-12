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

dnf install mysql-server -y &>>$LOGS_FILE
VALIDATE $? "Install MySQL Server"

systemctl enable mysqld &>>$LOGS_FILE
VALIDATE $? "Start MySQL Service"

systemctl start mysqld &>>$LOGS_FILE
VALIDATE $? "Start MySQL Service"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOGS_FILE
VALIDATE $? "Setup Mysql Root Password"

systemctl restart mysqld &>>$LOGS_FILE
VALIDATE $? "Restart the MySQL service"