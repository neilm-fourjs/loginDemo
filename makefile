
ifndef GENVER
export GENVER=300
endif
export FGLRESOURCE=../etc
export FGLPROFILE=../etc/profile
export FGLSQLDEBUG=0
export FGLCOVERAGE=0
APPNAME=logindemo
GARNAME=loginDemo$(GENVER)
GARFILE=packages/$(GARNAME).gar
WARFILE=packages/loginDemo310.war

all: build gar

build:
	gsmake loginDemo$(GENVER).4pw

run: bin$(GENVER)/loginDemo.42r
	cd bin$(GENVER) && fglrun loginDemo.42r

clean:
	rm -rf bin* packages logs

# -------------
# GAR Files

packages: 
	mkdir packages	

gar: $(GARFILE)

packages/loginDemo$(GENVER).gar: packages bin$(GENVER)/loginDemo.42r
	$(info Building Genero Archive ...)
	@cp gas$(GENVER)/MANIFEST .
	@zip -qr $(GARFILE) MANIFEST gas$(GENVER)/g*.xcf bin$(GENVER)/* etc/.creds.xml etc/*.4?? etc/*.db etc/profile
	@rm MANIFEST

# -------------
# GAS Deploy

undeploy:
	gasadmin --disable-archive $(GARNAME)
	gasadmin --undeploy-archive $(GARNAME)

deploy: $(GARFILE)
	gasadmin --deploy-archive $(GARFILE)
	gasadmin --enable-archive $(GARNAME)


# -------------
# JGAS War

$(WARFILE): $(GARFILE)
	$(info Building Genero WAR File ...)
	fglgar war --input-gar $^ --output $@

runwar: $(WARFILE)
	fglgar run --war $^

launchurl: $(WARFILE)
	google-chrome	http://localhost:8080/$(GARNAME)/ua/r/$(APPNAME)

