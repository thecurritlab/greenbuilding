-- SELECT current_user;
DROP FUNCTION IF EXISTS api.check_token CASCADE;
CREATE OR REPLACE FUNCTION api.check_token() RETURNS VOID AS $$
	DECLARE
		v_tkn text;
	BEGIN
		RAISE NOTICE 'Checking the token...';
-- 		SELECT public.verify(current_setting('request.jwt.claims', true)::json->>'role',
-- 							 current_setting('auth.jwt_secret'))INTO v_tkn;
-- 		RAISE NOTICE '%', v_tkn;

-- 		raise insufficient_privilege
--       		using hint = 'Nope, we are on to you';
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION api.check_token TO anonymous;
GRANT EXECUTE ON FUNCTION api.check_token TO isabel;

--------------------------------------------

DROP FUNCTION IF EXISTS api.what_is_jwt_doing CASCADE;
CREATE OR REPLACE FUNCTION api.what_is_jwt_doing() RETURNS record AS $$
	DECLARE
		v_token record;
		v_header json;
		v_payload json;
		v_valid boolean;
		v_role text;
		v_exp text;
	BEGIN
		RAISE NOTICE 'Checking the token...';
		
		SELECT public.verify('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ3aXNoZWRfcm9sZSI6IndlYl91c2VyIiwicm9sZSI6ImlzYWJlbCIsInVzZXJuYW1lIjoiaXNhYmVsIn0.eQcYqy_LHBsW-66TeHH5jLMFy6ET2m6lnX7m0ZCS4RA',
				   		     'reallyreallyreallysecretjwtsecretkey') INTO v_token;
		
-- 		RAISE NOTICE 'JWT header is %', v_token;

-- 		raise insufficient_privilege
--       		using hint = 'Nope, we are on to you';

-- 		RETURN 'Done checking JWT.';
		RETURN v_token;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION api.what_is_jwt_doing TO PUBLIC;