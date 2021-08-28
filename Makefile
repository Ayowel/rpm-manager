BUILD_DIR=build

.PHONY: all audit lint test build-rpm build-scripts doc quick-package package

all: audit doc-package package verify

clean:
	rm -rf build docs coverage rpm-manager.tar.gz

doc:
	doxygen tools/Doxyfile

audit: lint test

lint:
	shellcheck --shell bash main.sh src/*

test:
	kcov --bash-dont-parse-binary-dir --include-path=src,main.sh coverage bats --tap test

verify: build/rpm-manager
	MANAGER=$< bats --tap test/inte_*.bats

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

build/licenses/LICENSE: build/licenses
	cp LICENSE $@

licenses: build/licenses/LICENSE

build/rpm-manager: main.sh build
	awk '{if($$1=="source"){system("cat "$$2); print "\n"}else{print $$0}}' '$<' >"$@"
