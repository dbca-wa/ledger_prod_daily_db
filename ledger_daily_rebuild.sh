#!/bin/bash
  
echo "Running ledger production daily database rebuild.";

if [ $TEMPORARY_LEDGER_DATABASE ==  'ledger_prod' ]; then
        echo "ERROR: ledger_prod can not be a TEMPORARY Database";
        exit;
fi

echo "Dumping Production Database";
pg_dump "host=$PRODUCTION_LEDGER_HOST port=5432 dbname=$PRODUCTION_LEDGER_DATABASE user=$PRODUCTION_LEDGER_USERNAME password=$PRODUCTION_LEDGER_PASSWORD sslmode=require"  > /dbdumps/ledger_prod.sql

# Build Ledger SQL Dump with out reversion
pg_dump -T reversion_revision -T  reversion_version  "host=$PRODUCTION_LEDGER_HOST port=5432 dbname=$PRODUCTION_LEDGER_DATABASE user=$PRODUCTION_LEDGER_USERNAME password=$PRODUCTION_LEDGER_PASSWORD sslmode=require"  > /dbdumps/ledger_prod_no_reversion.sql
pg_dump -t reversion_revision -t  reversion_version  "host=$PRODUCTION_LEDGER_HOST port=5432 dbname=$PRODUCTION_LEDGER_DATABASE user=$PRODUCTION_LEDGER_USERNAME password=$PRODUCTION_LEDGER_PASSWORD sslmode=require"  >> /dbdumps/ledger_prod_no_reversion.sql

# DROP All TABLES IN DAILY DB
for I in $(psql "host=$TEMPORARY_LEDGER_HOST port=5432 dbname=$TEMPORARY_LEDGER_DATABASE user=$TEMPORARY_LEDGER_USERNAME password=$TEMPORARY_LEDGER_PASSWORD sslmode=require" -c "SELECT tablename FROM pg_tables" -t);
  do
  echo " drop table $I CASCADE; ";
  psql "host=$TEMPORARY_LEDGER_HOST port=5432 dbname=$TEMPORARY_LEDGER_DATABASE user=$TEMPORARY_LEDGER_USERNAME password=$TEMPORARY_LEDGER_PASSWORD sslmode=require" -c "drop table $I CASCADE;" -t
done


# IMPORT LEDGER PROD DATABASE INTO DAILY
echo "Importing Ledger prod into ledger daily database";
psql "host=$TEMPORARY_LEDGER_HOST port=5432 dbname=$TEMPORARY_LEDGER_DATABASE user=$TEMPORARY_LEDGER_USERNAME password=$TEMPORARY_LEDGER_PASSWORD sslmode=require" < /dbdumps/ledger_prod.sql

# EXPORT LEDGER CORE TABLES
PGPASSWORD="$PRODUCTION_LEDGER_PASSWORD" pg_dump -t 'accounts_*' -t 'actions_*' -t 'address_*' -t 'analytics_*' -t 'api_*' -t 'auth_*' -t 'basket_*' -t 'bpay_*' -t 'bpoint_*' -t 'cash_*' -t 'catalogue_*' -t 'customer_*' -t 'django_*'  -t 'invoice_*' -t 'ledgergw_*' -t 'main_sequence' -t 'offer_*' -t 'order_*' -t 'partner_*' -t 'payment_*' -t 'payments_*' -t 'promotions_*' -t 'reviews_*' -t 'shipping_*' -t 'social_auth_*' -t 'taggit_*' -t 'voucher_*' -t 'wishlists_*' --file /dbdumps/ledger_core_prod.sql --format=custom --host $PRODUCTION_LEDGER_HOST --dbname $PRODUCTION_LEDGER_DATABASE --username $PRODUCTION_LEDGER_USERNAME

# Full LEDGER PROD DATABASE
rm /dbdumps/ledger_prod.sql.gz
gzip /dbdumps/ledger_prod.sql
mv /dbdumps/ledger_prod.sql.gz /dbdumps/dumps/

# ledger no reversion 
rm /dbdumps/ledger_prod_no_reversion.sql.gz
gzip /dbdumps/ledger_prod_no_reversion.sql
mv /dbdumps/ledger_prod_no_reversion.sql.gz /dbdumps/dumps/

# LEDGER CORE PROD DATABASE TABLES
rm /dbdumps/ledger_core_prod.sql.gz
gzip /dbdumps/ledger_core_prod.sql
mv /dbdumps/ledger_core_prod.sql.gz /dbdumps/dumps/
