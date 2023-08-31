
# lib_secureFile library

This library and program are used for handling passwords required at runtime by web services and applications.

The idea is all the passwords are stored in an encrypted .xml file that's read runtime.


## Example .xml file to encrypt

```
<Secure>
	<db>
		<password>TheDBPassword</password>
	</db>
	<email>
		<user>me@test.com</user>
		<password>ThisIsMyPassword</password>
	</email>
	<sms>
		<user>me</user>
		<password>ThisIsMyPassword</password>
	</sms>
</Secure>
```


## Contents of this folder

# README.md - this file
# crypt2.4gl - Genero Source file to use the library to encrypt the .xml file
# lib_secureFile.4gl - Genero Source file for the library.
# Makefile - Make file compiling and generating the certificate if it's missing.


## Encrypting the .xml file

To encrypt the xml file you run the 'crypt2' program, this will use the following environment variables to find the required files:

# PLAINFILE - plain text source .xml file with clear text passwords, the default file name is .creds.xml
# SECUREFILE - This will be the encrypted version of the PLAINFILE, the default name is .credsEnc.xml
# SECURECERT - This is certificate used to encrypt the xml file, default name is MyCert.crt
# SECURECKEY - This is the associated certificate 'key' used to decrypt the xml file, default name is MyCert.key

NOTE: only the SECUREFILE and the SECURECKEY are required at runtime to access the secure file.


## Makefile

The 'Makefile' can create the certificate files if they are missing.
The 'Makefile' also set the environment variables to suggested values, ie ../etc/<filename>

The 'run' target will run the crypt2 program to encrypt the .xml file and then it will use one of the functions to retrieve an example username and password.
Expected output should be:
```
$ make run
fglrun crypt2.42m
Plain: ../etc/.creds.xml Encrypted: ../etc/.credsEnc.xml Cert: ../etc/MyCert.crt CertKey: ../etc/MyCert.key
Encrypt ...
Encrypted Okay
Decrypt ...
User: me@test.com Pass: ThisIsMyPassword
```

## Updating / Adding username/passwords

Edit the plain text xml file to add or change the required values, then run the crypt2 program.
ie: assuming the files are in ./etc and this code is in ./lib_secureFile
```
cd ./lib_secureFile
vi ../etc/.creds.xml
make run
```

## Accessing Passwords from the Application / Services

These passwords are read by calling one of the two functions.
If you only need the password then you call 'getSecurePassword'
```
	LET l_db_password = lib_secureFile.getSecurePassword("db")
```
or if you also need the user name then you call 'getSecureUsernamePassword'
```
	CALL lib_secureFile.getSecureUsernamePassword("email") RETURNING l_email_user, l_email_password
```


