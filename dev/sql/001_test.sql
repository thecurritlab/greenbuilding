--------------------------------------------------------------
-- User signup and delete_account...and permissions testing --
--------------------------------------------------------------

SET ROLE nate; -- superuser

SELECT *
FROM auth.users;

SELECT *
FROM auth.user_secrets;

SHOW search_path;

SELECT api.signup('Amy Currit', 'amy', 'akcurrit@gmail.com', 'letAmyInNow!');
SELECT api.signup('Elisabeth Currit', 'elisabeth', 'letElisabethInNow!');
SELECT api.signup('Isabel Currit', 'isabel', 'letIsabelInNow!');

SELECT *
FROM auth.users;

SELECT *
FROM auth.user_secrets;

SELECT *
FROM api.users;

SET ROLE amy;

CREATE TABLE amy.made_by_amy(
	id SERIAL PRIMARY KEY,
	name text,
	working boolean DEFAULT false
);

CREATE TABLE isabel.amy_cannot_create_this(
	id SERIAL PRIMARY KEY,
	name text,
	working boolean DEFAULT false
);

SET ROLE isabel;
SELECT current_user;

CREATE TABLE amy.isabel_cannot_create_this(
	id SERIAL PRIMARY KEY,
	name text,
	working boolean DEFAULT false
);

CREATE TABLE isabel.made_by_isabel(
	id SERIAL PRIMARY KEY,
	name text,
	working boolean DEFAULT false
);

SET ROLE nate; -- superuser...back to dev mode!
SELECT api.delete_account('Amy Currit', 'amy');

SET ROLE amy;
SELECT api.debug('Amy Currit', 'amy');

SELECT auth.delete_account('Elisabeth Currit', 'elisabeth');
SELECT auth.delete_account('Isabel Currit', 'isabel');

--- Stuff ---

SELECT current_user;

--- End Stuff ---

------------------------------------------------------
-- The below tables are for everyone...for testing. --
------------------------------------------------------

CREATE TABLE car (
	id SERIAL PRIMARY KEY,
	make text,
	model text,
	price float
);

INSERT INTO car (make, model, price) VALUES
('Nissan', 'Altima', 18000),
('Ford', 'Model T', 90000);

SELECT *
FROM car;

