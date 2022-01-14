#!/bin/bash
  
echo "Running ledger production daily database rebuild.";

if [ $TEMPORARY_LEDGER_DATABASE ==  'ledger_prod' ]; then
        echo "ledger_prod can not be a TEMPORARY Database";
        exit;
fi

echo "Dumping Production Database";
pg_dump "host=$PRODUCTION_LEDGER_HOST port=5432 dbname=$PRODUCTION_LEDGER_DATABASE user=$PRODUCTION_LEDGER_USERNAME password=$PRODUCTION_LEDGER_PASSWORD sslmode=require"  > /dbdumps/ledger_prod.sql

# DROP All TABLES IN DAILY DB
for I in $(psql "host=$TEMPORARY_LEDGER_HOST port=5432 dbname=$TEMPORARY_LEDGER_DATABASE user=$TEMPORARY_LEDGER_USERNAME password=$TEMPORARY_LEDGER_PASSWORD sslmode=require" -c "SELECT tablename FROM pg_tables" -t);
  do
  echo " drop table $I CASCADE; ";
  psql "host=$TEMPORARY_LEDGER_HOST port=5432 dbname=$TEMPORARY_LEDGER_DATABASE user=$TEMPORARY_LEDGER_USERNAME password=$TEMPORARY_LEDGER_PASSWORD sslmode=require" -c "drop table $I CASCADE;" -t
done

# IMPORT LEDGER PROD DATABASE INTO DAILY
echo "Importing Ledger prod into ledger daily database";
psql "host=$TEMPORARY_LEDGER_HOST port=5432 dbname=$TEMPORARY_LEDGER_DATABASE user=$TEMPORARY_LEDGER_USERNAME password=$TEMPORARY_LEDGER_PASSWORD sslmode=require" < /dbdumps/ledger_prod.sql
