#!/bin/bash

###########################################################################################################
# import parameters and utility functions 
###########################################################################################################
. utils.sh

###########################################################################################################
#	install postgresql
###########################################################################################################
echo "functions loaded..."

echo "begin install postgresql..."
install_postgres

echo "database installed..."
