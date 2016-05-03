#!/bin/sh

/bin/bash -c '

SELECTION_LINE="0"

arrowup="\[A"
arrowdown="\[B"
arrowright="\[C"

SUCCESS=0

MENU_STRING=$(qdbus org.mpris.MediaPlayer2.* | grep "org.mpris.MediaPlayer2." | sed 's/org.mpris.MediaPlayer2.//')

ENUM_TIC=1
ENUM_MAX=$(printf "$MENU_STRING" | wc -w)

MENU_PROPER_NAME=$(

while [ "$ENUM_TIC" < "$ENUM_MAX" ]; do

printf "$(qdbus org.mpris.MediaPlayer2.$(printf "$MENU_STRING" | sed -n "$ENUM_TIC{p;q}")  /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Identity | sed -e "s#^#$(if [ "$SELECTION_LINE" = "0" ]; then tput rev; else tput sgr0; fi)#")\n"
((ENUM_TIC++))

done

)

while true; do

printf "$(tput cup 0 0)$(tput ed)$MENU_PROPER_NAME"
    
read -rsn3 input

printf "$input" | grep "$arrowup"
if [ "$?" -eq $SUCCESS ]; then
    ((SELECTION_LINE--))
fi

printf "$input" | grep "$arrowdown"
if [ "$?" -eq $SUCCESS ]; then
    ((SELECTION_LINE++))
fi

printf "$input" | grep "$arrowright"
if [ "$?" -eq $SUCCESS ]; then
    break
fi

done

tput cup 0 0
tput ed

printf "$(printf "$MENU_STRING" | sed -n "$(($SELECTION_LINE+1)){p;q}")\n"

'
