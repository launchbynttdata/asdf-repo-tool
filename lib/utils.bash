#!/usr/bin/env bash

set -euox pipefail

GH_REPO="https://github.com/launchbynttdata/git-repo"
TOOL_NAME="repo"
TOOL_TEST="repo --help"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if repo is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  list_github_tags
}

cleanup() {
  local path="$1"
  chmod -R u+w "$path" || true
  rm -rf "$path" || true
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    git clone "$GH_REPO" "$ASDF_DOWNLOAD_PATH"
    cd "$ASDF_DOWNLOAD_PATH"
    git checkout "$version"
    chmod +x repo
    rsync -av "$ASDF_DOWNLOAD_PATH/" "$install_path/"

    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || {
    cleanup "$ASDF_DOWNLOAD_PATH"
    cleanup "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  }

  cleanup "$ASDF_DOWNLOAD_PATH"
}
