#!/usr/bin/env bash

FLY_TARGET ?= concourse
FLY_USERNAME ?= test
FLY_PASSWORD ?= test

.PHONY: *

.envrc:
	[[ -f .envrc ]] || cp .envrc.example .envrc
	direnv allow

.params.yml:
	[[ -f .params.yml ]] || (echo '---' && cat params.yml | grep '.*: ((.*))' | sed -n 's/.*: ((\(.*\)))/\1: ((\1))/p' && cat ci/params.yml | grep '.*: ((.*))' | sed -n 's/.*: ((\(.*\)))/\1: ((\1))/p') | uniq | sort > .params.yml

login:
	fly -t $(FLY_TARGET) login -u $(FLY_USERNAME) -p $(FLY_PASSWORD)

ci-pipeline: login
	fly -t $(FLY_TARGET) sp -p cf-system-stats-ci -c ci/pipeline.yml -l ci/params.yml -l .params.yml

pipeline: login
	fly -t $(FLY_TARGET) sp -p cf-system-stats -c pipeline.yml -l params.yml -l .params.yml
