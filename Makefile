SHELL := /bin/bash

# Keep FILTER literal, including Make expressions, shell syntax, and apostrophes.
unexport FILTER
test_filter_arg = $(if $(value FILTER),--filter '$(subst ','"'"',$(value FILTER))')

.PHONY: build check docs-list format lint release restart start start-debug start-release stop test test-fast test-skip-build test-live test-tty uninstall uninstall-cli

start:
	./Scripts/compile_and_run.sh

start-debug:
	./Scripts/compile_and_run.sh

start-release:
	./Scripts/package_app.sh release
	pkill -x LimitBar || pkill -f LimitBar.app || true
	cd "$(CURDIR)" && open -n "$(CURDIR)/LimitBar.app"

restart: start

stop:
	pkill -x LimitBar || pkill -f LimitBar.app || true

check lint:
	./Scripts/lint.sh lint

format:
	./Scripts/lint.sh format

docs-list:
	node Scripts/docs-list.mjs

build:
	swift build

test:
	./Scripts/test.sh

test-fast:
	./Scripts/test_fast.sh $(test_filter_arg)

test-skip-build:
	./Scripts/test_fast.sh --skip-build $(test_filter_arg)

test-tty:
	LIMITBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter TTYIntegrationTests

test-live:
	LIVE_TEST=1 LIMITBAR_ALLOW_TEST_KEYCHAIN_ACCESS=1 swift test --filter LiveAccountTests

release:
	./Scripts/package_app.sh release

uninstall-cli:
	rm -f /usr/local/bin/limitbar /opt/homebrew/bin/limitbar
	@echo "LimitBar CLI uninstalled successfully."

uninstall: stop uninstall-cli
	rm -rf "/Applications/LimitBar.app" "$(CURDIR)/LimitBar.app"
	rm -rf ~/Library/Application\ Support/LimitBar
	rm -rf ~/.config/limitbar
	@echo "LimitBar app and configuration uninstalled successfully."
