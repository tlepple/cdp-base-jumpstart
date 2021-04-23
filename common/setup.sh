#!/bin/bash

###########################################################################################################
# import parameters and utility functions 
###########################################################################################################
. common/input.properties
. common/utils.sh

# logging function
log() {
    echo -e "[$(date)] [$BASH_SOURCE: $BASH_LINENO] : $*"
}

###########################################################################################################
#       install pre-reqs
###########################################################################################################

log "installing pre-reqs..."
echo
setup_prereqs

###########################################################################################################
#       install CM Repository
###########################################################################################################

log "installing CM Repository..."
echo
install_cm_repo

###########################################################################################################
#       install Java from the CM Repo
###########################################################################################################

log "installing Java..."
echo
install_java


###########################################################################################################
#	install postgresql
###########################################################################################################

log "installing postgresql for metadata services..."
echo
install_postgres

###########################################################################################################
#       install Cloudera Manager
###########################################################################################################

log "installing Cloudera Manager..."
echo
install_cm

###########################################################################################################
#      setup passwordless access for root.  *** Not recommended for production workloads **
###########################################################################################################

log "setting up passwordless access..."
echo
install_pwdless_access

###########################################################################################################
#       Start CM 
###########################################################################################################

log "starting Cloudera Manager..."
echo

systemctl start cloudera-scm-server

while [[ -z  `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version`  ]];
    do
    echo "waiting 10s for CM to come up..";
    sleep 10;
done

echo
log "CM installed"
