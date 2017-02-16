
IMPORT os
IMPORT FGL gl_lib
&include "schema.inc"

MAIN

	CALL gl_lib.db_connect()

	DROP TABLE accounts

	TRY
		SELECT COUNT(*) FROM accounts 
	CATCH
		DISPLAY "Creating accounts table..."
		CREATE TABLE accounts (
			acct_id     SERIAL NOT NULL,
			salutation  VARCHAR(60),
			forenames   VARCHAR(60) NOT NULL,
			surname     VARCHAR(60) NOT NULL,
			position    VARCHAR(60),
			email       VARCHAR(60) NOT NULL,
			comment     VARCHAR(60),
			acct_type   SMALLINT,
			active      SMALLINT NOT NULL,
			forcepwchg  CHAR(1),
			login_pass  VARCHAR(16), -- not actually used.
			salt        VARCHAR(32) NOT NULL, -- for Genero 3.10 using bcrypt we don't need this
			pass_hash   CHAR(64) NOT NULL,
			pass_expire DATE
		)
		DISPLAY "Done."
	END TRY
END MAIN