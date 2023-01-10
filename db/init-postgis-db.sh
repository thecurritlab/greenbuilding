#!/bin/bash

# For MobilityDB
echo "shared_preload_libraries = 'postgis-3.so,timescaledb'" >> $PGDATA/postgresql.conf
echo "max_locks_per_transaction = 128" >> $PGDATA/postgresql.conf

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_postgis' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis IS_TEMPLATE true;
EOSQL

# Load PostGIS into both template_database and $POSTGRES_DB
for DB in template_postgis "$POSTGRES_DB"; do
	echo "Loading PostGIS extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
        CREATE SCHEMA postgis;
		CREATE EXTENSION IF NOT EXISTS postgis SCHEMA postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_raster SCHEMA postgis;
		ALTER DATABASE postgres SET search_path = "$user", public, postgis;
		ALTER DATABASE postgres SET postgis.enable_outdb_rasters = true;
		ALTER DATABASE postgres SET postgis.gdal_enabled_drivers TO 'ENABLE_ALL';
EOSQL
done