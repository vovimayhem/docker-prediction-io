#! /bin/bash
echo "Initialization file at:";
echo " - [compose-project]/volumes/postgres/docker-entrypoint-initdb.d/03_create_project_databases.sh";
echo "Operation: CREATING PROJECT DATABASES";

gosu postgres postgres --single <<-EOSQL
   CREATE DATABASE prediction_io_example;
EOSQL

echo "";
echo "PROJECT DATABASES CREATED";
