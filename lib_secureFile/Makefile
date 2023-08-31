
export FGLWSDEBUG=0
# Source unencrypted creds
export PLAINFILE=../etc/.creds2.xml

# Variables for actual encrypted file and cert+key to use.
export SECUREFILE=../etc/.creds2Enc.xml
export SECURECERT=../etc/MyCert.crt
export SECURECKEY=../etc/MyCert.key

# Test variables:
#export SECUREFILE=../etc/.credsEncTest.xml
#export SECURECERT=../etc/TestCert.crt
#export SECURECKEY=../etc/TestCert.key

all: crypt2.42m lib_secureFile.42m $(SECURECKEY) $(SECURECERT)

crypt2.42m: crypt2.4gl lib_secureFile.4gl
	fglcomp $^

lib_secureFile.42m: lib_secureFile.4gl
	fglcomp $^

run: crypt2.42m
	fglrun crypt2.42m

clean:
	rm *.42?

# Generate cert and key

$(SECURECKEY):
	@echo "Make key file '$(SECURECKEY)' :"
	openssl req -newkey rsa:2048 -nodes -keyout $@ -out temp.csr
	rm -f temp.csr

$(SECURECERT):
	@echo "Make certificate file '$(SECURECERT)' :"
	openssl req -key $(SECURECKEY) -new -x509 -days 365 -out $@
