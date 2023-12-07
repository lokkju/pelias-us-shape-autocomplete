# North America Project

__based on https://github.com/pelias/docker/tree/master/projects/north-america__

This project is configured to download/prepare/build a complete Pelias installation for North America.

As a fairly large build, this will require significant resources to complete quickly. It can still run on a personal computer with 8GB+ RAM, but will take a while. It will require 300GB or so of disk space.

Running an interpolation build of this side would also take many days

Additionally, it requires a polylines file generated with [Valhalla](https://github.com/valhalla).

## Tools
You must have docker and just installed prior to running this project

# Deploy
ensure you have a local `.env` file as below. It is important that paths end in a slash
```
COMPOSE_PROJECT_NAME=pelias
DATA_DIR=/data/pelias/united-states/
S3_DATA_DIR=s3://your-bucket/pelias-data/2023-12-07/
```

Then

```bash
# sync the pre-built pelias data archive
just data-restore
# bring up the required images
just docker-up
```
# Development and data building

The minimum configuration required in order to run this project are [installing prerequisites](https://github.com/pelias/docker#prerequisites), [install the pelias command](https://github.com/pelias/docker#installing-the-pelias-command) and [configure the environment](https://github.com/pelias/docker#configure-environment).

This build also requires [obtaining or generating a polylines file from Valhalla](https://github.com/pelias/polylines/wiki/Generating-polylines-from-Valhalla). Once you have the polylines file, you must move it to `polylines/extract.0sv`. You can also download the latest `north-america-valhalla.polylines.0sv.gz`, move and rename from: https://geocode.earth/data/

Please ensure that's all working fine before continuing.

## Run a Build

To run a complete build, execute the following commands:

```bash
docker compose build
pelias compose pull
pelias elastic start
pelias elastic wait
pelias elastic create
pelias download all
pelias prepare placeholder
pelias import all
pelias compose up
pelias test run
```

## Push custom place support docker images to hub
```bash
just build
```

# Make an Example Query

You can now make queries against your new Pelias build:

[http://localhost:4000/v1/search?text=empire state building](http://localhost:4000/v1/search?text=empire%20state%20building)
