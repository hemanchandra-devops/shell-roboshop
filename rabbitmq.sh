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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOGS_FILE
VALIDATE $? "Setup the Rabbitmq repo file"

dnf install rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "Install RabbitMQ"

systemctl enable rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "Enable RabbitMQ Service"

systemctl start rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "Start RabbitMQ Service"

if ! rabbitmqctl list_users | grep -q roboshop; then
    rabbitmqctl add_user roboshop roboshop123 &>>"$LOGS_FILE"
    VALIDATE $? "create one user for the application"

    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>"$LOGS_FILE"
    VALIDATE $? "Set permissions for user"
else
    echo -e "$Y Already Roboshop RabbitMQ user exists ...$N Skipping" | tee -a "$LOGS_FILE"
fi


systemctl restart rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "Restart the RabbitMQ service"