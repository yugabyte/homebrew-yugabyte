#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Get the latest version from the GitHub API
latest=$(curl -s -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/yugabyte/ybm-cli/releases/latest)
version=$(echo $latest | jq -r '.tag_name')

echo "Latest version: $version"
# strip the leading 'v' from the version
version=${version:1}

# get the SHA256 checksum from the file that ends with _SHA256SUMS
shaFile=$(echo $latest | jq -r '.assets[] | select(.name | endswith("_SHA256SUMS")) | .name')
download_url=$(echo $latest | jq -r '.assets[] | select(.name | endswith("_SHA256SUMS")) | .browser_download_url')

echo "Downloading $shaFile from $download_url"
curl -s -L -fo $shaFile $download_url >/dev/null

# get the SHA256 checksum from the file that ends with _SHA256SUMS
sha_linux_amd64=$(grep _linux_amd64 $shaFile | awk '{print $1}')
sha_linux_arm64=$(grep _linux_arm64 $shaFile | awk '{print $1}')
sha_darwin_amd64=$(grep _darwin_amd64 $shaFile | awk '{print $1}')
sha_darwin_arm64=$(grep _darwin_arm64 $shaFile | awk '{print $1}')

destination_file=$SCRIPT_DIR/Formula/ybm.rb
echo "Writing to $destination_file"

cat >$destination_file <<EOF
class Ybm < Formula
  desc "YugabyteDB Managed CLI"
  homepage "https://github.com/yugabyte/ybm-cli"
  version "$version"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/yugabyte/ybm-cli/releases/download/v$version/ybm_${version}_darwin_amd64.zip"
      sha256 "$sha_darwin_amd64"

      def install
        bin.install "ybm"
        bash_completion.install "completions/ybm.bash" => "ybm"
        zsh_completion.install "completions/ybm.zsh" => "_ybm"
        fish_completion.install "completions/ybm.fish"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/yugabyte/ybm-cli/releases/download/v$version/ybm_${version}_darwin_arm64.zip"
      sha256 "$sha_darwin_arm64"

      def install
        bin.install "ybm"
        bash_completion.install "completions/ybm.bash" => "ybm"
        zsh_completion.install "completions/ybm.zsh" => "_ybm"
        fish_completion.install "completions/ybm.fish"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/yugabyte/ybm-cli/releases/download/v$version/ybm_${version}_linux_amd64.zip"
      sha256 "$sha_linux_amd64"

      def install
        bin.install "ybm"
        bash_completion.install "completions/ybm.bash" => "ybm"
        zsh_completion.install "completions/ybm.zsh" => "_ybm"
        fish_completion.install "completions/ybm.fish"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/yugabyte/ybm-cli/releases/download/v$version/ybm_${version}_linux_arm64.zip"
      sha256 "$sha_linux_arm64"

      def install
        bin.install "ybm"
        bash_completion.install "completions/ybm.bash" => "ybm"
        zsh_completion.install "completions/ybm.zsh" => "_ybm"
        fish_completion.install "completions/ybm.fish"
      end
    end
  end
end
EOF

ver_destination_file=$SCRIPT_DIR/Formula/ybm@${version}.rb
echo "Writing to $ver_destination_file"

cp $destination_file $ver_destination_file

# Remove the SHA256 file if it exists
if [ -f $shaFile ]; then
  echo "Removing existing $shaFile"
  rm $shaFile
fi
