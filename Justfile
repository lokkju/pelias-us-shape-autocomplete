set dotenv-load := true

export REPOS := "pelias-schema pelias-api pelias-whosonfirst"
export BRANCH := "shape_support"
export ORG := "lokkju"

data_dir := env_var('DATA_DIR')
s3_data_dir := env_var('S3_DATA_DIR')
aws_profile := env_var('AWS_PROFILE')

# default recipe to display help information
default:
  @just --list

@_clone repo:
	if ! {{path_exists("_repos/" + repo)}}; then \
		@echo "Cloning {{repo}}" ;\
		git clone "https://github.com/lokkju/{{repo}}.git" _repos/{{repo}} ; \
		git checkout BRANCH ; \
	fi

_build $REPO : (_clone REPO)
	#!/usr/bin/env bash
	# based on https://raw.githubusercontent.com/pelias/ci-tools/master/build-docker-images.sh
	set -ux
	cd "./_repos/{{REPO}}"
	set -ux

	if [[ ! -f Dockerfile ]]; then
		echo "No Dockerfile found, not building"
		exit 0
	fi

	# fetch git tags
	git fetch --depth=1 origin +refs/tags/*:refs/tags/*

	# calculate basic values
	DATE=`date +%Y-%m-%d`
	REVISION="$(git rev-parse --short HEAD)"

		
	# list of tags to build and push
	tags=(
		"$ORG/$REPO:$BRANCH"
		"$ORG/$REPO:$BRANCH-$DATE-$REVISION"
	)

	# default build targets can be configured with the DOCKER_BUILD_PLATFORMS env var
	DOCKER_BUILD_DEFAULT_PLATFORMS='linux/amd64'
	DOCKER_BUILD_PLATFORMS=${DOCKER_BUILD_PLATFORMS:-$DOCKER_BUILD_DEFAULT_PLATFORMS}

	# log in to Docker Hub _before_ building to avoid rate limits
	#docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

	# Build and push each tag (the built image will be reused after the first build)
	for tag in ${tags[@]}; do
	  if [ "$DOCKER_BUILD_PLATFORMS" == "classic" ]; then
	    docker build -t $tag .
	    docker push $tag
	  else
	    docker buildx create --use --platform="$DOCKER_BUILD_PLATFORMS" --name 'multi-platform-builder'
	    docker buildx inspect --bootstrap
	    docker buildx build --push --platform="$DOCKER_BUILD_PLATFORMS" -t $tag .
	  fi
	done

# Build and push docker images
build:
	#!/usr/bin/env bash
	for repo in $REPOS; do
		just _build $repo
	done

# Backup pelias data to S3
data-backup:
	[ -d $DATA_DIR ] && s5cmd --profile=$AWS_PROFILE sync --size-only $DATA_DIR $S3_DATA_DIR

# Restore pelias data from S3
data-restore:
	s5cmd --profile=$AWS_PROFILE sync --size-only $S3_DATA_DIR* $DATA_DIR

docker-up:
	docker compose up -d
