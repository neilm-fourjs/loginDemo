# Test program for 'lib_secureFile'

IMPORT FGL lib_secureFile

MAIN
	DEFINE l_usr, l_pwd STRING

# Encrypt the XML file with a certificate
	IF encryptXMLFile("../etc/creds.xml", "../etc/.creds2.xml", "../etc/MyCert.crt") THEN
		DISPLAY "Encrypted Okay"
	ELSE
		EXIT PROGRAM
	END IF

# Decrypt the XML file with a certificate and retrieve a specific set of credentials.
	CALL decryptXMLFile("../etc/.creds2.xml", "../etc/MyCert.key", "email") RETURNING l_usr, l_pwd
	DISPLAY SFMT("User: %1 Pass: %2", l_usr, l_pwd)
END MAIN

