#+ Provide function to:
#+ * Handle an encrypted XML config file
#+ * Encrypt / Decrypt a password & salt pair for storing in a databaase
#+
#+ This module initially written by: Neil J.Martin ( neilm@4js.com ) 
#+

IMPORT xml
IMPORT os
IMPORT security
IMPORT util
IMPORT FGL gl_lib

-- Private variables:
DEFINE m_doc xml.domDocument
DEFINE m_user_node, m_pass_node xml.domNode
DEFINE m_file STRING

CONSTANT DEFPASSLEN=16
CONSTANT c_sym = "!$%^&*,.;@#?<>"
--------------------------------------------------------------------------------
#+ Generate a random password that conforms to the follow set of rules:
#+ Password must be at least DEFPASSLEN chars long
#+ Password must contain at least one number
#+ Password must contain at least one symbol
#+
#+ @return String - password
FUNCTION glsec_genPassword()
	DEFINE l_pass CHAR(DEFPASSLEN)
	DEFINE x,y SMALLINT
-- because it's base64 encoded it will return 16 chars or larger!!
	WHILE TRUE
		LET l_pass = security.RandomGenerator.CreateRandomString( DEFPASSLEN )
		FOR x = 1 TO DEFPASSLEN -- make sure we have at least one number
			IF l_pass[x] MATCHES "[0-9]" THEN EXIT WHILE END IF
		END FOR
	END WHILE
-- Add a random symbol to the random string.
	CALL util.math.srand()
	LET x = util.math.rand(DEFPASSLEN)
	LET y = util.math.rand( c_sym.getLength() )
	LET l_pass[x] = c_sym.getCharAt(y)
--	DISPLAY "Pass:",l_pass
	RETURN l_pass
END FUNCTION
--------------------------------------------------------------------------------
#+ Generate a random salt string
FUNCTION glsec_genSalt()
	RETURN security.RandomGenerator.CreateRandomString( 16 )
END FUNCTION
--------------------------------------------------------------------------------
#+ Generate a hash or a password using a salt string
#+
#+ @param l_pass - String - Password
#+ @param l_salt - String - The salt value
#+ @return String - An Encrypted string using SHA256
FUNCTION glsec_genHash(l_pass,l_salt)
	DEFINE l_pass, l_salt STRING
	DEFINE l_hash STRING
	DEFINE l_dgst security.Digest

	LET l_pass = l_pass.trim()
	LET l_salt = l_salt.trim()
  TRY
    LET l_dgst = security.Digest.CreateDigest("SHA256")
    CALL l_dgst.AddStringData(l_pass||l_salt)
    LET l_hash = l_dgst.DoBase64Digest()
  CATCH
    CALL gl_logIt( "ERROR:"||STATUS||":"||SQLCA.SQLERRM)
  END TRY

	RETURN l_hash
END FUNCTION
--------------------------------------------------------------------------------
#+ Get a string from base64 string or raise an error prompt
#+
#+ @param l_str - String
#+ @return String or NULL if failed.
FUNCTION glsec_fromBase64( l_str )
	DEFINE l_str STRING

	IF l_str IS NULL THEN RETURN NULL END IF
	TRY
		LET l_str = security.Base64.toString( l_str )
	CATCH
		CALL gl_winMessage("Error","Error in security module!\n"||SQLCA.SQLERRM,"exclamation")
		LET l_str = NULL
	END TRY

	RETURN l_str
END FUNCTION
--------------------------------------------------------------------------------
#+ Get base64 version of a string or raise an error prompt
#+
#+ @param l_str - String
#+ @return String or NULL if failed.
FUNCTION glsec_toBase64( l_str )
	DEFINE l_str STRING

	IF l_str IS NULL THEN RETURN NULL END IF
	TRY
		LET l_str = security.Base64.fromString( l_str )
	CATCH
		CALL gl_winMessage("Error","Error in security module!\n"||SQLCA.SQLERRM,"exclamation")
		LET l_str = NULL
	END TRY

	RETURN l_str
END FUNCTION
--------------------------------------------------------------------------------
#+ Retrieve a username/password combination from an encrypted xml config file
#+
#+ @param l_typ - String - The type of the data to return, eg: EMAIL / SMS provider creds
#+ @returns - Strings : username, password
FUNCTION glsec_getCreds(l_typ)
	DEFINE l_typ, l_user, l_pwd STRING
	DEFINE l_node xml.DomNode
	DEFINE l_enc xml.Encryption
	DEFINE l_symkey xml.CryptoKey
	DEFINE l_list xml.DomNodeList
	DEFINE l_key CHAR(32)

	IF m_file.getLength() < 2 THEN CALL get_credFile() END IF

	LET l_key = seclogit()

	LET m_doc = xml.DomDocument.Create()
# Notice that whitespaces are significants in crytography,
# therefore it is recommended to remove unnecessary whitespace.
	CALL m_doc.setFeature("whitespace-in-element-content",FALSE)
	TRY
		# Load encrypted XML file
		--DISPLAY "Loading xml ..."
		CALL m_doc.load(m_file)
		# Retrieve encrypted l_node (if any) from the document
		LET l_list = m_doc.getElementsByTagNameNS("EncryptedData","http://www.w3.org/2001/04/xmlenc#")
		IF l_list.getCount()==1 THEN
			LET l_node = l_list.getItem(1)
		ELSE
			CALL gl_lib.gl_logIt( "No encrypted l_node found" )
			EXIT PROGRAM 210
		END IF
		# Check if symmetric key name matches the expected "MySecretKey" (Not mandatory)
		--DISPLAY "Looking for key name ..."
		LET l_list = l_node.selectByXPath("dsig:KeyInfo/dsig:KeyName[position()=1 and text()=\"MySecretKey\"]","dsig","http://www.w3.org/2000/09/xmldsig#")
		IF l_list.getCount()!=1 THEN
			CALL gl_lib.gl_logIt( "Key name doesn't match" )
			EXIT PROGRAM 211
		END IF
	CATCH
		CALL gl_logIt("Unable to load / process XML file :"||STATUS||":"||err_get(STATUS))
		EXIT PROGRAM 212
	END TRY

	TRY
		# Create symmetric AES256 key for XML decryption purpose
		LET l_symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
		CALL l_symkey.setKey(l_key) # password of 256 bits
		# Decrypt the entire document
		LET l_enc = xml.Encryption.Create()
		CALL l_enc.setKey(l_symkey) # Set the symmetric key to be used 
		CALL l_enc.decryptElement(l_node) # Decrypt 
		# Save encrypted document back to disk
		CALL m_doc.setFeature("format-pretty-print",TRUE)
		--CALL l_doc.save("DecryptedXMLFile.xml")
		--DISPLAY l_doc.saveToString()
		--DISPLAY "Successful decrypted"
	CATCH
		CALL gl_lib.gl_logIt("Unable to decrypt XML file :"||STATUS||":"||err_get(STATUS))
		EXIT PROGRAM 213
	END TRY

	LET l_list = m_doc.selectByXPath("//"||l_typ||"/user","")
	IF l_list.getCount() < 1 THEN 
		--DISPLAY "Failed to find:",l_typ
	ELSE
		LET l_node = l_list.getItem(1)
		LET m_user_node = l_node.getFirstChild()
		LET l_user = m_user_node.getNodeValue()
		--DISPLAY l_typ," User:",l_usr
	END IF

	LET l_list = m_doc.selectByXPath("//"||l_typ||"/password","")
	IF l_list.getCount() < 1 THEN 
		--DISPLAY "Failed to find:",l_typ
	ELSE
		LET l_node = l_list.getItem(1)
		LET m_pass_node = l_node.getFirstChild()
		LET l_pwd = m_pass_node.getNodeValue()
		--DISPLAY l_typ," Pass:",l_pwd
	END IF

	RETURN l_user, l_pwd
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION glsec_updCreds(l_typ, l_user, l_pass)
	DEFINE l_typ, l_user, l_pass, l_old_usr, l_old_pass STRING
	DEFINE l_root xml.DomNode
	DEFINE enc xml.Encryption
	DEFINE symkey xml.CryptoKey
	DEFINE l_myKey CHAR(32)
	DEFINE l_dte STRING
	DEFINE l_tim CHAR(5)

	CALL glsec_getCreds(l_typ) RETURNING l_old_usr, l_old_pass

	LET l_myKey = seclogit()
	LET l_tim = TIME
	LET l_dte = (TODAY USING "yyyymmdd")||l_tim[1,2]||l_tim[4,5]
	TRY
		LET l_root = m_doc.getDocumentElement()
		CALL m_user_node.setNodeValue( l_user )
		CALL m_pass_node.setNodeValue( l_pass )
		# CALL m_doc.save("DecryptedXMLFile.xml")
		IF NOT os.Path.rename( m_file, m_file||l_dte ) THEN
			CALL gl_lib.gl_logIt("Failed to backup creds file:"||STATUS||":"||ERR_GET(STATUS))
			RETURN FALSE
		END IF
		# Create symmetric AES256 key for XML encryption purposes
		LET symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
		CALL symkey.setKey(l_mykey) # password of 256 bits
		CALL symKey.setFeature("KeyName","MySecretKey") # Name the password in order to identify the key (Not mandatory)
		# Encrypt the entire document
		LET enc = xml.Encryption.Create()
		CALL enc.setKey(symkey) # Set the symmetric key to be used 
		CALL enc.encryptElement(l_root) # Encrypt 
		# Save encrypted document back to disk
		CALL m_doc.save( m_file ) 
	CATCH
		CALL gl_lib.gl_logIt("Unable to encrypt XML file :"||STATUS||":"||err_get(STATUS))
		RETURN FALSE
	END TRY 
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  PRIVATE FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Obfuscation Code
PRIVATE FUNCTION secchk(l_s)
	DEFINE l_s,l_e STRING
	DEFINE x SMALLINT
	FOR x = 11 TO 4 STEP -1
		LET l_e = l_e.append(l_s.getCharAt(x))
	END FOR
	RETURN l_e
END FUNCTION
--------------------------------------------------------------------------------
-- obfuscate our key
{PRIVATE} FUNCTION seclogit()
	DEFINE s1,s2,s3,s4 STRING
--TODO: fixme
	LET s1 = ASCII(62),ASCII(68),ASCII(62),ASCII(64),ASCII(66),ASCII(67),ASCII(69),ASCII(68),ASCII(68),ASCII(67),ASCII(66),ASCII(62),ASCII(62),ASCII(60),ASCII(60),ASCII(62)
	LET s2 = ASCII(67),ASCII(66),ASCII(62),ASCII(61),ASCII(67),ASCII(64),ASCII(69),ASCII(64),ASCII(60),ASCII(60),ASCII(62),ASCII(67),ASCII(62),ASCII(61),ASCII(64),ASCII(67)
	LET s3 = ASCII(62),ASCII(68),ASCII(62),ASCII(64),ASCII(66),ASCII(67),ASCII(69),ASCII(68),ASCII(68),ASCII(67),ASCII(66),ASCII(62),ASCII(62),ASCII(60),ASCII(60),ASCII(62)
	LET s4 = ASCII(67),ASCII(66),ASCII(62),ASCII(61),ASCII(67),ASCII(64),ASCII(69),ASCII(64),ASCII(60),ASCII(60),ASCII(62),ASCII(67),ASCII(62),ASCII(61),ASCII(64),ASCII(67)

	RETURN secchk(s1)||secchk(s2)||secchk(s3)||secchk(s4)
END FUNCTION
--------------------------------------------------------------------------------
-- Used to generate obfuscation code
PRIVATE FUNCTION b(s)
	DEFINE s,r STRING
	DEFINE x,c SMALLINT
	FOR x = 1 TO s.getLength()
		FOR c = 12 TO 127
			IF s.getCharAt(x) = ASCII(c) THEN
				LET r = r.append( "ASCII("||c||")," )
			END IF
		END FOR
	END FOR
	DISPLAY r
END FUNCTION
--------------------------------------------------------------------------------
#+ Sets the m_file module variable and validates that the file exists.
PRIVATE FUNCTION get_credFile()
	LET m_file = "../etc/.creds.xml"
	IF NOT os.Path.exists( m_file ) THEN
		CALL gl_lib.gl_logIt("Creditials File is Missing!")
	ELSE
		CALL gl_lib.gl_logIt("Creditials File is "||m_file)
	END IF
END FUNCTION
