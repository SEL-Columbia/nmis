VERSION=0.95
DATE=$(shell date)
STYLES = ./styles.css
STYLES_LESS = ./styles.less
STYLES_MIN = ./styles.min.css
LESS_COMPRESSOR ?= `which lessc`
#UGLIFY_JS ?= `which uglifyjs`
#WATCHR ?= `which watchr`

# this is all based on bootstrap's Makefile

build:
	@@if test ! -z ${LESS_COMPRESSOR}; then \
		sed -e 's/@VERSION/'"v${VERSION}"'/' -e 's/@DATE/'"${DATE}"'/' <${STYLES_LESS} >${STYLES_LESS}.tmp; \
		lessc ${STYLES_LESS}.tmp > ${STYLES_MIN} --compress; \
		rm -f ${STYLES_LESS}.tmp; \
		echo "Stylesheets successfully built! - `date`"; \
	else \
		echo "You must have the LESS compiler installed in order to build Bootstrap."; \
		echo "You can install it by running: npm install less -g"; \
	fi
