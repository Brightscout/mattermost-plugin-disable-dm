GO:=go
GOARCH:=amd64
GOOS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
GOPATH ?= $(GOPATH:)

MANIFEST_FILE ?= plugin.json

PLUGINNAME=$(shell echo `grep '"'"id"'"\s*:\s*"' $(MANIFEST_FILE) | head -1 | cut -d'"' -f4`)
PLUGINVERSION=v$(shell echo `grep '"'"version"'"\s*:\s*"' $(MANIFEST_FILE) | head -1 | cut -d'"' -f4`)
PACKAGENAME=mattermost-plugin-$(PLUGINNAME)-$(PLUGINVERSION)

HAS_WEBAPP=$(shell if [ "$(shell grep -E '[\^"]webapp["][ ]*[:]' $(MANIFEST_FILE)  | wc -l)" -gt "0" ]; then echo "true"; fi)
HAS_SERVER=$(shell if [ "$(shell grep -E '[\^"]server["][ ]*[:]' $(MANIFEST_FILE)  | wc -l)" -gt "0" ]; then echo "true"; fi)

TMPFILEGOLINT=golint.tmp

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BOLD=`tput bold`
INVERSE=`tput rev`
RESET=`tput sgr0`

.PHONY: default .npminstall vendor setup-plugin build test clean check-style check-js check-go govet golint gofmt .distclean dist format fix-js fix-go trigger-release install-dependencies

default: dist

setup-plugin:
ifneq ($(HAS_WEBAPP),)
	@echo "export const PLUGIN_NAME = '`echo $(PLUGINNAME)`';" > webapp/src/constants/manifest.js
endif
ifneq ($(HAS_SERVER),)
	@echo "package config\n\nconst (\n\tPluginName = \""`echo $(PLUGINNAME)`"\"\n)" > server/config/manifest.go
endif

trigger-release:
	@if [ $$(git status --porcelain | wc -l) != "0" -o $$(git rev-list HEAD@{upstream}..HEAD | wc -l) != "0" ]; \
		then echo ${RED}"local repo is not clean"${RESET}; exit 1; fi;
	@echo ${BOLD}"Creating a tag to trigger circleci build-and-release job\n"${RESET}
	git tag $(PLUGINVERSION)
	git push origin $(PLUGINVERSION)

check-style: check-js check-go

check-js:
ifneq ($(HAS_WEBAPP),)
	@echo ${BOLD}Running ESLINT${RESET}
	@cd webapp && npm run lint
	@echo ${GREEN}"eslint success\n"${RESET}
endif

check-go: govet golint gofmt

govet:
ifneq ($(HAS_SERVER),)
	@go tool vet 2>/dev/null ; if [ $$? -eq 3 ]; then \
		echo "--> installing govet"; \
		go get golang.org/x/tools/cmd/vet; \
	fi
	@echo ${BOLD}Running GOVET${RESET}
	@cd server
	$(eval PKGS := $(shell go list ./... | grep -v /vendor/))
	@$(GO) vet -shadow $(PKGS)
	@echo ${GREEN}"govet success\n"${RESET}
endif

golint:
ifneq ($(HAS_SERVER),)
	@command -v golint >/dev/null ; if [ $$? -ne 0 ]; then \
		echo "--> installing golint"; \
		go get -u golang.org/x/lint/golint; \
	fi
	@echo ${BOLD}Running GOLINT${RESET}
	@cd server
	$(eval PKGS := $(shell go list ./... | grep -v /vendor/))
	@touch $(TMPFILEGOLINT)
	-@for pkg in $(PKGS) ; do \
		echo `golint $$pkg | grep -v "have comment" | grep -v "comment on exported" | grep -v "lint suggestions"` >> $(TMPFILEGOLINT) ; \
	done
	@grep -Ev "^$$" $(TMPFILEGOLINT) || true
	@if [ "$$(grep -Ev "^$$" $(TMPFILEGOLINT) | wc -l)" -gt "0" ]; then \
		rm -f $(TMPFILEGOLINT); echo ${RED}"golint failure\n"${RESET}; exit 1; else \
		rm -f $(TMPFILEGOLINT); echo ${GREEN}"golint success\n"${RESET}; \
	fi
endif

format: fix-js fix-go

fix-js:
ifneq ($(HAS_WEBAPP),)
	@echo ${BOLD}Formatting js giles${RESET}
	@cd webapp && npm run fix
	@echo "formatted js files\n"
endif

fix-go:
ifneq ($(HAS_SERVER),)
	@command -v goimports >/dev/null ; if [ $$? -ne 0 ]; then \
		echo "--> installing goimports"; \
		go get golang.org/x/tools/cmd/goimports; \
	fi
	@echo ${BOLD}Formatting go giles${RESET}
	@cd server
	@find ./ -type f -name "*.go" -not -path "./server/vendor/*" -exec goimports -w {} \;
	@echo "formatted go files\n"
endif

gofmt:
ifneq ($(HAS_SERVER),)
	@echo ${BOLD}Running GOFMT${RESET}
	@for package in $$(go list ./server/...); do \
		files=$$(go list -f '{{range .GoFiles}}{{$$.Dir}}/{{.}} {{end}}' $$package); \
		if [ "$$files" ]; then \
			gofmt_output=$$(gofmt -d -s $$files 2>&1); \
			if [ "$$gofmt_output" ]; then \
				echo "$$gofmt_output"; \
				echo ${RED}"gofmt failure\n"${RESET}; \
				exit 1; \
			fi; \
		fi; \
	done
	@echo ${GREEN}"gofmt success\n"${RESET}
endif

test:
ifneq ($(HAS_SERVER),)
	go test -v -coverprofile=coverage.txt ./...
endif

.npminstall:
ifneq ($(HAS_WEBAPP),)
	@echo ${BOLD}"Getting dependencies using npm\n"${RESET}
	cd webapp && npm install
	@echo "\n"
endif

vendor:
ifneq ($(HAS_SERVER),)
	@echo ${BOLD}"Getting dependencies using glide\n"${RESET}
	cd server && go get github.com/Masterminds/glide
	cd server && $(shell go env GOPATH)/bin/glide install
	@echo "\n"
endif

install-dependencies: .npminstall vendor

dist: install-dependencies check-style test build

build: .distclean $(MANIFEST_FILE)
	@echo ${BOLD}"Building plugin\n"${RESET}
	mkdir -p dist/$(PLUGINNAME)/
	cp $(MANIFEST_FILE) dist/$(PLUGINNAME)/

ifneq ($(HAS_WEBAPP),)
	# Build and copy files from webapp
	cd webapp && npm run build
	mkdir -p dist/$(PLUGINNAME)/webapp
	cp -r webapp/dist/* dist/$(PLUGINNAME)/webapp/
endif

ifneq ($(HAS_SERVER),)
	# Build files from server and copy server executables
	cd server && go get github.com/mitchellh/gox
	$(shell go env GOPATH)/bin/gox -osarch='darwin/amd64 linux/amd64 windows/amd64' -output 'dist/intermediate/plugin_{{.OS}}_{{.Arch}}' ./server
	mkdir -p dist/$(PLUGINNAME)/server

endif

	# Compress plugin
ifneq ($(HAS_SERVER),)
	mv dist/intermediate/plugin_darwin_amd64 dist/$(PLUGINNAME)/server/plugin.exe
	cd dist && tar -zcvf $(PACKAGENAME)-darwin-amd64.tar.gz $(PLUGINNAME)/*

	mv dist/intermediate/plugin_linux_amd64 dist/$(PLUGINNAME)/server/plugin.exe
	cd dist && tar -zcvf $(PACKAGENAME)-linux-amd64.tar.gz $(PLUGINNAME)/*

	mv dist/intermediate/plugin_windows_amd64.exe dist/$(PLUGINNAME)/server/plugin.exe
	cd dist && tar -zcvf $(PACKAGENAME)-windows-amd64.tar.gz $(PLUGINNAME)/*
else ifneq ($(HAS_WEBAPP),)
	cd dist && tar -zcvf $(PACKAGENAME).tar.gz $(PLUGINNAME)/*
endif

	# Clean up temp files
	rm -rf dist/$(PLUGINNAME)
	rm -rf dist/intermediate

ifneq ($(HAS_SERVER),)
	@echo Linux plugin built at: dist/$(PACKAGENAME)-linux-amd64.tar.gz
	@echo MacOS X plugin built at: dist/$(PACKAGENAME)-darwin-amd64.tar.gz
	@echo Windows plugin built at: dist/$(PACKAGENAME)-windows-amd64.tar.gz
else ifneq ($(HAS_WEBAPP),)
	@echo Cross-platform plugin built at:  dist/$(PACKAGENAME)-amd64.tar.gz
endif

.distclean:
	@echo ${BOLD}"Cleaning dist files\n"${RESET}
	rm -rf dist
	rm -rf webapp/dist
	rm -f server/plugin.exe
	@echo "\n"

clean: .distclean
	@echo ${BOLD}"Cleaning plugin\n"${RESET}
	rm -rf server/vendor
	rm -rf webapp/node_modules
	rm -rf webapp/.npminstall
	@echo "\n"
