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
MYSQL_HOST=mysql.heman.icu
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


dnf install maven -y &>>$LOGS_FILE
VALIDATE $? "Install Maven"

if ! id roboshop &>>"$LOGS_FILE"; then
    useradd --system --home /app --shell /sbin/nologin \
        --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Add application User"
else
    echo -e "$Y Already Roboshop user exists ...$N Skipping" | tee -a "$LOGS_FILE"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "setup an app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGS_FILE
VALIDATE $? "Download the application code"

cd /app 
VALIDATE $? "Move to app directory"

rm -rf /app/*
VALIDATE $? "Application files may already exist"

unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "Unzip the shipping code" 

mvn clean package &>>$LOGS_FILE
VALIDATE $? "download the dependencies" 

mv target/shipping-1.0.jar shipping.jar &>>$LOGS_FILE
VALIDATE $? "Moveing shipping jar to current dir" 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGS_FILE
VALIDATE $? "Setup SystemD shipping Service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Load the shipping service"

systemctl enable shipping &>>$LOGS_FILE
VALIDATE $? "enable the shipping service"

systemctl start shipping &>>$LOGS_FILE
VALIDATE $? "Start the shipping service"


dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "install mysql client"


mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 -e "USE cities;" &>>"$LOGS_FILE"

if [ $? -ne 0 ]; then
    echo "Database 'cities' not found. Creating..."

    mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 -e "CREATE DATABASE IF NOT EXISTS cities;" &>>"$LOGS_FILE"
    VALIDATE $? "Create cities database"

    mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 cities < /app/db/schema.sql &>>"$LOGS_FILE"
    VALIDATE $? "Load schema to database"

    mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 cities < /app/db/app-user.sql &>>"$LOGS_FILE"
    VALIDATE $? "Create application user"

    mysql -h "$MYSQL_HOST" -uroot -pRoboShop@1 cities < /app/db/master-data.sql &>>"$LOGS_FILE"
    VALIDATE $? "Load master data"
else
    echo -e "$Y Already loaded schema to the Database...$N Skipping" | tee -a "$LOGS_FILE"
fi

systemctl restart shipping &>>$LOGS_FILE
VALIDATE $? "Restart the shipping service"