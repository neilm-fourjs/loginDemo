
IMPORT os
IMPORT FGL gl_lib
IMPORT FGL lib_secure
&include "schema.inc"

MAIN
	DEFINE l_hash_type, l_login_pass, l_salt, l_pass_hash VARCHAR(64)

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
			hash_type		VARCHAR(12) NOT NULL, -- type of hash used.
			login_pass  VARCHAR(16), -- not actually used.
			salt        VARCHAR(32), -- for Genero 3.10 using bcrypt we don't need this
			pass_hash   VARCHAR(64) NOT NULL,
			pass_expire DATE
		)
		DISPLAY "Table Created."
	END TRY

	LET l_login_pass = "T3st.T3st"
	LET l_hash_type = lib_secure.glsec_getHashType()
	LET l_salt = lib_secure.glsec_genSalt(l_hash_type)
	LET l_pass_hash = lib_secure.glsec_genPasswordHash( l_login_pass, l_salt, l_hash_type )

	TRY
		INSERT INTO accounts VALUES(1,"Mr","Test","Testing","Tester","test@test.com","A test account",0,1,"N",
			l_hash_type, l_login_pass, l_salt, l_pass_hash, TODAY+365)
		DISPLAY "Test Account Inserted."
	CATCH
		DISPLAY "Insert test account failed!\n",STATUS,":",SQLERRMESSAGE
	END TRY
END MAIN