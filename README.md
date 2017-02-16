Security Library Demo
=====================

A simple login style demo using encrypted passwords and an encrypted xml config file

With Genero 3.00 the passwords are hashed using SHA256

With Genero 3.10 the passwords are hashed using BCRYPT ( Blowfish )

## Structure of folders
* src: Genero source code
* src/forms: Genero screen forms
* src/lib: Genero library source code
* etc:  genero styles / action defaults / schema files / logindemo.db etc
* gas300: gas .xcf files for running the demo via the GAS
* bin: Created a compile time for the runnable object files
* logs: Created a runtime for logging

## Building - Multiple platform
This prject requires Genero Studio 3.00 or greater installed and licensed.

Either use GeneroStudios main UI or build from command line using:
```
gsmake loginDemo300.4pw
```

## Building Extra - Linux / Mac ( assuming gnu make installed )
You build and deploy a GAR file for the application using the makefile
```
$ make gar
$ make deploy
```

With Genero 3.10 you can also build a WAR file and run using JGAS
```
$ make runwar
```

## Running
You can either run from GeneroStudio UI or run from the command line using:
```
$ cd bin300
$ FGLRESOURCEPATH=../etc; fglrun loginDemo.42r
```

or Run via the Genero Application Server.

The GAS xcf file ( in the GAS300 folder ) has a resource defined of res.path.myhome - this should be edited to point to the base
directory where you have checked out this demo to, ie the expected path for the demo application is: $(res.path.myhome)/loginDemo

Run the deployed GAR file using http://<server>/gas/ua/r/glogindemo

Run the JGAS WAR using http://<server>:8080/loginDemo310/ua/r/logindemo

## Database

### SQLite
The demo comes with an sqlite database in etc/logindemo.db

This is used by default, it comes with one test account, User: test@test.com Password: T3st.T3st

NOTE: SQLite is single user only, if you to deploy this on a server for multiple people to try then use Informix

### Informix
You'll need to change the etc/profile and commend out the driver line for Sqlite and uncomment the informix one. eg:
```
#dbi.default.driver = "dbmsqt3xx"
dbi.default.driver = "dbmifx9x"
```
The studio project sets DBNAME to "logindemo" so you can just create a new empty datebase called logindemo then run the mk_db.42r to create the table.

## Source files
A brief descrption of the source files included in this demo
* crypt.4gl: A simple program to encrypted an xml config file
* gl_lib.4gl: A cut-down version of a generic Genero library
* lib_login.4gl: Login specific library functions used by the loginDemo program
* lib_secure.4gl: The Security Library
* logindemo.4gl: The demo program main source
* logindemo.per: The main screen form for the demo
* login.per: Login screen form
* mk_db.4gl: Program to create the database table 'accounts' used by the demo
* new_acct.per: New account screen form
* schema.inc: Contains the SCHEMA statement for the name of the database

## The etc folder
A brief descrption of the files in the etc folder
* .creds.xml: The encrypted version of creds.xml file
* creds.xml: A simple example creditials XML file
* default.4ad: Genero Action Defaults
* default.4st: Genero Styles
* logindemo.4db: Genero Studio database schema file
* logindemo.db: SQLite demo database

## The Security Library ( lib_secure.4gl )
This is the library that handles all the encryption and security related code. The main public functions are:
* glsec_genPassword: Generate a random password that conforms to a set of rules
* glsec_genSalt: Generate a random salt string
* glsec_genHash: Generate a hash of a password using a salt string
* glsec_fromBase64: Get a string from base64 string or raise an error prompt
* glsec_toBase64: Get base64 version of a string or raise an error prompt
* glsec_getCreds: Retrieve a username/password combination from an encrypted xml config file
* glsec_updCreds: Update creditials in an encrypted XML File

See the code for more details on passed and returned values.
