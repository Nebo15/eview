#!/bin/bash

# This script simplifies releasing a new hex package.
# It will run following steps:
#   1. Run tests;
#   2. Create git tag with incremented version number (taken from mix.exs);
#   3. Start build for Hex.pm package.
#
# Usage:
# hrel [-v RELEASE_VERSION]

# Find mix.exs inside project tree.
# This allows to call bash scripts within any folder inside project.
PROJECT_DIR=$(git rev-parse --show-toplevel)
if [ ! -f "${PROJECT_DIR}/mix.exs" ]; then
    echo "[E] Can't find '${PROJECT_DIR}/mix.exs'."
    echo "    Check that you run this script inside git repo or init a new one in project root."
fi

# Extract project name and version from mix.exs
PROJECT_VERSION=$(sed -n 's/.*@version "\([^"]*\)".*/\1/pg' "${PROJECT_DIR}/mix.exs")

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

# Increment patch version
a=( ${PROJECT_VERSION//./ } )
((a[2]++))
INC_PROJECT_VERSION="${a[0]}.${a[1]}.${a[2]}"

# Parse ARGS
while getopts "v:" opt; do
  case "$opt" in
    v)  INC_PROJECT_VERSION=$OPTARG
        ;;
  esac
done

# Tag should be unique
if [ `git tag --list $INC_PROJECT_VERSION` ]; then
  echo "[W] Git tag '${INC_PROJECT_VERSION}' already exists!"
  echo "    Try to manually set version via -v flag."
  exit 1
fi

# Check working tree
if [ ! `git diff-index --quiet HEAD --;` ]; then
  echo "[E] Working tree contains uncommitted changes. This may cause wrong relation between hex release and git tag."
  exit 1
fi

# Get release notes
PREVIOUS_TAG=$(git describe HEAD^1 --abbrev=0 --tags)
GIT_HISTORY=$(git log --no-merges --format="- %s" $PREVIOUS_TAG..HEAD)

if [[ $PREVIOUS_TAG == "" ]]; then
  GIT_HISTORY=$(git log --no-merges --format="- %s")
fi;

echo "[I] Creating git tag '${INC_PROJECT_VERSION}'.."
echo "    Release Notes: "
echo $GIT_HISTORY

git tag -a $INC_PROJECT_VERSION -m "${GIT_HISTORY}"

# Persist new project version
echo "[I] Incrementing project version from '${PROJECT_VERSION}' to '${INC_PROJECT_VERSION}' in 'mix.exs'."
sed -i'' "s/@version \"${PROJECT_VERSION}\"/@version \"${INC_PROJECT_VERSION}\"/g" "${PROJECT_DIR}/mix.exs"
sed -i'' "s/\"~> ${PROJECT_VERSION}\"/\"~> ${INC_PROJECT_VERSION}\"/g" "${PROJECT_DIR}/README.md"
git add mix.exs README.md
git commit -m "Bump version to ${INC_PROJECT_VERSION}"

mix hex.publish
