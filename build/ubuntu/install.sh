#!/bin/bash
#
# Copy/fork of https://github.com/google/timesketch/blob/master/contrib/deploy_timesketch.sh
set -e

# Exit early if docker is not installed.
if ! command -v docker; then
  echo "ERROR: Docker is not available."
  echo "See: https://docs.docker.com/engine/install/ubuntu/"
  exit 1
fi

# Exit early if there are Timesketch containers already running.
if [ ! -z "$(docker ps | grep timesketch)" ]; then
  echo "ERROR: Timesketch containers already running."
  exit 1
fi


echo -n "* Create necessary directories.."
# TODO: Switch to named volumes instead of host volumes.
mkdir -p jupyter/{notebooks,libs}
mkdir -p timesketch/{data/postgresql,data/opensearch,logs,etc,etc/timesketch,etc/timesketch/sigma/rules,upload}


echo -n "* Setting default config parameters.."
POSTGRES_USER="timesketch"
POSTGRES_PASSWORD="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 32 ; echo)"
POSTGRES_ADDRESS="postgres"
POSTGRES_PORT=5432
SECRET_KEY="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 32 ; echo)"
JUPYTER_TOKEN="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 32 ; echo)"
OPENSEARCH_ADDRESS="opensearch"
OPENSEARCH_PORT=9200
OPENSEARCH_MEM_USE_GB=$(cat /proc/meminfo | grep MemTotal | awk '{printf "%.0f", ($2 / (1024 * 1024) / 2)}')
REDIS_ADDRESS="redis"
REDIS_PORT=6379
echo "* Setting OpenSearch memory allocation to ${OPENSEARCH_MEM_USE_GB}GB"

curl -s $GITHUB_DINOC_BASE_URL/build/ubuntu/docker-compose.yml > ./docker-compose.yml
curl -s $GITHUB_DINOC_BASE_URL/build/ubuntu/.env > ./.env
curl -s $GITHUB_DINOC_BASE_URL/build/ubuntu/jupyter.Dockerfile > ./jupyter.Dockerfile

# Fetch last version of docker-compose, .env and jupyter.Dockerfile files
echo -n "* Fetching DINOC configuration files.."
GITHUB_DINOC_BASE_URL="https://github.com/nahotjan/dinoc/main"
GITHUB_DINOCLIB_CLONE="https://github.com/nahotjan/dinoclib.git"
GITHUB_TIMESKETCH_BASE_URL="https://raw.githubusercontent.com/google/timesketch/master"

echo -n "* Fetching DINOC LIB.."
git clone $GITHUB_DINOCLIB_CLONE jupyter/libs

# Fetch default Timesketch config files
echo -n "* Fetching Timesketch configuration files.."
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/timesketch.conf > timesketch/etc/timesketch/timesketch.conf
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/tags.yaml > timesketch/etc/timesketch/tags.yaml
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/plaso.mappings > timesketch/etc/timesketch/plaso.mappings
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/generic.mappings > timesketch/etc/timesketch/generic.mappings
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/features.yaml > timesketch/etc/timesketch/features.yaml
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/ontology.yaml > timesketch/etc/timesketch/ontology.yaml
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/sigma_rule_status.csv > timesketch/etc/timesketch/sigma_rule_status.csv
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/tags.yaml > timesketch/etc/timesketch/tags.yaml
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/intelligence_tag_metadata.yaml > timesketch/etc/timesketch/intelligence_tag_metadata.yaml
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/sigma_config.yaml > timesketch/etc/timesketch/sigma_config.yaml
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/sigma_blocklist.csv > timesketch/etc/timesketch/sigma_blocklist.csv
curl -s $GITHUB_TIMESKETCH_BASE_URL/data/sigma/rules/lnx_susp_zmap.yml > timesketch/etc/timesketch/sigma/rules/lnx_susp_zmap.yml
curl -s $GITHUB_TIMESKETCH_BASE_URL/contrib/nginx.conf > timesketch/etc/nginx.conf

# Create a minimal Timesketch config
echo -n "* Edit configuration files.."
sed -i 's#SECRET_KEY = \x27\x3CKEY_GOES_HERE\x3E\x27#SECRET_KEY = \x27'$SECRET_KEY'\x27#' timesketch/etc/timesketch/timesketch.conf

# Set up the Elastic connection
sed -i 's#^OPENSEARCH_HOST = \x27127.0.0.1\x27#OPENSEARCH_HOST = \x27'$OPENSEARCH_ADDRESS'\x27#' timesketch/etc/timesketch/timesketch.conf
sed -i 's#^OPENSEARCH_PORT = 9200#OPENSEARCH_PORT = '$OPENSEARCH_PORT'#' timesketch/etc/timesketch/timesketch.conf

# Set up the Redis connection
sed -i 's#^UPLOAD_ENABLED = False#UPLOAD_ENABLED = True#' timesketch/etc/timesketch/timesketch.conf
sed -i 's#^UPLOAD_FOLDER = \x27/tmp\x27#UPLOAD_FOLDER = \x27/usr/share/timesketch/upload\x27#' timesketch/etc/timesketch/timesketch.conf

sed -i 's#^CELERY_BROKER_URL =.*#CELERY_BROKER_URL = \x27redis://'$REDIS_ADDRESS':'$REDIS_PORT'\x27#' timesketch/etc/timesketch/timesketch.conf
sed -i 's#^CELERY_RESULT_BACKEND =.*#CELERY_RESULT_BACKEND = \x27redis://'$REDIS_ADDRESS':'$REDIS_PORT'\x27#' timesketch/etc/timesketch/timesketch.conf

# Set up the Postgres connection
sed -i 's#postgresql://<USERNAME>:<PASSWORD>@localhost#postgresql://'$POSTGRES_USER':'$POSTGRES_PASSWORD'@'$POSTGRES_ADDRESS':'$POSTGRES_PORT'#' timesketch/etc/timesketch/timesketch.conf

sed -i 's#^POSTGRES_PASSWORD=#POSTGRES_PASSWORD='$POSTGRES_PASSWORD'#' ./.env
sed -i 's#^OPENSEARCH_MEM_USE_GB=#OPENSEARCH_MEM_USE_GB='$OPENSEARCH_MEM_USE_GB'#' ./.env
sed -i 's#^JUPYTER_TOKEN=#JUPYTER_TOKEN='$JUPYTER_TOKEN'#' ./.env

# Download docker images
docker compose pull

# Start jupyter and install packages
docker compose up -d jupyter

# Set up timesketch
echo "OK"