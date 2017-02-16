
ifndef GENVER
export GENVER=300
endif
export FGLRESOURCE=../etc
APPNAME=logindemo
GARNAME=loginDemo$(GENVER)
GARFILE=packages/$(GARNAME).gar
WARFILE=packages/loginDemo310.war

all: bin$(GENVER)/loginDemo.42r packages $(GARFILE)

bin$(GENVER)/loginDemo.42r:
	gsmake loginDemo$(GENVER).4pw

run: bin$(GENVER)/loginDemo.42r
	cd bin$(GENVER) && fglrun loginDemo.42r

clean:
	rm -rf bin* packages logs

packages: 
	mkdir packages	

packages/loginDemo300.gar: bin300/loginDemo.42r
	fglgar --gar --output $@ --application gas300/$(APPNAME).xcf

packages/loginDemo310.gar: bin310/loginDemo.42r
	fglgar gar --output $@ --application gas310/$(APPNAME).xcf

$(WARFILE): $(GARFILE)
	fglgar war --input-gar $^ --output $@

runwar: $(WARFILE)
	fglgar run --war $^

launchurl: $(WARFILE)
	google-chrome	http://localhost:8080/$(GARNAME)/ua/r/$(APPNAME)

enable:
	gasadmin --enable-archive $(GARNAME)

undeploy:
	gasadmin --undeploy-archive $(GARNAME)

disable:
	gasadmin --disable-archive $(GARNAME)

deploy: $(GARFILE)
	gasadmin --deploy-archive $(GARFILE)

