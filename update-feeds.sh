#!/usr/bin/env bash
# Pin every feed in feeds.conf to the feed's master as of this tree's
# upstream base.
#
# Feed master tracks OpenWrt main's newest APIs and this fork is rebased by
# hand, so a feed is pinned to its last first-parent commit at or before the
# committer date of the fork's merge-base with upstream main. First-parent
# matters: a PR commit can carry a date before the cut-off yet be merged
# after it.
#
# To add a feed, add its `src-git <name> <url>` line to feeds.conf and run
# this. Only src-git feeds on their default branch are handled.
#
# Bumping the feeds:
#   1. Rebase the fork onto upstream main.
#   2. ./update-feeds.sh
#   3. ./scripts/feeds update -a && ./scripts/feeds install -a
#   4. Per config-<ap>, check that `make defconfig` drops no selection:
#        cp config-<ap> .config && make defconfig
#        comm -23 <(grep '=y$' config-<ap> | sort) <(grep '=y$' .config | sort)
#      Any output is a package a feed renamed or removed. Fix the config
#      before going on; never re-save over a loss.
#   5. cp .config config-<ap>, and commit feeds.conf with the configs.
set -euo pipefail

cd "$(dirname "$0")"
upstream=https://git.openwrt.org/openwrt/openwrt.git

[ -f feeds.conf ] || { echo "feeds.conf missing" >&2; exit 1; }

git fetch --quiet --no-tags "$upstream" main
base=$(git merge-base HEAD FETCH_HEAD)
date=$(git log -1 --format=%cI "$base")
echo "upstream base $base, committed $date" >&2

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

{
	echo "# Written by update-feeds.sh: feed master as of upstream $base ($date)"
	grep -v '^[[:space:]]*\(#\|$\)' feeds.conf | while read -r type name src; do
		[ "$type" = src-git ] || { echo "$name: unsupported feed type $type" >&2; exit 1; }
		url=${src%%^*}
		git clone --quiet --bare --single-branch --no-tags "$url" "$tmp/$name"
		rev=$(git -C "$tmp/$name" log -1 --first-parent --until="$date" --format=%H HEAD)
		[ -n "$rev" ] || { echo "$name: no commit at or before $date" >&2; exit 1; }
		git -C "$tmp/$name" log -1 --format="$name: %h %cI %s" "$rev" >&2
		echo "src-git $name $url^$rev"
	done
} > "$tmp/feeds.conf"

mv "$tmp/feeds.conf" feeds.conf
