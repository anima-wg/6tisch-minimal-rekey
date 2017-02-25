DRAFT:=draft-richardson-6tisch-minimal-rekey
VERSION:=$(shell ./getver ${DRAFT}.mkd )

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt

%.xml: %.mkd
	kramdown-rfc2629 ${DRAFT}.mkd >${DRAFT}.xml

%.txt: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc $? $@

%.html: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --html -o $@ $?

.PRECIOUS: ${DRAFT}.xml

version:
	echo Version: ${VERSION}

