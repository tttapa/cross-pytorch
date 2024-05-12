#!/usr/bin/env bash
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

set -ex

# Select architecture
triple="x86_64-bionic-linux-gnu"

# Download compiler
download_url="https://github.com/tttapa/toolchains/releases/download/0.0.8"
tools_dir="$PWD/toolchains"
pfx="$tools_dir/$triple"
mkdir -p "$tools_dir"
if [ ! -d "$pfx" ]; then
    wget "$download_url/x-tools-$triple-gcc12.tar.xz" -O- | \
        tar xJ -C "$tools_dir"
fi
