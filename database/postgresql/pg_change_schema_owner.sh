#!/bin/bash
#设置密码 export PGPASSWORD=123456
usage()
{
cat << EOF
usage: $0 options

This script sets ownership for all tables, sequences, views, and functions for a given schema.
Run this script as your postgres OS user.

Credit: Based on http://stackoverflow.com/a/2686185/305019 by Alex Soto
        Also merged changes from @sharoonthomas

bspkrs: Added function code based on http://dba.stackexchange.com/a/9710/31043
        and changed messy object quoting to use quote_ident().

OPTIONS:
   -h      Show this message
   -a      Database address
   -d      Database name
   -o      New Owner
EOF
}

DB_NAME="";
NEW_OWNER="";
while getopts "h:a:d:o:" OPTION; do
    case $OPTION in
        h)
            usage;
            exit 1;
            ;;
        a)
            DB_HOST=$OPTARG;
            ;;
        d)
            DB_NAME=$OPTARG;
            ;;
        o)
            NEW_OWNER=$OPTARG;
            ;;
    esac
done

if [[ -z $DB_NAME ]] || [[ -z $NEW_OWNER ]]; then
     usage;
     exit 1;
fi

for tbl in `psql -h ${DB_HOST} -U postgres -qAt -c "SELECT quote_ident(schemaname) || '.' || quote_ident(tablename) FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog';" ${DB_NAME}` \
           `psql -h ${DB_HOST} -U postgres -qAt -c "SELECT quote_ident(sequence_schema) || '.' || quote_ident(sequence_name) FROM information_schema.sequences WHERE sequence_schema != 'pg_catalog';" ${DB_NAME}` \
           `psql -h ${DB_HOST} -U postgres -qAt -c "SELECT quote_ident(table_schema) || '.' || quote_ident(table_name) FROM information_schema.views WHERE table_schema != 'pg_catalog';" ${DB_NAME}` ;
  do
      psql -h ${DB_HOST} -U postgres -c "ALTER TABLE $tbl OWNER TO ${NEW_OWNER}" ${DB_NAME};
  done

psql -h ${DB_HOST} -U postgres -qAt -c "SELECT DISTINCT quote_ident(table_schema) FROM information_schema.tables WHERE table_schema != 'pg_catalog';" ${DB_NAME} | while read schema ;
  do
      psql -h ${DB_HOST} -U postgres -c "ALTER SCHEMA $schema OWNER TO ${NEW_OWNER}" ${DB_NAME};
  done

psql -h ${DB_HOST} -U postgres -qAt -c "SELECT quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')' FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname != 'pg_catalog';" ${DB_NAME} | while read func ;
  do
      psql -h ${DB_HOST} -U postgres -c "ALTER FUNCTION $func OWNER TO ${NEW_OWNER}" ${DB_NAME};
  done
