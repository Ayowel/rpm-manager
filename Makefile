BUILD_DIR=build

.PHONY: all audit lint test coverage build-rpm build-scripts doc quick-package package

all: package audit doc

clean:
	rm -rf build docs coverage rpm-manager.tar.gz

doc:
	doxygen tools/Doxyfile

audit: lint test coverage

lint:
	shellcheck --shell bash main.sh src/*

test:
	bats --tap test

coverage:
	kcov --bash-dont-parse-binary-dir --include-path=src,main.sh coverage bats --tap test

package: build-scripts licenses
	find build/licenses -type f -exec chmod 644 {} \;
	find build -type d -exec chmod 755 {} \;
	chmod 755 build/rpm-manager
	tar -czf rpm-manager.tar.gz --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2021-01-01' -C build .

quick-package: build-scripts licenses
	tar -czf rpm-manager.tar.gz -C build .

doc-package: doc
	tar -czf rpm-manager-doc.tar.gz --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2021-01-01' -C docs/html .

build-scripts: build build/rpm-manager

build-rpm:
	echo 'Not supported'
	false

build:
	mkdir -p $@

build/licenses:
	mkdir -p $@

build/licenses/shell-utilities.LICENSE: build/licenses
	cp vendors/shell-utilities/LICENSE $@

build/licenses/LICENSE: build/licenses
	cp LICENSE $@

licenses: build/licenses/LICENSE build/licenses/shell-utilities.LICENSE

build/rpm-manager: main.sh build
	awk '{if($$1=="source"){system("cat "$$2); print "\n"}else{print $$0}}' '$<' >"$@"
