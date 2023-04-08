/* ### Database initialization ### */

-- ENSURE THIS PASSWORD IS IDENTICAL TO THE ONE IN .env --
ALTER DATABASE app SET auth.jwt_secret TO 'reallyreallyreallysecretjwtsecretkey';
-- I think the above line is unnecessary!

-- Install extensions
CREATE EXTENSION pgcrypto;
CREATE EXTENSION pgjwt;
CREATE EXTENSION citext;

-- Create roles
-- Alter the following password!
CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'superSecretAuthenticatorPassword';
CREATE ROLE anonymous NOLOGIN;
CREATE ROLE web_user NOLOGIN;
GRANT anonymous TO authenticator;
GRANT web_user TO authenticator;

-- Create api schema
CREATE SCHEMA api;
GRANT USAGE ON SCHEMA api TO anonymous, web_user;

-- Revokes privileges from all functions in all schemas
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Function to ensure jwt access is working properly
DROP FUNCTION IF EXISTS api.my_jwt;
CREATE OR REPLACE FUNCTION api.my_jwt() RETURNS json AS $$
	SELECT current_setting('request.jwt.claims', true)::json;
$$ LANGUAGE sql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION api.my_jwt TO anonymous, web_user;

/* ### END Database initialization ### */
