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
#	install postgresql
###########################################################################################################


echo "functions loaded..."

echo "Test that user & pass have been set"
if [[ -z "${CLDR_REPO_USER}" ]] || [[ -z "${$CLDR_REPO_PASS}" ]]; then
	log "Credentails have not been set.  Please update.  Exiting..."
	exit 1
fi

echo "begin install postgresql..."
#install_postgres

echo "database installed..."

echo
echo "install prereqs..."
#setup_prereqs