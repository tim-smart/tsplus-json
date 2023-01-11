SHORT_SHA="$(git rev-parse --short HEAD)"

cwd="$(pwd)"
tsplus_gen="$cwd/node_modules/.bin/tsplus-gen"

package_json() {
  cat <<EOF
{
  "name": "$1",
  "description": "Generated tsplus annotations for $3",
  "version": "$2",
  "publishConfig": {
    "access": "public"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/tim-smart/tsplus-json.git"
  },
  "peerDependencies": {
    "$3": "$4"
  },
  "license": "MIT",
  "tsPlusTypes": [
    "./annotations.json"
  ]
}
EOF
}

for project in config/*; do
  project_name="$(basename $project)"
  project_path="$(readlink -f "$project")"
  git_repo="$(cat "$project_path/git")"
  tsplus_config="$project_path/tsplus-gen.config.json"
  annotations_dir="$project_path/annotations"

  rm -rf tmp
  mkdir tmp
  cd tmp

  mkdir dist
  git clone "$git_repo" repo
  cd repo

  package_name="$(npm pkg get name | sed 's/[",]//g')"
  latest_tag="$(git describe --tags --abbrev=0)"
  latest_version="${latest_tag#"v"}"
  dist_version="${latest_version}-${SHORT_SHA}"

  git checkout -f "$latest_tag"
  cp -r "$tsplus_config" .

  if [ -e "$annotations_dir" ]; then
    cp -r "$annotations_dir" .
  fi

  $tsplus_gen tsplus-gen.config.json > ../dist/annotations.json

  cd ../dist
  package_json "@tsplus-json/${project_name}" "$dist_version" "$package_name" "$latest_version" > package.json

  npm publish || true

  cd "$cwd"
  rm -rf tmp
done
