#!/bin/bash

set -e

cwd="$(pwd)"
tsplus_gen="$cwd/node_modules/.bin/tsplus-gen"
tarballjs="$cwd/tarball.js"

SHORT_SHA=`git rev-parse --short HEAD`

latest_tarball() {
  opts=(-s)

  if [ -n "$GITHUB_TOKEN" ]; then
    opts+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  url=`curl "${opts[@]}" "https://api.github.com/repos/$1/releases/latest" | node $tarballjs`
  mkdir source
  curl -L "$url" | tar -zx -C source --strip-components 1
}

package_json() {
  cat <<EOF
{
  "name": "@tsplus-types/$1",
  "version": "$2",
  "description": "Generated tsplus annotations for $3",
  "publishConfig": {
    "access": "public"
  },
  "main": "./annotations.json",
  "repository": {
    "type": "git",
    "url": "https://github.com/tim-smart/tsplus-json.git"
  },
  "peerDependencies": {
    "$3": "$4"
  },
  "license": "MIT"
}
EOF
}

for project in config/*; do
  project_name="$(basename $project)"
  if [ "$1" != "" ] && [ "$1" != "$project_name" ]; then
    continue
  fi
  project_path="$(readlink -f "$project")"
  github="$(cat "$project_path/github")"
  tsplus_config="$project_path/tsplus-gen.config.json"
  annotations_dir="$project_path/annotations"
  src_dir="$project_path/src"

  echo "Generation annotations for $project_name"

  cd "$project"

  rm -rf dist source

  latest_tarball "$github"
  mkdir dist
  cd source

  pnpm i -P

  package_name="$(npm pkg get name | sed 's/[",]//g')"
  latest_version="$(npm pkg get version | sed 's/[",]//g')"
  dist_version="${latest_version}-${SHORT_SHA}"

  if [ -e "$annotations_dir" ]; then
    cp -r "$annotations_dir" .
  fi

  $tsplus_gen "$tsplus_config" > ../dist/annotations.json

  cd ../dist
  package_json "${project_name}" "$dist_version" "$package_name" "$latest_version" > package.json
  cp "$cwd/README.md" .

  if [ -e "$src_dir" ]; then
    cp -r "$src_dir"/* .
  fi

  if [ "$NPM_PUBLISH" == "true" ]; then
    npm publish || true
  fi

  cd "$cwd"
done
