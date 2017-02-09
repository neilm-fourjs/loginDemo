
#+ Login Demo
#+ The purpose of this demo is to show an example of how 
#+ to use the lib_login & lib_secure libraries
#+
#+ This module initially written by: Neil J.Martin ( neilm@4js.com ) 
#+

IMPORT FGL lib_secure
IMPORT FGL lib_login
IMPORT FGL gl_lib
&include "schema.inc"

CONSTANT VER = "1.0"
CONSTANT APP = %"Login Demo"

MAIN
	DEFINE l_login STRING

	OPEN FORM ld FROM "logindemo"
	DISPLAY FORM ld

	DISPLAY "Hello" TO msg

	CALL gl_lib.gl_init(TRUE)

	MENU
		BEFORE MENU
			--CALL DIALOG.setActionActive("shwcred",FALSE)
			CALL DIALOG.setActionActive("updcred",FALSE)
		ON ACTION close EXIT MENU
		ON ACTION login
			LET l_login = do_login()
			IF l_login IS NOT NULL THEN
				DISPLAY SFMT(%"Welcome %1",l_login) TO msg
				CALL DIALOG.setActionActive("login", FALSE)
				CALL DIALOG.setActionActive("shwcred",TRUE)
				CALL DIALOG.setActionActive("updcred",TRUE)
			END IF
		ON ACTION updcred CALL creds(TRUE)
		ON ACTION shwcred CALL creds(FALSE)
		ON ACTION quit EXIT MENU
	END MENU

	DISPLAY "Program Finished."

END MAIN
--------------------------------------------------------------------------------
#+ Do the login call
#+ @returns NULL or valid email address for an account
FUNCTION do_login()
	DEFINE l_login STRING

	LET int_flag = FALSE
	WHILE NOT int_flag

-- CALL THE LOGIN LIBRARY FUNCTION TO GET A VALID LOGIN EMAIL ADDRESS.
		LET l_login = lib_login.login(APP, VER, TRUE)

		DISPLAY "Login:",l_login
		IF l_login = "NEW" THEN 
			CALL new_acct()
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END WHILE

	IF l_login != "Cancelled" THEN
		CALL gl_lib.gl_winMessage(%"Login Okay",SFMT(%"Login for user %1 accepted.",l_login),"information")
		RETURN l_login
	END IF
	RETURN NULL
END FUNCTION
--------------------------------------------------------------------------------
#+ Create a new account.
FUNCTION new_acct()
	DEFINE l_acc RECORD LIKE accounts.*

	LET l_acc.acct_id = 0
	LET l_acc.acct_type = 1
	LET l_acc.active = TRUE
	LET l_acc.forcepwchg = "Y"
	LET l_acc.pass_expire = TODAY + 6 UNITS MONTH

	OPEN WINDOW new_acct WITH FORM "new_acct"

	INPUT BY NAME l_acc.* ATTRIBUTES(WITHOUT DEFAULTS, FIELD ORDER FORM, UNBUFFERED)
		AFTER FIELD email
			IF lib_login.sql_checkEmail(l_acc.email) THEN
				CALL gl_lib.gl_winMessage(%"Error",%"This Email is already registered.","exclamation")
				NEXT FIELD email
			END IF
		AFTER FIELD pass_expire
			IF l_acc.pass_expire < (TODAY + 1 UNITS MONTH) THEN
				ERROR %"Password expire date can not be less than 1 month."
				NEXT FIELD pass_expire
			END IF
		BEFORE INPUT
			CALL DIALOG.setFieldActive("accounts.acct_id",FALSE)
			CALL DIALOG.setFieldActive("accounts.forcepwchg",FALSE)
			CALL DIALOG.setFieldActive("accounts.active",FALSE)
			CALL DIALOG.setFieldActive("accounts.acct_type",FALSE)
		ON ACTION generate
			LET l_acc.login_pass = lib_secure.glsec_genPassword()
			CALL fgl_winMessage(%"Password",SFMT(%"Your Generated Password is:\n%1\nDon't forget it!",l_acc.login_pass),"information")
	END INPUT

	CLOSE WINDOW new_acct

	IF NOT int_flag THEN
		LET l_acc.salt = lib_secure.glsec_genSalt()
		LET l_acc.pass_hash = lib_secure.glsec_genHash(l_acc.login_pass ,l_acc.salt)
		LET l_acc.login_pass = "PasswordEncrypted!" -- we don't store their clear text password!
		INSERT INTO accounts VALUES l_acc.*
	END IF

	LET int_flag = FALSE
END FUNCTION
--------------------------------------------------------------------------------
#+ Show the creditials from the encrypted xml file.
FUNCTION creds( l_upd )
	DEFINE l_upd BOOLEAN
	DEFINE l_type,l_user, l_pass STRING
	LET l_type = "email"
	CALL lib_secure.glsec_getCreds(l_type) RETURNING l_user, l_pass
	DISPLAY l_type TO cred_type
	DISPLAY l_user TO username
	DISPLAY l_pass TO password
END FUNCTION
--------------------------------------------------------------------------------
#+ Populate the combox objects
#+ NOTE: This function is normally called by INITIALIZER statement in a per file.
#+
#+ @param l_cb A valid ui.ComboBox object
FUNCTION pop_combo(l_cb)
	DEFINE l_cb ui.ComboBox

	CASE l_cb.getColumnName()
		WHEN "acct_type"
			CALL l_cb.addItem(1,%"Normal User")
			CALL l_cb.addItem(2,%"Admin User")
	END CASE
END FUNCTION
--------------------------------------------------------------------------------