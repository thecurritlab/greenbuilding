-- #################################################################
-- ##### This file should eventually be copied to 100-init.sql #####
-- #################################################################

/* ### Database initialization ### */

CREATE EXTENSION pgcrypto SCHEMA extensions;
CREATE EXTENSION pgjwt SCHEMA extensions;
CREATE EXTENSION citext SCHEMA extensions;

-- Alter the following password!
CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'superSecretAuthenticatorPassword';
CREATE ROLE anonymous NOLOGIN;
CREATE ROLE web_user NOLOGIN;

CREATE ROLE api_views_owner NOINHERIT;

CREATE SCHEMA api;

/* ### END Database initialization ### */
----------
/* ### AUTHORIZATION ### */

CREATE SCHEMA auth;

DROP TYPE IF EXISTS auth.jwt_token;

-- CREATE TYPE auth.jwt_token AS (
--   token text
-- );

CREATE TYPE auth.jwt_token AS (
    role text,
    exp integer,
    username citext,
	email text,
    is_admin boolean
);

-- DROP FUNCTION IF EXISTS auth.current_username;
-- CREATE OR REPLACE FUNCTION auth.current_username() RETURNS text AS $$
--     SELECT NULLIF(current_setting('jwt.claims.name', true), '')::text;
-- $$ LANGUAGE SQL stable set search_path from current;
DROP FUNCTION IF EXISTS auth.current_username;
CREATE OR REPLACE FUNCTION auth.current_username() RETURNS text AS 
$$
    SELECT COALESCE(current_setting('jwt.claims.username', true)::json->>'username', '')::text;
$$ LANGUAGE SQL stable set search_path from current;

DROP TABLE IF EXISTS auth.users CASCADE;
CREATE TABLE auth.users(
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	name text NOT NULL,
	username extensions.citext NOT NULL,
	email text NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now(),
	updated_at timestamptz NOT NULL DEFAULT now(),
	CONSTRAINT username_uniq UNIQUE(username),
	CONSTRAINT username_check CHECK(username ~ '^[a-zA-Z]([a-zA-Z0-9][_]?)+$'),
	CONSTRAINT email_check CHECK(email ~* '^.+@.+\..+$')
);

DROP VIEW IF EXISTS api.users CASCADE;
CREATE OR REPLACE VIEW api.users AS
	SELECT name, username
	FROM auth.users;
ALTER VIEW api.users OWNER TO api_views_owner;

DROP TABLE IF EXISTS auth.user_secrets CASCADE;
CREATE TABLE auth.user_secrets(
	user_id uuid PRIMARY KEY,
	password_hash text,
	CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

/*
##### Function to signup user and add user schema and role
*/
DROP FUNCTION IF EXISTS api.signup;
CREATE OR REPLACE FUNCTION api.signup(
	p_name text,
	p_username text,
	p_email text,
	p_password text
) RETURNS auth.users AS
$$
	DECLARE
		v_user auth.users;
		v_name text = p_name;
		v_username text = p_username;
		v_email text = p_email;
		v_password text = p_password;
	BEGIN
		if v_username is null then
			v_username = coalesce(name, 'user');
		end if;
		v_username = regexp_replace(v_username, '^[^a-z]+', '', 'i'); -- Numbers at beginning of username removed ('i' is for case-insensitive)
  		v_username = regexp_replace(v_username, '[^a-z0-9]+', '_', 'i'); -- Spaces replaced with underbar
		
		INSERT INTO auth.users(name, username, email) VALUES
    	(v_name, v_username, v_email)
    	RETURNING * INTO v_user;
		
		INSERT INTO auth.user_secrets(user_id, password_hash) VALUES
		(v_user.id, extensions.crypt(v_password, extensions.gen_salt('bf')));
		
		EXECUTE format('CREATE ROLE %I NOLOGIN', v_user.username);
		EXECUTE format('GRANT %I TO web_user', v_user.username);
		EXECUTE format('CREATE SCHEMA AUTHORIZATION %I', v_user.username);
				
		RETURN v_user;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
##### Function to login user by returning jwt_token
*/
DROP FUNCTION IF EXISTS api.login;
CREATE OR REPLACE FUNCTION api.login(
	p_username text,
	p_password text
) RETURNS auth.jwt_token AS $$
	DECLARE
		v_username text = p_username;
		v_password text;
		v_token auth.jwt_token;
	BEGIN
		-- WITH payload AS (
		-- 	SELECT 'web_user'::text AS role,
        --            extract(epoch from now())::integer + 300 AS exp,
		-- 		   v_username::text AS username
		-- )
		-- SELECT public.sign(row_to_json(payload), current_setting('auth.jwt_secret')) INTO v_token
		-- FROM payload;
        WITH payload AS (
            SELECT 'web_user'::text AS role,
                extract(epoch from now())::integer + 300 AS exp,
                v_username::text AS username,
                false AS is_admin
        )
        SELECT extensions.sign(row_to_json(payload::auth.jwt_token), current_setting('auth.jwt_secret')) INTO v_token
        FROM payload;

		RETURN v_token;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION api.login TO anonymous;

/*
##### Function to delete user account and remove user schema and role
*/
DROP FUNCTION IF EXISTS api.delete_account;
CREATE OR REPLACE FUNCTION api.delete_account(
	p_name text,
	p_username text
) RETURNS auth.users AS
$$
	DECLARE
		v_user auth.users;
		v_name text = p_name;
		v_username text = p_username;
		v_current_user text;
	BEGIN
		SELECT current_user INTO v_current_user;
		
		SELECT * INTO v_user
		FROM auth.users
		WHERE name = v_name AND username = v_username AND username = v_current_user;
		
		DELETE FROM auth.user_secrets
		WHERE user_id = v_user.id;
		
		DELETE FROM auth.users
		WHERE id = v_user.id
		RETURNING * INTO v_user;
		
		EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', v_user.username);
		
		RETURN v_user;
	END;
$$ LANGUAGE plpgsql;

---------------------------------------------
-- Revokes privileges from all functions in all schemas
-- ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC; -- Schema public is gone. I removed it. Privileges are revoked by default for all schemas besides public.
-- ENSURE THIS PASSWORD IS IDENTICAL TO THE ONE IN .env --
ALTER DATABASE app SET auth.jwt_secret TO 'reallyreallyreallysecretjwtsecretkey';

GRANT anonymous TO authenticator;
GRANT web_user TO authenticator;

GRANT USAGE ON SCHEMA api TO anonymous, web_user;

GRANT SELECT ON VIEW api.users TO anonymous, web_user;

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_self ON auth.users FOR SELECT USING (username = current_username());

-- ALTER VIEW api.users OWNER TO api_views_owner;
-- GRANT ALL ON TABLE api.users TO web_user, isabel, nate; -- keep??

ALTER TABLE auth.user_secrets ENABLE ROW LEVEL SECURITY;

GRANT EXECUTE ON FUNCTION api.signup TO anonymous;

GRANT EXECUTE ON FUNCTION api.login TO anonymous;

GRANT EXECUTE ON FUNCTION api.delete_account TO web_user;



