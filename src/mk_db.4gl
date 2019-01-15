
IMPORT os
IMPORT FGL gl_lib
IMPORT FGL lib_secure
&include "schema.inc"

MAIN
	DEFINE l_hash_type, l_login_pass, l_salt, l_pass_hash, l_email VARCHAR(128)
	DEFINE l_expires DATE

	CALL gl_lib.db_connect()

	TRY
		DISPLAY "Dropping accounts table ..."
		DROP TABLE accounts
	CATCH
		DISPLAY STATUS,":",SQLERRMESSAGE
		DISPLAY "accounts drop failed."
	END TRY

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
			salt        VARCHAR(64), -- for Genero 3.10 using bcrypt we don't need this
			pass_hash   VARCHAR(128) NOT NULL,
			pass_expire DATE
		)
		DISPLAY "Table Created."
	END TRY

	LET l_email = "test@test.com"
	LET l_login_pass = "T3st.T3st"
	LET l_hash_type = lib_secure.glsec_getHashType()
	LET l_salt = lib_secure.glsec_genSalt(l_hash_type)
	LET l_pass_hash = lib_secure.glsec_genPasswordHash( l_login_pass, l_salt, l_hash_type )
	LET l_expires = TODAY+365
	TRY
		INSERT INTO accounts VALUES(1,"Mr","Test","Testing","Tester",l_email,"A test account",0,1,"N",
			l_hash_type, l_login_pass, l_salt, l_pass_hash, l_expires)
		DISPLAY "Test Account Inserted: "||l_email||" / "||l_login_pass||" with "||l_hash_type||" hash."
	CATCH
		DISPLAY "Insert test account failed!\n",STATUS,":",SQLERRMESSAGE
	END TRY
END MAIN