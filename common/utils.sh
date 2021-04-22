#!/bin/bash

#####################################################
# Function to install passwordless access to hosts
#####################################################
install_pwdless_access() {

	echo "-- Enable passwordless root login via rsa key"
	ssh-keygen -f ~/myRSAkey -t rsa -N ""
	mkdir ~/.ssh
	cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
	chmod 400 ~/.ssh/authorized_keys
	ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
	sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
	systemctl restart sshd

}

#####################################################
# Function to install jq
#####################################################
install_jq_cli() {

	#####################################################
	# first check if JQ is installed
	#####################################################
	echo "Installing jq"
	yum install -y unzip

	jq_v=`jq --version 2>&1`
	if [[ $jq_v = *"command not found"* ]]; then
	  curl -L -s -o jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
	  chmod +x ./jq
	  cp jq /usr/bin
	else
	  echo "jq already installed. Skipping"
	fi

	jq_v=`jq --version 2>&1`
	if [[ $jq_v = *"command not found"* ]]; then
	  #log "error installing jq. Please see README and install manually"
	  echo "Error installing jq. Please see README and install manually"
	  exit 1 
	fi  

}

#####################################################
# Function to install aws cli
#####################################################

install_aws_cli() {

	#########################################################
	# BEGIN
	#########################################################
	echo "BEGIN setup.sh"
	yum install -y unzip


	#####################################################
	# first check if JQ is installed
	#####################################################
	echo "Installing jq"

        jq_v=`jq --version 2>&1`
        if [[ $jq_v = *"command not found"* ]]; then
          curl -L -s -o jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
          chmod +x ./jq
          cp jq /usr/bin
        else
          echo "jq already installed. Skipping"
        fi

        jq_v=`jq --version 2>&1`
        if [[ $jq_v = *"command not found"* ]]; then
          echo "Error installing jq. Please see README and install manually"
          exit 1
        fi

	#####################################################
 	# then install AWS CLI
	#####################################################
  	echo "Installing AWS_CLI"
#  	aws_cli_version=`aws --version 2>&1`
#  	echo "Current CLI version: $aws_cli_version"
#  	if [[ $aws_cli_version = *"aws-cli"* ]]; then
#    		echo "AWS CLI already installed. Skipping"
#    		return
#  	fi
  		curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  		unzip awscliv2.zip
  		./aws/install -i /usr/local/aws-cli -b /usr/local/bin 
  		rm -rf awscliv2*
  	echo "Done installing AWS CLI"

}

#####################################################
# Function to install postgres database
#####################################################

install_postgres() {
	# set location variables info
	https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/
	PG_REPO_URL="https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
	PG_HOME_DIR="/var/lib/pgsql/11"

	#############################################
	## Install Postgresql repo for Redhat
	#############################################
	yum -y install $PG_REPO_URL

        #############################################
        ## Install the database
        #############################################
	yum -y install postgresql11-server postgresql11-contrib postgresql11 postgresql-jdbc*

        #############################################
        ## setup jdbc connectors
        #############################################
	cp /usr/share/java/postgresql-jdbc.jar /usr/share/java/postgresql-connector-java.jar
	chmod 644 /usr/share/java/postgresql-connector-java.jar

        #############################################
        ## setup database to use UTF-8
        #############################################
	echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf

        #############################################
        ## Initialize Postgres
        #############################################
	/usr/pgsql-11/bin/postgresql-11-setup initdb

        #############################################
        ## Enable & Start Postgres
        #############################################
	systemctl enable postgresql-11
	systemctl start postgresql-11

        #############################################
        ## configure database conf items
        #############################################
	echo "setup some conf items..."
	echo
	# allow listender from any host
	sed -e 's,#listen_addresses = \x27localhost\x27,listen_addresses = \x27*\x27,g' -i $PG_HOME_DIR/data/postgresql.conf

	# Increase number of connections
	sed -e 's,max_connections = 100,max_connections = 300,g' -i  $PG_HOME_DIR/data/postgresql.conf

	#############################################
        ## Save the original & replace with a new pg_hba.conf
        #############################################
	echo "backup pg_hba.conf"
	echo
	mv $PG_HOME_DIR/data/pg_hba.conf $PG_HOME_DIR/data/pg_hba.conf.orig

	cat <<EOF > $PG_HOME_DIR/data/pg_hba.conf
  # TYPE  DATABASE        USER            ADDRESS                 METHOD
  local   all             all                                     peer
  host    scm             scm            0.0.0.0/0                md5
  host    das             das            0.0.0.0/0                md5
  host    hive            hive           0.0.0.0/0                md5
  host    hue             hue            0.0.0.0/0                md5
  host    oozie           oozie          0.0.0.0/0                md5
  host    ranger          rangeradmin    0.0.0.0/0                md5
  host    rman            rman           0.0.0.0/0                md5
  host    hbase           hbase          0.0.0.0/0                md5
  host    phoenix         phoenix        0.0.0.0/0                md5  
  host    registry        registry       0.0.0.0/0                md5
  host    streamsmsgmgr   streamsmsgmgr  0.0.0.0/0                md5
  host    nifireg         nifireg        0.0.0.0/0                md5
  host    efm             efm            0.0.0.0/0                md5
  host    datagen         datagen        0.0.0.0/0                md5
EOF

	#############################################
	# Set permissions on this new file
	#############################################
	chown postgres:postgres $PG_HOME_DIR/data/pg_hba.conf
	chmod 600 $PG_HOME_DIR/data/pg_hba.conf


	#############################################
	# restart postgresql
	#############################################
	echo "restart the database..."
	echo
	systemctl restart postgresql-11

 	#############################################
        # Create DDL for needed databases
        #############################################
	echo "create the ddl script ..."
	echo
	cat <<EOF > ~/create_ddl_c714.sql
CREATE ROLE das LOGIN PASSWORD 'supersecret1';
CREATE ROLE hive LOGIN PASSWORD 'supersecret1';
CREATE ROLE hue LOGIN PASSWORD 'supersecret1';
CREATE ROLE oozie LOGIN PASSWORD 'supersecret1';
CREATE ROLE rangeradmin LOGIN PASSWORD 'supersecret1';
CREATE ROLE rman LOGIN PASSWORD 'supersecret1';
CREATE ROLE scm LOGIN PASSWORD 'supersecret1';
CREATE ROLE hbase LOGIN PASSWORD 'supersecret1';
CREATE ROLE phoenix LOGIN PASSWORD 'supersecret1';
CREATE ROLE registry LOGIN PASSWORD 'supersecret1';
CREATE ROLE streamsmsgmgr LOGIN PASSWORD 'supersecret1';
CREATE ROLE nifireg LOGIN PASSWORD 'supersecret1';
CREATE ROLE efm LOGIN PASSWORD 'supersecret1';
CREATE ROLE datagen LOGIN PASSWORD 'supersecret1';
CREATE DATABASE das OWNER das ENCODING 'UTF-8';
CREATE DATABASE hive OWNER hive ENCODING 'UTF-8';
CREATE DATABASE hue OWNER hue ENCODING 'UTF-8';
CREATE DATABASE oozie OWNER oozie ENCODING 'UTF-8';
CREATE DATABASE ranger OWNER rangeradmin ENCODING 'UTF-8';
CREATE DATABASE rman OWNER rman ENCODING 'UTF-8';
CREATE DATABASE scm OWNER scm ENCODING 'UTF-8';
CREATE DATABASE hbase OWNER hbase ENCODING 'UTF-8';
CREATE DATABASE phoenix OWNER phoenix ENCODING 'UTF-8';
CREATE DATABASE registry OWNER registry ENCODING 'UTF-8';
CREATE DATABASE streamsmsgmgr OWNER streamsmsgmgr ENCODING 'UTF-8';
CREATE DATABASE nifireg OWNER nifireg ENCODING 'UTF-8';
CREATE DATABASE efm OWNER efm ENCODING 'UTF-8';
CREATE DATABASE datagen OWNER datagen ENCODING 'UTF-8';
EOF


	#############################################
        # run the file
        #############################################
	echo "run the DDL ..."
	echo
	sudo -u postgres psql <~/create_ddl_c714.sql


	echo "install script complete..."
	echo

}

#####################################################
# Function to OS requirements
#####################################################

setup_prereqs() {
	echo "install --> wget, epel-release, python-pip"
	yum install -y wget epel-release python-pip
	echo

	echo "check status of selinux..."
	echo
	SELINUX_STATUS=`getenforce`
	echo "SELINUX is currently --> " $SELINUX_STATUS
	if 
		[ getenforce != Disabled ]
	then  
		setenforce 0;
		sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
	fi
	
	echo
	echo "SELINUX is currently --> " getenforce

	echo
	echo "setup timezone info ..."
	
	# the varialbe LOCAL_TIMEZONE is set from the file input.properties
	ln -sf /usr/share/zoneinfo/$LOCAL_TIMEZONE /etc/localtime

	echo
	echo "turn off swappiness ..."
	sysctl vm.swappiness=10
	echo "vm.swappiness = 10" >> /etc/sysctl.conf
	echo

	# turn off Transparent Huge pages
	echo "turn off Transparent Huge pages ..."
	echo never > /sys/kernel/mm/transparent_hugepage/defrag
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo

	echo "install rng-tools ..."
	yum -y install rng-tools
	cp /usr/lib/systemd/system/rngd.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl start rngd
	echo



	echo "prereqs installed ..."
	echo

}

#####################################################
# Function to install java JDK
#####################################################

install_java() {
	echo
	echo "Check if java installed"
	echo
	echo "Install Java JDK"
	# values for JDK_RPM_URL are set in file input.properties
#	rpm -ivh $JDK_RPM_URL
}

#####################################################
# Function to install Cloudera Manager Repo
#####################################################

install_cm_repo() {
	# the value for $CLDR_MGR_VER_URL is set in input.properties file
	#wget $CLDR_MGR_VER_URL/cloudera-manager-trial.repo -P /etc/yum.repos.d/
	wget $CLDR_MGR_VER_URL/cloudera-manager.repo -P /etc/yum.repos.d/
	##################################################################################################
	# Update the UserName and PWD in the repo here for paywall from values set in input.properties
	##################################################################################################
sed -i "s/username=changeme/username=$CLDR_REPO_USER/g" /etc/yum.repos.d/cloudera-manager.repo
sed -i "s/password=changeme/password=$CLDR_REPO_PASS/g" /etc/yum.repos.d/cloudera-manager.repo

	
}


