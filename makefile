
ifndef GENVER
export GENVER=320
endif
export FGLRESOURCEPATH=../etc
export FGLPROFILE=../etc/profile
export FGLSQLDEBUG=0
export FGLCOVERAGE=0
export CLASSPATH=$(FGLDIR)/testing_utilities/ggc/ggc.jar:$(FGLDIR)/lib/fgl.jar
APPNAME=logindemo
GARNAME=loginDemo$(GENVER)
GARFILE=distbin/$(GARNAME).gar
WARFILE=packages/loginDemo$(GENVER).war
PROG=bin$(GENVER)/loginDemo.42r
SRC=\
	src/crypt.4gl \
	src/gl_lib.4gl \
	src/lib_login.4gl \
	src/lib_secure.4gl \
	src/logindemo.4gl \
	src/logindemo.per \
	src/login.per \
	src/mk_db.4gl \
	src/new_acct.per \
	src/schema.inc 

all: $(PROG) gar

$(PROG): $(SRC)
	gsmake loginDemo$(GENVER).4pw

run: $(PROG)
	cd bin$(GENVER) && fglrun loginDemo.42r

clean:
	rm -rf bin* packages logs test/*.guilog test/test_loginDemo.4gl src/*.cov

# -------------
# GAR Files

packages: 
	mkdir packages	

gar: $(GARFILE)

$(GARFILE): packages bin$(GENVER)/loginDemo.42r
	$(info Building Genero Archive ...)
	gsmake -t loginDemo$(GENVER) loginDemo$(GENVER).4pw

undeploy:
	gasadmin gar --disable-archive $(GARNAME)
	gasadmin gar --undeploy-archive $(GARNAME)

deploy: $(GARFILE)
	gasadmin gar --deploy-archive $(GARFILE)
	gasadmin gar --enable-archive $(GARNAME)


# -------------
# JGAS War
war: $(WARFILE)

$(WARFILE): $(GARFILE)
	$(info Building Genero WAR File ...)
	fglgar war --input-gar $^ --output $@

runwar: $(WARFILE)
	fglgar run --war $^

launchurl: $(WARFILE)
	google-chrome	http://localhost:8080/$(GARNAME)/ua/r/$(APPNAME)

# -------------------
# Genero Ghost Client

test/loginDemo.guilog: $(PROG)
	if [ ! -d test ]; then \
		mkdir test; \
	fi; \
	cd bin$(GENVER) && fglrun --start-guilog=../$@ loginDemo.42r

test/test_loginDemo.4gl: test/loginDemo.guilog
	cd test; \
	rm -f test_loginDemo.4gl; \
	java com.fourjs.ggc.generator.GhostGenerator loginDemo.guilog com.fourjs.ggc.generator.BDLSimpleProducer test_loginDemo.4gl

bin$(GENVER)/test_loginDemo.42m: test/test_loginDemo.4gl
	cd bin$(GENVER) && fglcomp ../test/test_loginDemo.4gl

runtest: bin$(GENVER)/test_loginDemo.42m
	cd bin$(GENVER) && fglrun test_loginDemo.42m "fglrun loginDemo.42r"

#	cd test && fglrun test_loginDemo.42m http://localhost:6394/ua/r/loginDemo

# -------------------
# Converage

runcov: $(PROG)
	cd bin$(GENVER) && FGLCOV=1 fglrun loginDemo.42r; \
	mv *.cov ../src; \
	cd ../src; \
	fglrun --merge-cov logindemo.4gl; \
	cat logindemo.4gl.cov
