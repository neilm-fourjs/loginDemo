
#+ This program is used to encypt the data in an xml file, the xml should look something like this:
{
<Secure>
        <email>
                <user>me@test.com</user>
                <password>ThisIsMyPassword</password>
        </email>
        <sms>
                <user>me</user>
                <password>ThisIsMyPassword</password>
        </sms>
</Secure>
}

IMPORT xml
IMPORT FGL lib_secure

MAIN
	CALL encrypt("../etc/creds.xml", "../etc/.creds.xml")
END MAIN
--------------------------------------------------------------------------------
FUNCTION encrypt(l_file_in, l_file_out)
  DEFINE doc xml.DomDocument
  DEFINE root xml.DomNode
  DEFINE enc xml.Encryption
  DEFINE symkey xml.CryptoKey
	DEFINE l_myKey CHAR(32)
	DEFINE l_file_in, l_file_out STRING

	LET l_myKey = lib_secure.seclogit()
	DISPLAY "Encrypting with :",l_mykey

  LET doc = xml.DomDocument.Create() 
  # Notice that white spaces are significant in crytography,
  # therefore it is recommended that you remove unnecessary ones
  CALL doc.setFeature("whitespace-in-element-content",FALSE)
  TRY
    # Load XML file to be encrypted
		DISPLAY "Loading source xml from ",l_file_in
    CALL doc.load(l_file_in)
		--CALL doc.save(l_file_out||".x")
    LET root = doc.getDocumentElement()
    # Create symmetric AES256 key for XML encryption purposes
    LET symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
    CALL symkey.setKey(l_mykey) # password of 256 bits
    CALL symKey.setFeature("KeyName","MySecretKey") # Name the password in order to identify the key (Not mandatory)
    # Encrypt the entire document
    LET enc = xml.Encryption.Create()
    CALL enc.setKey(symkey) # Set the symmetric key to be used 
    CALL enc.encryptElement(root) # Encrypt 
    # Save encrypted document back to disk
    CALL doc.setFeature("format-pretty-print",TRUE) 
		DISPLAY "Saving encrypted file:",l_file_out
    CALL doc.save(l_file_out)
  CATCH
    DISPLAY "Unable to encrypt XML file :",STATUS,"\n",err_get(STATUS)
  END TRY 
END FUNCTION
--------------------------------------------------------------------------------