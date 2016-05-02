#!/bin/sh

/bin/bash -c '

SELECTION_LINE="0"

arrowup="\[A"
arrowdown="\[B"
arrowright="\[C"

SUCCESS=0

MENU_STRING=$(printf "Item1.\nItem2.\nItem3.\nItem4.\nItem5.\n")

while true; do

printf "$(tput cup 0 0)$(tput ed)$(if [ "$SELECTION_LINE" = "0" ]; then tput rev; else tput sgr0; fi)Item1.\n$(if [ "$SELECTION_LINE" = "1" ]; then tput rev; else tput sgr0; fi)Item2.\n$(if [ "$SELECTION_LINE" = "2" ]; then tput rev; else tput sgr0; fi)Item3.\n$(if [ "$SELECTION_LINE" = "3" ]; then tput rev; else tput sgr0; fi)Item4.\n$(if [ "$SELECTION_LINE" = "4" ]; then tput rev; else tput sgr0; fi)Item5.\n\n$(tput sgr0)"
    
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

printf "You have selected $(printf "$MENU_STRING" | sed -n "$(($SELECTION_LINE+1)){p;q}")"

'
