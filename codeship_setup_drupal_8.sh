#!/bin/bash
# Set php version through phpenv. 5.3, 5.4, 5.5 & 5.6 available
phpenv local 5.5

# Remove xdebug
rm -f /home/rof/.phpenv/versions/$(phpenv version-name)/etc/conf.d/xdebug.ini

# Composer config
mv ~/clone/tests/composer.codeship.json ~/.composer/composer.json
composer config -g github-oauth.github.com $GITHUB_ACCESS_TOKEN
composer global update --prefer-dist --no-interaction
export PATH=~/.composer/vendor/bin:$PATH

# Pantheon Authentication
terminus auth login $PANTHEON_ROBOT --password=$ROBOT_PASSWORD
# Get Pantheon DB
terminus site backups get --site=$1 --env=$2 --element=database --to=panthbackup.sql.gz --latest
# Decompress DB
gunzip panthbackup.sql.gz
# Move to site
cd ~/clone
# Upload DB
drush sqlc < ~/codeship/panthbackup.sql
# Sanitize database
drush sqlsan --sanitize-email="build+%uid@webscope.co.nz" -y
# Update database
drush updb
# Inport config
drush config-import -y

# Start PHP server
nohup bash -c "php -S 127.0.0.1:8000 2>&1 &" && sleep 1;

# Install and run selenium
#\curl -sSL https://raw.githubusercontent.com/codeship/scripts/master/packages/selenium_server.sh | bash -s
SELENIUM_VERSION=${SELENIUM_VERSION:="2.46.0"}
SELENIUM_PORT=${SELENIUM_PORT:="4444"}
SELENIUM_OPTIONS=${SELENIUM_OPTIONS:=""}
SELENIUM_WAIT_TIME=${SELENIUM_WAIT_TIME:="10"}
set -e
MINOR_VERSION=${SELENIUM_VERSION%.*}
CACHED_DOWNLOAD="${HOME}/cache/selenium-server-standalone-${SELENIUM_VERSION}.jar"
wget --continue --output-document "${CACHED_DOWNLOAD}" "http://selenium-release.storage.googleapis.com/${MINOR_VERSION}/selenium-server-standalone-${SELENIUM_VERSION}.jar"
nohup bash -c "java -jar ${CACHED_DOWNLOAD} -port ${SELENIUM_PORT} ${SELENIUM_OPTIONS} 2>&1 &" && sleep ${SELENIUM_WAIT_TIME};
