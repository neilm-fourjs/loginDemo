# Test program for 'lib_secureFile'
#
# This program will 

IMPORT FGL lib_secureFile

MAIN
	DEFINE l_usr, l_pwd     STRING
	DEFINE l_plain_file     STRING
	DEFINE l_encrypted_file STRING
	DEFINE l_cert_file      STRING
	DEFINE l_certkey_file   STRING

	LET l_plain_file     = fgl_getenv("PLAINFILE")
	IF l_plain_file.getLength() < 2 THEN LET l_plain_file = ".creds.xml" END IF
	LET l_encrypted_file = fgl_getenv("SECUREFILE")
	IF l_encrypted_file.getLength() < 2 THEN LET l_encrypted_file = ".credsEnc.xml" END IF
	LET l_cert_file      = fgl_getenv("SECURECERT")
	IF l_cert_file.getLength() < 2 THEN LET l_cert_file = "MyCert.crt" END IF
	LET l_certkey_file   = fgl_getenv("SECURECKEY")
	IF l_certkey_file.getLength() < 2 THEN LET l_certkey_file = "MyCert.key" END IF

	DISPLAY SFMT("Plain: %1 Encrypted: %2 Cert: %3 CertKey: %4",
			l_plain_file, l_encrypted_file, l_cert_file, l_certkey_file)

# Encrypt the XML file with a certificate
	DISPLAY "Encrypt ..."
	IF encryptXMLFile(l_plain_file, l_encrypted_file, l_cert_file) THEN
		DISPLAY "Encrypted Okay"
	ELSE
		EXIT PROGRAM
	END IF

# Decrypt the XML file with a certificate and retrieve a specific set of credentials.
	DISPLAY "Decrypt ..."
	CALL decryptXMLFile(l_encrypted_file, l_certkey_file, "email") RETURNING l_usr, l_pwd
	DISPLAY SFMT("User: %1 Pass: %2", l_usr, l_pwd)
END MAIN
