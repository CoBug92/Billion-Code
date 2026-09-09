.PHONY: bootstrap generate lint test build deploy signing-sync-development signing-sync-appstore signing-create-development signing-create-appstore

bootstrap:
	./scripts/bootstrap.sh

generate:
	./scripts/generate

lint:
	./scripts/lint

test:
	./scripts/test

build:
	./scripts/build

deploy:
	./scripts/fastlane/run ios deploy_to_tf

signing-sync-development:
	./scripts/fastlane/run ios signing_sync type:development

signing-sync-appstore:
	./scripts/fastlane/run ios signing_sync type:appstore

signing-create-development:
	./scripts/fastlane/run ios signing_create type:development

signing-create-appstore:
	./scripts/fastlane/run ios signing_create type:appstore
