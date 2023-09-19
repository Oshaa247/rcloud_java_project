#!/bin/bash

# Update package repository
sudo apt update -y

# Install Java and Tomcat
sudo apt install openjdk-8-jdk tomcat9 -y

sudo cp -r /usr/share/tomcat9-admin/* /var/lib/tomcat9/webapps/ -v

# Start Tomcat
sudo systemctl start tomcat9

# Enable Tomcat to start on boot
sudo systemctl enable tomcat9
