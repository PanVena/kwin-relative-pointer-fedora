# shellcheck shell=bash
message_locale=${LC_ALL:-${LC_MESSAGES:-${LANG:-C}}}
declare -A pointer_en=(
    ['Використання: %s [--enable|--disable]']='Usage: %s [--enable|--disable]'
    ['KWin не застосував зміну стану ефекту %s.']='KWin could not change the state of the %s effect.'
    ['KWin завантажив ефект %s.']='KWin loaded the %s effect.'
    ['Ефект %s вимкнено.']='The %s effect is disabled.'
    ['Якщо після оновлення поведінка не змінилася, збережи роботу та ввійди в Plasma заново.']='If the behavior is unchanged after an update, save your work and log back in to Plasma.'
)

message() {
    local format=$1
    shift
    if [[ ${message_locale,,} != uk* ]]; then
        format=${pointer_en[$format]}
    fi
    printf "$format\n" "$@"
}
