-- test program to generate a hash from a password.

IMPORT FGL lib_secure

MAIN
	DEFINE l_login_pass, l_hash_type, l_salt, l_pass_hash STRING

	LET l_login_pass = ARG_VAL(1)
	LET l_hash_type  = lib_secure.glsec_getHashType()
	LET l_salt       = lib_secure.glsec_genSalt(l_hash_type)
	LET l_pass_hash  = lib_secure.glsec_genPasswordHash(l_login_pass, l_salt, l_hash_type)

	DISPLAY "Pass:", l_login_pass, " - Length(", (l_login_pass.getLength() USING "<<<"), ")"
	DISPLAY "Type:", l_hash_type
	DISPLAY "Hash:", l_pass_hash, " - Length(", (l_pass_hash.getLength() USING "<<<"), ")"

END MAIN
