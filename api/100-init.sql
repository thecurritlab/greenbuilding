CREATE ROLE anonymous NOLOGIN;
-- Remember the following password!
CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'superSecretAuthenticatorPassword';
GRANT anonymous to authenticator;
CREATE SCHEMA api;
GRANT USAGE ON SCHEMA api TO anonymous;
-- Ensure the database name ('app' below) corresponds to POSTGRES_DB in /envs/postgis.env
ALTER DATABASE app SET search_path = "$user", public, postgis;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

---------------------------------------------------
-- The following SQL is for a quick test of the API
---------------------------------------------------

CREATE TABLE api.cars (
	id SERIAL PRIMARY KEY,
	make text,
	model text,
	price float
);

INSERT INTO api.cars (make, model, price) VALUES
('Nissan', 'Altima', 20000),
('Ford', 'Festiva', 10000);

GRANT SELECT ON TABLE api.cars TO anonymous;

-- Go to http://localhost:3000/cars or 
--     curl --location --request GET 'localhost:3000/cars'

CREATE FUNCTION api.hi() RETURNS text AS $$
    DECLARE
        greeting text;
    BEGIN
        SELECT 'Hi there, you!' INTO greeting;
        RETURN greeting;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION api.hello(p_name text) RETURNS text AS $$
    DECLARE
        v_name text = p_name;
        greeting text;
    BEGIN
        SELECT 'Hello, ' || v_name INTO greeting;
        RETURN greeting;
    END;
$$ LANGUAGE plpgsql;

-- See Schema Cache Reloading at https://postgrest.org/en/stable/schema_cache.html
-- docker compose -f docker-compose.yml -f docker-compose.api.yml kill -s SIGUSR1 postgrest

GRANT EXECUTE ON FUNCTION api.hi TO anonymous;
GRANT EXECUTE ON FUNCTION api.hello TO anonymous;

-- Go to http://localhost:3000/rpc=hi or 
--     curl --location --request GET 'localhost:3000/rpc/hi'
-- Go to http://localhost:3000/rpc/hello?p_name=Nate or 
--     curl --location --request GET 'localhost:3000/rpc/hello?p_name=Nate'