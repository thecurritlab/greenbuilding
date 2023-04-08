/* ### AUTHORIZATION ### */

CREATE SCHEMA auth;

DROP TYPE IF EXISTS auth.jwt_token CASCADE;
CREATE TYPE auth.jwt_token AS (
  	role text,
	exp integer,
	username citext,
	is_admin boolean
);

DROP TABLE IF EXISTS auth.users CASCADE;
CREATE TABLE auth.users(
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	name text NOT NULL,
	username citext NOT NULL,
	email text NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now(),
	updated_at timestamptz NOT NULL DEFAULT now(),
	CONSTRAINT username_uniq UNIQUE(username),
	CONSTRAINT username_check CHECK(username ~ '^[a-zA-Z]([a-zA-Z0-9][_]?)+$'),
	CONSTRAINT email_check CHECK(email ~* '^.+@.+\..+$')
);
GRANT SELECT ON TABLE auth.users TO web_user;
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_self ON auth.users FOR SELECT USING (username = current_setting('request.jwt.claims', true)::json->>'username');

DROP TABLE IF EXISTS auth.user_secrets CASCADE;
CREATE TABLE auth.user_secrets(
	user_id uuid PRIMARY KEY,
	password_hash text,
	CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
GRANT SELECT ON TABLE auth.user_secrets TO web_user;
ALTER TABLE auth.user_secrets ENABLE ROW LEVEL SECURITY;

-- Get current_username and current_user_id from request
DROP FUNCTION IF EXISTS auth.current_user_id;
CREATE OR REPLACE FUNCTION auth.current_user_id() RETURNS uuid AS $$
	SELECT id
	FROM auth.users
	WHERE username = current_setting('request.jwt.claims', true)::json->>'username';
$$ LANGUAGE sql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION auth.current_user_id TO anonymous, web_user;

CREATE POLICY update_self ON auth.user_secrets FOR UPDATE USING (user_id = auth.current_user_id());

DROP VIEW IF EXISTS api.users CASCADE;
CREATE OR REPLACE VIEW api.users WITH (security_invoker=true) AS
	SELECT name, username
	FROM auth.users;
GRANT SELECT ON TABLE api.users TO web_user;

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
		(v_user.id, extensions.crypt(v_password, extensions.gen_salt('bf'::text)));
		
		EXECUTE format('CREATE ROLE %I NOLOGIN', v_user.username);
		EXECUTE format('GRANT %I TO web_user', v_user.username);
		EXECUTE format('CREATE SCHEMA AUTHORIZATION %I', v_user.username);
				
		RETURN v_user;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION api.signup TO anonymous;

/*
##### Function to login user by returning jwt_token
*/
DROP FUNCTION IF EXISTS api.login;
CREATE OR REPLACE FUNCTION api.login(
	p_username text,
	p_password text
) RETURNS text AS $$
	DECLARE
		v_username text = p_username;
		v_password text;
		v_token text;
	BEGIN
        WITH payload AS (
            SELECT 'web_user'::text AS role,
             	   extract(epoch from now())::integer + 24 * 3600 + 0 * 60 + 0 AS exp, -- hours * 3600m/h + minutes * 60s/m + seconds
             	   username AS username,
             	   false AS is_admin
			FROM auth.users
			WHERE username = v_username
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
-- DROP FUNCTION IF EXISTS api.delete_account;
-- CREATE OR REPLACE FUNCTION api.delete_account(
-- 	p_name text,
-- 	p_username text
-- ) RETURNS auth.users AS
-- $$
-- 	DECLARE
-- 		v_user auth.users;
-- 		v_name text = p_name;
-- 		v_username text = p_username;
-- 		v_current_user text;
-- 	BEGIN
-- 		SELECT current_user INTO v_current_user;
		
-- 		SELECT * INTO v_user
-- 		FROM auth.users
-- 		WHERE name = v_name AND username = v_username AND username = v_current_user;
		
-- 		DELETE FROM auth.user_secrets
-- 		WHERE user_id = v_user.id;
		
-- 		DELETE FROM auth.users
-- 		WHERE id = v_user.id
-- 		RETURNING * INTO v_user;
		
-- 		EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', v_user.username);
		
-- 		RETURN v_user;
-- 	END;
-- $$ LANGUAGE plpgsql;

-- GRANT EXECUTE ON FUNCTION api.delete_account TO web_user;

/* ### END AUTHORIZATION ### */
