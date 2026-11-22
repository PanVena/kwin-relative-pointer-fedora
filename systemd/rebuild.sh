#!/usr/bin/env bash
set -euo pipefail
src=/usr/local/src/kwin-relative-pointer
state=/var/lib/kwin-relative-pointer
plugin_root=$(qtpaths6 --plugin-dir)
dest="$plugin_root/kwin/effects/plugins/kwin_relative_pointer.so"

install -d "$state"
exec 9>"$state/build.lock"
flock 9
current=$(rpm -q kwin)
if [[ ${1:-} != --force && -f $dest && -f $state/built-for && $(cat "$state/built-for") == "$current" ]]; then
    exit 0
fi

build=$(mktemp -d /var/tmp/kwin-relative-pointer.XXXXXXXX)
tmp=
trap 'rm -rf -- "$build"; if [[ -n $tmp ]]; then rm -f -- "$tmp"; fi' EXIT
cmake -S "$src" -B "$build" -DCMAKE_INSTALL_PREFIX=/usr -DKDE_INSTALL_PLUGINDIR="$plugin_root"
cmake --build "$build" --parallel
install -d "$(dirname "$dest")"
# Replace the file atomically while an existing session may have it mapped.
tmp=$(mktemp "$dest.XXXXXXXX")
install -m 755 "$build/lib/kwin/effects/plugins/kwin_relative_pointer.so" "$tmp"
mv -fT "$tmp" "$dest"
printf '%s\n' "$current" > "$state/built-for"
