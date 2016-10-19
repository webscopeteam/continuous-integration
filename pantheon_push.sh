#!/bin/bash
# Identify the automation user
_CI_BOT_EMAIL="user@codeship.io"
_CI_BOT_NAME="codeship ci"
_CI_COMMIT_MSG=$CI_MESSAGE
# Use the 'master' branch for the dev environment; for multidev,
# use the branch with the same name as the multidev environment name.

# Set PANTHEON_SITE from environment variable or argument
if [ -z "$PANTHEON_SITE" ]
then
  PANTHEON_SITE=$1
fi

# Set PENV from argument , develop otherwise
if [ -z "$2" ]
then
  PENV="develop"
else
  PENV=$2
fi

if [ -z "$3" ]
then
  BRANCH="$PENV"
else
  BRANCH="$3"
fi



echo "Check to see if Pantheon site $PANTHEON_SITE exists"
which terminus
terminus auth login $PANTHEON_ROBOT --password=$ROBOT_PASSWORD
PUUID=$(terminus site info --site="$PANTHEON_SITE" --field=id 2>/dev/null)
if [ -z "$PUUID" ]
then
  echo "Could not get UUID for $PANTHEON_SITE"
  exit 1
fi
PUUID=$(echo $PUUID | sed -e 's/^[^:]*: *//')
echo "UUID for $PANTHEON_SITE is $PUUID"
echo "Wake up the site $PANTHEON_SITE"
terminus site wake --site="$PANTHEON_SITE" --env="$PENV"
git config --global user.email "$CI_COMMITTER_EMAIL"
git config --global user.name "$CI_COMMITTER_USERNAME"

# Clone pantheon repo
REPO="ssh://codeserver.dev.$PUUID@codeserver.dev.$PUUID.drush.in:2222/~/repository.git"
sshpass -p $ROBOT_PASSWORD git clone --depth 1 --branch "$BRANCH" "$REPO" pantheon_repo
# Copy files onto repo
cp -r ~/clone/* pantheon_repo/.
cd pantheon_repo
# Remove nohup.out file
rm nohup.out
# Output status
git status
# Add any new files
git add --all .

# Push our built files up to Pantheon
sshpass -p $ROBOT_PASSWORD git add --all
sshpass -p $ROBOT_PASSWORD git commit -a -m "Built by CI: '$_CI_COMMIT_MSG'"
sshpass -p $ROBOT_PASSWORD git push origin "$BRANCH"
