#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
source ./i18n.sh
id=kwin_relative_pointer
effect_call() {
    gdbus call --session --dest org.kde.KWin --object-path /Effects \
        --method "org.kde.kwin.Effects.$1" "$id"
}

case "${1:-install}" in
    install)
        src=/usr/local/src/kwin-relative-pointer
        helper=/usr/local/bin/kwin-relative-pointer-rebuild
        unit=kwin-relative-pointer-rebuild.service
        sudo install -d "$src"
        sudo install -m 644 CMakeLists.txt plugin.cpp metadata.json "$src/"
        sudo install -D -m 755 systemd/rebuild.sh "$helper"
        sudo "$helper" --force
        sudo install -D -m 644 "systemd/$unit" "/etc/systemd/system/$unit"
        sudo install -D -m 644 systemd/kwin-relative-pointer-rebuild.actions \
            /etc/dnf/libdnf5-plugins/actions.d/kwin-relative-pointer-rebuild.actions
        sudo systemctl daemon-reload
        sudo systemctl enable "$unit"
        if [[ $(effect_call isEffectLoaded) == "(true,)" ]]; then
            effect_call unloadEffect >/dev/null
        fi
        enabled=true
        ;;
    --disable) enabled=false ;;
    --enable) enabled=true ;;
    *) message 'Використання: %s [--enable|--disable]' "$0" >&2; exit 2 ;;
esac
kwriteconfig6 --file kwinrc --group Plugins --key "${id}Enabled" --type bool "$enabled"
dbus-send --session --print-reply --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null

expected="($enabled,)"
if [[ $(effect_call isEffectLoaded) != "$expected" ]]; then
    if [[ $enabled == true ]]; then
        effect_call loadEffect >/dev/null
    else
        effect_call unloadEffect >/dev/null
    fi
fi
if [[ $(effect_call isEffectLoaded) != "$expected" ]]; then
    message 'KWin не застосував зміну стану ефекту %s.' "$id" >&2
    exit 1
fi
if [[ $enabled == true ]]; then
    message 'KWin завантажив ефект %s.' "$id"
else
    message 'Ефект %s вимкнено.' "$id"
fi
if [[ ${1:-install} == install ]]; then
    message 'Якщо після оновлення поведінка не змінилася, збережи роботу та ввійди в Plasma заново.'
fi
