# Remove docker containers
docker rm gb_postgrest
docker rm gb_pgadmin4
docker rm gb_postgis

# Remove docker volume
docker volume rm greenbuilding_postgis_data

# Remove docker network
docker network rm greenbuilding_db_network

