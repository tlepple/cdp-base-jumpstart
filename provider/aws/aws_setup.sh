#!/bin/bash

PROVIDER=$1
TEMPLATE=$2
BLOCKDEVICE=$3

echo "PUBLIC_IP variable now ..."
echo
PUBLIC_IP=`curl https://api.ipify.org/`

#########################################################
# Input parameters
#########################################################

echo "Begin install into AWS Instance from the aws_setup.sh script..."

echo "Parameter PROVIDER -->" $PROVIDER
echo "Parameter TEMPLATE -->" $TEMPLATE
echo "Parameter BLOCKDEICD -->" $BLOCKDEVICE

###########################################################################################################
#time issues for clock offset in aws	
###########################################################################################################
echo "setup clock offset issues for aws"
#echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" >> /etc/chrony.conf
#systemctl restart chronyd

###########################################################################################################
# install the common items from script 
###########################################################################################################
echo "calling common setup.sh here..."
. $starting_dir/common/setup.sh $PROVIDER $TEMPLATE $BLOCKDEVICE

ECHO_PUBLICIP=`curl ifconfig.me`
echo
echo "          ---------------------------------------------------------------------------------------------------------"
echo "          ---------------------------------------------------------------------------------------------------------"
echo "          |          Service              |                       URL                                              "
echo "          ---------------------------------------------------------------------------------------------------------"
echo "          ---------------------------------------------------------------------------------------------------------"
echo "          | Cloudera Manager              |       http://$ECHO_PUBLICIP:7180                                       "
echo "          ---------------------------------------------------------------------------------------------------------"

