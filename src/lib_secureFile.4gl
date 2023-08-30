#+ This library is used to encypt the data in an xml file, the xml should look something like this:
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
# The file is encrypted using a certificate:
# openssl req -newkey rsa:2048 -nodes -keyout MyCert.key -out MyCert.csr
# openssl req -key MyCert.key -new -x509 -days 365 -out MyCert.crt
#

IMPORT xml

--------------------------------------------------------------------------------
-- Encrypt an XML file with a certificate
FUNCTION encryptXMLFile(l_file_in STRING, l_file_out STRING, l_cert_file STRING) RETURNS BOOLEAN
	DEFINE l_doc    xml.DomDocument
	DEFINE l_root   xml.DomNode
	DEFINE l_enc    xml.Encryption
	DEFINE l_symkey xml.CryptoKey
	DEFINE l_kek    xml.CryptoKey
	DEFINE l_cert   xml.CryptoX509
	LET l_doc = xml.DomDocument.Create()
	# Notice that whitespaces are significant in cryptography,
	# therefore it is recommended to remove unnecessary ones
	CALL l_doc.setFeature("whitespace-in-element-content", FALSE)
	TRY
		# Load XML file to be encrypted
		CALL l_doc.load(l_file_in)
		LET l_root = l_doc.getDocumentElement()
	CATCH
		DISPLAY SFMT("XML Load Error: %1 : %2", status, err_get(status) )
		RETURN FALSE
	END TRY
	TRY
		# Load the X509 certificate and retrieve the public RSA key
		# for key-encryption purpose
		LET l_cert = xml.CryptoX509.Create()
		CALL l_cert.loadPEM(l_cert_file)
	CATCH
		DISPLAY SFMT("Certificate '%1' Failed: %2 : %3", l_cert_file, status, err_get(status) )
		RETURN FALSE
	END TRY
	TRY
		LET l_kek = l_cert.createPublicKey("http://www.w3.org/2001/04/xmlenc#rsa-1_5")
		# Generate symmetric key for XML encryption purpose
		LET l_symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
		CALL l_symkey.generateKey(NULL)
		# Encrypt the entire document
		LET l_enc = xml.Encryption.Create()
		CALL l_enc.setKey(l_symkey)           # Set the symmetric key to be used
		CALL l_enc.setKeyEncryptionKey(l_kek) # Set the key-encryption key to
		# be used for protecting the symmetric key
		CALL l_enc.setCertificate(l_cert) # Set the certificate to be added
		# (not mandatory)
		CALL l_enc.encryptElement(l_root) # Encrypt
		# Save encrypted document back to disk
		CALL l_doc.setFeature("format-pretty-print", TRUE)
		CALL l_doc.save(l_file_out)
	CATCH
		DISPLAY SFMT("Unable to encrypt XML file %1 : %2", status, err_get(status) )
		RETURN FALSE
	END TRY
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
-- Decrypt an XML file with a certificate and retrieve a specific set of credentials.
FUNCTION decryptXMLFile(l_file_in STRING, l_cert_file STRING, l_creds STRING) RETURNS(STRING, STRING)
	DEFINE l_doc        xml.DomDocument
	DEFINE l_node       xml.DomNode
	DEFINE l_enc        xml.Encryption
	DEFINE l_symkey     xml.CryptoKey
	DEFINE l_kek        xml.CryptoKey
	DEFINE l_list       xml.DomNodeList
	DEFINE l_usr, l_pwd STRING
	LET l_doc = xml.DomDocument.Create()
	# Notice that whitespaces are significant in cryptography,
	# therefore it is recommended to remove unnecessary ones
	CALL l_doc.setFeature("whitespace-in-element-content", FALSE)
	TRY
		# Load encrypted XML file
		CALL l_doc.load(l_file_in)
		# Retrieve encrypted node (if any) from the document
		LET l_list = l_doc.getElementsByTagNameNS("EncryptedData", "http://www.w3.org/2001/04/xmlenc#")
		IF l_list.getCount() == 1 THEN
			LET l_node = l_list.getItem(1)
		ELSE
			DISPLAY "No encrypted node found"
			RETURN NULL, NULL
		END IF
		# Load the private RSA key
		LET l_kek = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#rsa-1_5")
		CALL l_kek.loadPEM(l_cert_file)
		# Decrypt the entire document
		LET l_enc = xml.Encryption.Create()
		CALL l_enc.setKeyEncryptionKey(l_kek) # Set the key-encryption key to
		# decrypted the protected symmetric key
		CALL l_enc.decryptElement(l_node) # Decrypt
		# Retrieve the embedded symmetric key for futher usage and display
		# info about it
		LET l_symkey = l_enc.getEmbeddedKey()
		# Encrypted document back to disk
		CALL l_doc.setFeature("format-pretty-print", TRUE)
	CATCH
		DISPLAY "Unable to decrypt XML file :", STATUS
		RETURN NULL, NULL
	END TRY

	# get data require from file
	#...
	LET l_list = l_node.selectByXPath(SFMT("//%1", l_creds), NULL)
		IF l_list.getCount() == 1 THEN
			LET l_node = l_list.getItem(1)
		ELSE
			DISPLAY SFMT("Not found %1 node", l_creds)
			RETURN NULL, NULL
		END IF

	LET l_list = l_node.getElementsByTagName("user")
	IF l_list.getCount() == 1 THEN LET l_usr = l_list.getItem(1).getFirstChild().toString() END IF
	LET l_list = l_node.getElementsByTagName("password")
	IF l_list.getCount() == 1 THEN LET l_pwd = l_list.getItem(1).getFirstChild().toString() END IF
	RETURN l_usr, l_pwd
END FUNCTION