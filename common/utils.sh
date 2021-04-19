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

	####################################################
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
	PG_REPO_URL="https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm"
	PG_HOME_DIR="/var/lib/pgsql/11.2"

	#############################################
	## Install Postgresql repo for Redhat
	#############################################
	yum -y install $PG_REPO_URL

        #############################################
        ## Install the database
        #############################################
	yum -y install postgresql112-server postgresql112-contrib postgresql112 postgresql-jdbc*

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
	systemctl enable postgresql-11.2
	systemctl start postgresql-11.2

        #############################################
        ## configure database conf items
        #############################################
	# allow listender from any host
	sed -e 's,#listen_addresses = \x27localhost\x27,listen_addresses = \x27*\x27,g' -i $PG_HOME_DIR/data/postgresql.conf

	# Increase number of connections
	sed -e 's,max_connections = 100,max_connections = 300,g' -i  $PG_HOME_DIR/data/postgresql.conf

	#############################################
        ## Save the original & replace with a new pg_hba.conf
        #############################################
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
	systemctl restart postgresql-11.2

	echo "Database installed...."
	echo

}
