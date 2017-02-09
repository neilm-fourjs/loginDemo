
#+ This module is designed to present a login window and allow a user to login
#+

IMPORT FGL lib_secure
IMPORT FGL gl_lib
&include "schema.inc"

CONSTANT c_sym = "!$%^&*,.;@#?<>" -- valid symbols for use in a password

--------------------------------------------------------------------------------
#+ Login function - One day when this program grows up it will have single signon 
#+ then hackers only have one password to crack :)
#+
#+ @param l_appname - String - the name of the application ( used in the welcome message and window title )
#+ @param l_ver - String - the version of the application ( used in the window title )
#+ @param l_allow_new - Boolean - Enable the 'Create New Account' option.
#+ @return login email address or NULL or 'NEW' for a new account.
PUBLIC FUNCTION login(l_appname, l_ver, l_allow_new)
	DEFINE l_appname, l_ver STRING
	DEFINE l_allow_new BOOLEAN
	DEFINE l_login, l_pass STRING
	DEFINE f ui.Form

	LET INT_FLAG = FALSE
	CALL gl_lib.gl_logIt("Allow New:"||l_allow_new||" Ver:"||l_ver)
	OPTIONS
		INPUT NO WRAP

	OPEN WINDOW login WITH FORM "login"
	CALL login_ver_title(l_appname, l_ver)

	LET l_login = fgl_getenv("OPENID_email")
	IF l_login.getLength() < 2 THEN
		LET l_login = "enter email address"
	END IF

	CALL  gl_lib.gl_logIt("before input for login")
	INPUT BY NAME l_login, l_pass ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
		BEFORE INPUT
			LET f = DIALOG.getForm()
			IF NOT l_allow_new THEN
				CALL DIALOG.setActionActive( "acct_new",FALSE )
				CALL DIALOG.setActionHidden( "acct_new",TRUE )
				CALL f.setElementHidden( "acct_new",TRUE )
			END IF
		AFTER INPUT
			IF NOT int_flag THEN
				IF NOT validate_login(l_login,l_pass) THEN
					ERROR %"Invalid Login Details!"
					NEXT FIELD l_login
				END IF
			ELSE
				LET l_login = "Cancelled"
			END IF
		ON ACTION acct_new
			LET l_login = "NEW"
			EXIT INPUT
		ON ACTION forgotten CALL forgotten(l_login)
	END INPUT
	CLOSE WINDOW login

	CALL  gl_lib.gl_logIt("after input for login:"||l_login)

	RETURN l_login
END FUNCTION
--------------------------------------------------------------------------------
#+ Check to see if email address exists in database
#+
#+ @param l_email Email address to check
#+ @return true if exists else false
PUBLIC FUNCTION sql_checkEmail(l_email)
	DEFINE l_email VARCHAR(60)
	SELECT * FROM accounts WHERE email = l_email
	IF STATUS = NOTFOUND THEN RETURN FALSE END IF
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  PRIVATE FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
PRIVATE FUNCTION validate_login(l_login,l_pass)
	DEFINE l_login LIKE accounts.email
	DEFINE l_pass LIKE accounts.login_pass
	DEFINE l_acc RECORD LIKE accounts.*
	DEFINE l_hash LIKE accounts.pass_hash

-- does account exist?
	SELECT * INTO l_acc.* FROM accounts WHERE email = l_login
	IF STATUS = NOTFOUND THEN
		CALL gl_logIt("No account for:"||l_login)
		RETURN FALSE
	END IF

-- is password correct?
	LET l_hash = lib_secure.glsec_genHash(l_pass,l_acc.salt)
	IF l_hash != l_acc.pass_hash THEN
		DISPLAY "Hash wrong for:",l_login," Password:",l_acc.login_pass
		RETURN FALSE
	END IF

-- Has the password expired?
	IF l_acc.pass_expire IS NOT NULL AND l_acc.pass_expire > DATE("01/01/1990") THEN
		IF l_acc.pass_expire <= TODAY THEN
			CALL gl_lib.gl_logIt("Password has expired:"||l_acc.pass_expire)
			CALL gl_lib.gl_winMessage(%"Error",%"Your password has expired!\nYou will need to create a new one!","exclamation")
			LET l_acc.forcepwchg = "Y" 
		END IF
	END IF

-- do we need to force a password change?
	IF l_acc.forcepwchg = "Y" THEN
		IF NOT passchg(l_login) THEN
			RETURN FALSE
		END IF
	END IF

-- all okay
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
#+ Forgotten password routine.
#+
#+ @param l_login - String - email address to send email to
PRIVATE FUNCTION forgotten(l_login)
	DEFINE l_login LIKE accounts.email
	DEFINE l_acc RECORD LIKE accounts.*
	DEFINE l_cmd, l_subj, l_body, l_b64 STRING
	DEFINE l_ret SMALLINT

	IF l_login IS NULL OR l_login = " " THEN
		CALL gl_lib.gl_winMessage(%"Error",%"You must enter your email address!","exclamation")
		RETURN
	END IF

	IF NOT sql_checkEmail(l_login) THEN
		CALL gl_lib.gl_winMessage(%"Error",%"Email address not registered!","exclamation")
		RETURN
	END IF

	IF fgl_winQuestion(%"Confirm",%"Are you sure you want to reset your password?\n\nA link will be emailed to you,\nyou will then be able to change and clicking the link.",
			"No","Yes|No","question",0) = "No" THEN
		RETURN
	END IF

	CALL gl_lib.gl_logIt("Password regenerated for:"||l_login)

	LET l_acc.pass_expire = TODAY + 2
	LET l_acc.login_pass = lib_secure.glsec_genPassword()
	LET l_acc.salt = lib_secure.glsec_genSalt()
	LET l_acc.pass_hash = lib_secure.glsec_genHash(l_acc.login_pass ,l_acc.salt)
	LET l_acc.forcepwchg = "Y"
	LET l_b64 = lib_secure.glsec_toBase64( l_acc.pass_hash )
-- Need to actually send email!!
	LET l_subj = %"Password Reset"
	LET l_body = 
				SFMT(%"Your password for the Login Demo has been reset.\n"||
				"You are now required to change your password."||
				"\nClick the link below to enter a new password:\n"||
				"https://%1/g/ua/r/g/logindemo?Arg=__reset%2\n\n"||
				"NOTE: This link is only valid for 2 days.\n\n"||
				"Please do not reply to this email.",fgl_getEnv("LOGINDEMO_SRV"),l_b64)

	LET l_cmd = "fglrun sendemail.42r "||NVL(l_login,"NOEMAILADD!")||" \"[LoginDemo] "||NVL(l_subj,"NULLSUBJ")||"\" \""||NVL(l_body,"NULLBODY")||"\" 2> sendemail.err"
	--DISPLAY "CMD:",NVL(l_cmd,"NULL")
	ERROR "Sending Email, please wait ..."
	CALL ui.interface.refresh()
	RUN l_cmd RETURNING l_ret
	CALL gl_logIt("Sendmail return:"||NVL(l_ret,"NULL"))
	IF l_ret = 0 THEN -- email send okay
		UPDATE accounts 
			SET (salt, pass_hash, forcepwchg, pass_expire) = 
					(l_acc.salt, l_acc.pass_hash, l_acc.forcepwchg, l_acc.pass_expire )
			WHERE email = l_login
		CALL gl_lib.gl_winMessage(%"Password Reset",%"A Link has been emailed to you","information")
	ELSE -- email send failed
		CALL gl_lib.gl_winMessage(%"Password Reset",%"Reset Email failed to send!\nProcess aborted","information")
	END IF
	
END FUNCTION
--------------------------------------------------------------------------------
PRIVATE FUNCTION login_ver_title(l_appname,l_ver)
	DEFINE l_appname,l_ver STRING
	DEFINE w ui.Window
	DEFINE f ui.Form
	DEFINE n om.DomNode
	LET w = ui.Window.getCurrent()
	IF w IS NOT NULL THEN
		LET n = w.getNode()
		CALL n.setAttribute("name", l_appname||"_"||l_ver )
		CALL n.setAttribute("text", l_appname||" "||l_ver )
		LET f = w.getForm()
		CALL f.setElementText("titl",SFMT(%"Welcome to the %1",l_appname))
	END IF
END FUNCTION
--------------------------------------------------------------------------------
PRIVATE FUNCTION passchg(l_login)
	DEFINE l_login LIKE accounts.email
	DEFINE l_pass1, l_pass2 LIKE accounts.login_pass
	DEFINE w ui.Window
	DEFINE f ui.Form
	DEFINE l_rules STRING
	DEFINE l_acc RECORD LIKE accounts.*

	LET l_pass1 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	LET l_rules = %"The password must confirm to the following rules:\n",
								"At least 8 characters, max is "||LENGTH(l_pass1)||"\n",
								"At least 1 lower case letter\n",
								"At least 1 upper case letter\n",
								"At least 1 number\n",
								"At least 1 symbol from the this list: ",c_sym

	LET w = ui.Window.getCurrent()
	LET f = w.getForm()
	CALL f.setElementHidden("grp2",FALSE)
	DISPLAY BY NAME l_rules, l_login
	
	WHILE TRUE
		INPUT BY NAME l_pass1, l_pass2
			AFTER FIELD l_pass1
				IF NOT pass_ok(l_pass1) THEN
					NEXT FIELD l_pass1
				END IF
		END INPUT
		IF int_flag THEN LET int_flag = FALSE RETURN FALSE END IF

		IF l_pass1 != l_pass2 THEN
			ERROR %"Passwords didn't match!"
			LET l_pass1 = ""
			LET l_pass2 = ""
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END WHILE

	LET l_acc.login_pass = l_pass1
	LET l_acc.salt = lib_secure.glsec_genSalt()
	LET l_acc.pass_hash = lib_secure.glsec_genHash(l_acc.login_pass ,l_acc.salt)
	LET l_acc.forcepwchg = "N"
	LET l_acc.pass_expire = NULL
	--DISPLAY "New Hash:",l_acc.pass_hash
	UPDATE accounts 
		SET (salt, pass_hash, forcepwchg, pass_expire) = 
				(l_acc.salt, l_acc.pass_hash, l_acc.forcepwchg, l_acc.pass_expire )
		WHERE email = l_login

	CALL gl_lib.gl_winMessage(%"Comfirmation",%"Your password has be updated, please don't forget it.\nWe cannot retrieve this password, only reset it.\n","exclamation")

	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
PRIVATE FUNCTION pass_ok(l_pass)
	DEFINE l_pass LIKE accounts.login_pass
	DEFINE l_gotUp, l_gotLow, l_gotNum, l_gotSym BOOLEAN
	DEFINE x,y SMALLINT

	IF l_pass IS NULL THEN
		ERROR %"Password can't be NULL"
		RETURN FALSE
	END IF
	IF LENGTH(l_pass) < 8 THEN
		ERROR %"Password is less than 8 characters"
		RETURN FALSE
	END IF

	LET l_gotNum = FALSE
	LET l_gotUp = FALSE
	LET l_gotLow = FALSE
	LET l_gotSym = FALSE

	DISPLAY "Pass:",l_pass
	FOR x = 1 TO LENGTH(l_pass)
		IF l_pass[x] >= "0" AND l_pass[x] <= "9" THEN LET l_gotNum = TRUE CONTINUE FOR END IF
		IF l_pass[x] >= "A" AND l_pass[x] <= "Z" THEN LET l_gotUp = TRUE CONTINUE FOR END IF
		IF l_pass[x] >= "a" AND l_pass[x] <= "z" THEN LET l_gotLow = TRUE CONTINUE FOR END IF
		LET y = 1
		WHILE y <= c_sym.getLength()
			DISPLAY "Symbol check:",l_pass[x]," sym:",c_sym.getCharAt(y)
			IF l_pass[x] = c_sym.getCharAt(y) THEN LET l_gotSym = TRUE CONTINUE FOR END IF
			LET y = y + 1
		END WHILE
		ERROR %"Password contains an iilegal character:", l_pass[x]
	END FOR

	IF NOT l_gotUp OR NOT l_gotLow THEN
		ERROR %"Password must contain a mix of upper and lower case letters."
		RETURN FALSE
	END IF
	IF NOT l_gotNum THEN
		ERROR %"Password must contain at least one number."
		RETURN FALSE
	END IF
	IF NOT l_gotSym THEN
		ERROR %"Password must contain at least one symbol ("||c_sym||")."
		RETURN FALSE
	END IF

	RETURN TRUE
END FUNCTION