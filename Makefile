# Refs:
# https://www.zotero.org/support/dev/client_coding/building_the_standalone_client

target: build-zotero-client build-zotero-standalone-build
	echo "Rebuild success"

build-zotero-client:
	echo "npm build Zetero client"
	cd zotero-client; npm run build

build-zotero-standalone-build:
	echo "build stand alone App"
	cd zotero-standalone-build; ./scripts/dir_build

# Bootstrap Zotero dev environment
prepare-env:
	git clone --recursive https://github.com/zotero/zotero zotero-client
	git clone --recursive https://github.com/zotero/zotero-build
	git clone --recursive https://github.com/zotero/zotero-standalone-build
	cd zotero-standalone-build; ./fetch_xulrunner.sh -p m
	cd zotero-standalone-build; ./fetch_pdftools

# Check Zotero dev environment
check-env:
	cd zotero-standalone-build; scripts/check_requirements

run:
	./zotero-standalone-build/staging/Zotero.app/Contents/MacOS/zotero

debug:
	#./zotero-standalone-build/staging/Zotero.app/Contents/MacOS/zotero -debugger --jsconsole -ZoteroDebugText
	./zotero-standalone-build/staging/Zotero.app/Contents/MacOS/zotero -ZoteroDebugText
