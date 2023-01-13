<!-- <style>
    green {
        color: green;
    }

    h1 {
        padding-top: 30px;
        padding-bottom: 30px;
    }

    h3 {
        color: #5b5b5b;
    }

    h3, h4 {
        padding-top: 20px;
        padding-bottom: 15px;
    }

    reddish {
        color: #9e5252;
    }

    .indent-1 {
        padding-left: 25px;
    }
</style> -->
# **Project <green>_greenbuilding_</green>** :deciduous_tree:

### GREEN ROOF BUILDING PROJECTS

At its heart, this is a project to map and analyze green buildings&mdash;green building incentive programs, types of green buildings, and the environmental, urban, and social impacts of green buildings.

Technically, it is built (currently it is more correct to say _it is being built_) using [PostgreSQL](https://www.postgresql.org), [PostGIS](http://postgis.net) (and other database extensions), [PostgREST](https://postgrest.org/en/stable/), [SvelteKit](https://kit.svelte.dev), [OpenLayers](https://openlayers.org) and [MapLibre](https://maplibre.org). [pg_tileserv](https://access.crunchydata.com/documentation/pg_tileserv/latest/) and [pg_featureserv](https://access.crunchydata.com/documentation/pg_featureserv/latest/) are currently important for the project, but we're playing with other options, including building our own vector and feature tile servers. The plan is for [Varnish](https://varnish-cache.org) to serve as a caching layer and for all of these components to run as microservices on a [Kubernetes](https://kubernetes.io) cluster. Yes, that's a hefty lift...but totally doable!

### REPOSITORY CONTENTS
1. **/.github/workflows**: GitHub Actions to build, test, push and deploy project.

2. **/api**: SQL to build the application database.
    * 100-init.sql: PostgREST API basic setup. (This is essential to run the PostgREST API set up described below.)
    #### *<reddish>The following list of SQL files will grow as development continues to create a full-fledged database application and API.</reddish>*
    * 200-auth.sql: Authorization schema, tables and logic.
    * 300-multi_tenant_geospatial.sql: what's to come?
    * 300-data.sql: what's to come?
    * ...

3. **/db**: PostgreSQL database image build files.
    * Essential extensions: postgis, pgjwt, 
    * The full shebang of extensions: TimescaleDB, MobilityDB, pointcloud and more (more than really needed for a single project...but hey!)

4. **/dev**: Directories and files to be mapped as volumes with `docker-compose.dev.yml` for local development.
    * /data: postgis container volume
    * /sql: pgadmin container volume

5. **/envs**: Individual environment variables files for creating containers using `docker-compose*.yml` files.
    * pgadmin
    * postgis
    * postgrest
    * swagger

6. **`.env`**: Environment variables common to all `docker-compose*.yml` and `/envs/*.env` files.

7. **`docker-compose.yml`**: compose to run PostgreSQL/PostGIS

8. **`docker-compose.dev.yml`**: compose to run pgAdmin4 and modify `docker-compose.yml`.

9. **`docker-compose.api.yml`**: compose to run PostgREST 

### LOCAL DEVELOPMENT

Currently `docker` and `docker compose` are used to run the whole project. (Soon to come...Kubernetes!) 

For a **<green>DATABASE ONLY</green>** setup, run the following:

    docker compose -f docker.compose.yml up -d

To access the container, run:

    docker exec -it <PROJECT_PREFIX>_postgis bash 

Then, to access the database, run the following from within the container:

    psql postgres://<POSTGRES_USER>:<POSTGRES_PASSWORD>@localhost:5432/<POSTGRES_DB>`

---

For a **<green>DATABASE AND PGADMIN4 GUI</green>** set up, run the following:

    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

Follow the instructions above to access the container and the database.

To access the pgAdmin4 GUI, open http://localhost:5050 and login with <PGADMIN_DEFAULT_EMAIL> and <PGADMIN_DEFAULT_PASSWORD>.

---

For a **<green>DATABASE AND API</green>** set up, follow the instructions above and access the database. Run the SQL found in `/api/100-init.sql`. Then, run one of the following:

    docker compose -f docker-compose.yml -f docker-compose.api.yml up -d

or...

    docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.api.yml up -d

To access the API, either (1) open http://localhost:3000 for the API root, http://localhost:3000/<table_name> for a table or http://localhost:3000/rpc/<function_name> for a function. Because PGRST_JWT_SECRET was set, all access to the API must include a Bearer token signed with the JWT_SECRET. (You can comment out PGRST_JWT_SECRET in `postgrest.env` for unfettered development access to the API, just don't do this in production.) What you are able to access from the API depends on the table, column and row-level security permissions you have set in the database. 

#### <reddish>DATABASE AND API DEVELOPMENT HINTS</reddish>
<div class="indent-1">

Read the [PostgREST documentation](https://postgrest.org) closely for help building the database and API. When using PostgREST, API permissions are database permissions&mdash;so you need to know your database!. Closely follow [GRANT](https://www.postgresql.org/docs/current/sql-grant.html) and [Row Security Policies](https://www.postgresql.org/docs/15/ddl-rowsecurity.html) for allowing only the minimum access necessary for your application. Keep it secure!

Of particular note when running PostgREST with `docker compose` (as we are in this project), for newly created functions (remote procedure calls) to be recognized by the API you may need to perform [Schema Cache Reloading](https://postgrest.org/en/stable/schema_cache.html).

    docker compose -f docker-compose.yml -f docker-compose.api.yml kill -s SIGUSR1 postgrest

</div>

### WRAPPING UP DEVELOPMENT

When you have finished your development session, run one of the following depending on how you started developing: 

    docker compose -f docker-compose.yml stop

or...

    docker compose -f docker-compose.yml -f docker-compose.dev.yml stop

or... 

    docker compose -f docker-compose.yml -f docker-compose.api.yml stop

or ...

    docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.api.yml stop