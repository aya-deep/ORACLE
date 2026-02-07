#!/bin/bash

###############################################################################
# Script Name   : base_install.sh
# Description   : Installation of Oracle database 19
# Author        : Allali Ayoub
# Created       : 2026-02-07
# Version       : 1.0
# Usage         : sudo ./install_oracle.sh oracle_sid
###############################################################################

user_name=$(whoami)
if [[ $user_name != "oracle" ]]; then
	echo "To install a database on this server, you need to use the oracle user !"
	exit 1
fi

usage() {
    echo "Usage: $0 <DB_NAME> <SID>"
    echo ""
    echo "Description:"
    echo "  This script take the database name and the oracle sid of the base."
    echo ""
    echo "Arguments:"
	echo "  <SID>    SID of the new database"
    echo "  <DB_NAME>    DB_NAME of the new database"
    echo ""
    echo "Exemple:"
    echo "  $0 ORCL ORCL"
}

if [[ $# -ne 2 ]]; then
	usage
	exit 1
else 
	oracle_db_name="$1"
	oracle_sid="$2"
fi

base_installation() {
	dbca -silent \
	  -createDatabase \
	  -gdbname "$oracle_db_name" \
	  -sid "$oracle_sid" \
	  -responseFile NO_VALUE \
	  -characterSet AL32UTF8 \
	  -sysPassword MonPassSys123 \
	  -systemPassword MonPassSys123 \
      -createAsContainerDatabase false \
	  -recoveryAreaSize 2048 \
	  -enableArchive true \
	  -createListener lstnr \
	  -automaticMemoryManagement true \
	  -totalMemory 2048 \ 
	  -emConfiguration DBEXPRESS -omsPort 5500
}

main() {
	base_installation
}

main



