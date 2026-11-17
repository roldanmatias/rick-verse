# One set of commands: CI runs exactly these targets, so any CI failure reproduces with `make <target>`.
CORE := Packages/Core
CLI  := $(CORE)/apollo-ios-cli

.PHONY: test coverage lint format arch docs graphql graphql-generate apollo-cli

## Run the package tests (~210, about 1 s, no simulator).
test:
	cd $(CORE) && swift test

## Package tests with coverage, gated at 80% of Sources/ lines (generated code excluded).
coverage:
	cd $(CORE) && swift test --enable-code-coverage && ../../scripts/coverage.sh 80

## SwiftLint (strict) + swift-format (strict).
lint:
	swiftlint lint --strict
	scripts/swift-format-lint.sh

## Reformat every hand-written Swift file in place.
format:
	find $(CORE)/Sources $(CORE)/Tests RickVerse -name '*.swift' -not -path '*/Generated/*' -print0 \
	  | xargs -0 swift format format --in-place

## The architecture fitness function (layer import rules).
arch:
	scripts/check-architecture.sh

## DocC for every Core module → Packages/Core/_site.
docs:
	scripts/build-docs.sh

## Download the latest schema from the live API, then regenerate the Swift code.
graphql: apollo-cli
	cd $(CORE) && ./apollo-ios-cli fetch-schema
	cd $(CORE) && ./apollo-ios-cli generate

## Regenerate from the committed schema and operations (no network).
graphql-generate: apollo-cli
	cd $(CORE) && ./apollo-ios-cli generate

## Install the codegen CLI that matches the resolved Apollo version (it's gitignored).
## The plugin downloads a release binary, so SwiftPM needs network permission.
apollo-cli:
	@test -x $(CLI) || (cd $(CORE) && swift package --allow-writing-to-package-directory --allow-network-connections all apollo-cli-install)
