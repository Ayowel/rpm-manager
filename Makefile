BUILD_DIR=build

.PHONY: all build-rpm build-scripts doc

all: build-scripts doc

doc:
	doxygen Doxyfile

build-scripts: build build/rpm-manager.sh

build-rpm:
	echo 'Not supported'
	false

build:
	mkdir -p build

build/rpm-manager.sh: main.sh build
	awk '{if($$1=="source"){system("cat "$$2); print "\n"}else{print $$0}}' '$<' >"$@"
