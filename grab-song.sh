#!/bin/bash

tput civis
stty -echo

cd "${0%/*}"

VERBOSE=${VERBOSE-false}

CONFIG_DIR=${CONFIG_DIR-Config}

PLAYER_SELECTION=${1-$(cat $CONFIG_DIR/settings.conf | grep "last-used-player=" | sed 's/last-used-player=//')} 

OUTPUT_DIR=${OUTPUT_DIR-$(cat $CONFIG_DIR/settings.conf | grep "output-directory=" | sed 's/output-directory=//')}

ONELINE=${ONELINE-$(cat $CONFIG_DIR/settings.conf | grep "oneline=" | sed 's/oneline=//')}
ONELINER_FORMAT=${ONELINER_FORMAT-$(cat $CONFIG_DIR/settings.conf | grep "oneliner-format=" | sed 's/oneliner-format=//')}

SONG_METADATA="Temp/SongMetaData.txt"
SONG_TITLE="$OUTPUT_DIR/SongTitle.txt"
SONG_ARTIST="$OUTPUT_DIR/SongArtist.txt"
SONG_ALBUM="$OUTPUT_DIR/SongAlbum.txt"
SONG_ONELINER="$OUTPUT_DIR/SongInfo.txt"

mkdir -p Temp
mkdir -p $OUTPUT_DIR
mkdir -p $CONFIG_DIR
touch $SONG_METADATA
touch $SONG_TITLE
touch $SONG_ARTIST
touch $SONG_ALBUM
# Need to implement a oneliner output, similar to Snip.
touch $SONG_ONELINER

if [ ! -f $CONFIG_DIR/settings.conf ]; then
    echo "last-used-player=" >> $CONFIG_DIR/settings.conf
    echo "output-directory=$OUTPUT_DIR" >> $CONFIG_DIR/settings.conf
    echo "oneline=false" >> $CONFIG_DIR/settings.conf
    echo "oneliner-format= $a: $t - $i " >> $CONFIG_DIR/settings.conf
fi

# Define a function for saving the configuration and cleaning up temporary files.
save_and_clean()
{
sed -i "/last-used-player=/ c\last-used-player=$PLAYER_SELECTION" $CONFIG_DIR/settings.conf
sed -i "/output-directory=/ c\output-directory=$OUTPUT_DIR" $CONFIG_DIR/settings.conf
sed -i "/oneline=/ c\oneline=$ONELINE" $CONFIG_DIR/settings.conf
sed -i "/oneliner-format=/ c\oneliner-format=$ONELINER_FORMAT" $CONFIG_DIR/settings.conf
rm -rf Temp/*
kill $(jobs -p)
stty echo
tput cnorm
reset
exit 
}

# BEGIN MAIN LOOP
while true; do
(

# Check for MPRIS data update.
if [ "$(qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)" != "$(cat $SONG_METADATA)" ]; then
(

qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata > $SONG_METADATA

# If no album art is found, use generic image instead.
if grep -q "mpris:artUrl:" $SONG_METADATA; then

SONG_ART=$(cat $SONG_METADATA | grep "mpris:artUrl:" | sed 's/mpris:artUrl: //')
convert $SONG_ART -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

else

convert Images/NoArt.* -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

fi

if [ "$ONELINE" = "false" ]; then
# Edit the junk out of the MPRIS data and save the title, artist, and album data as individual text files.
cat $SONG_METADATA | grep "xesam:title:" | sed 's/xesam:title: //' > $SONG_TITLE
cat $SONG_METADATA | grep "xesam:artist:" | sed 's/xesam:artist: //' > $SONG_ARTIST
cat $SONG_METADATA | grep "xesam:album:" | sed 's/xesam:album: //' > $SONG_ALBUM
else
# Same as above, except for oneline mode.
t=$(cat $SONG_METADATA | grep "xesam:title:" | sed 's/xesam:title: //')
a=$(cat $SONG_METADATA | grep "xesam:artist:" | sed 's/xesam:artist: //')
i=$(cat $SONG_METADATA | grep "xesam:album:" | sed 's/xesam:album: //')
printf "$(eval "printf \"$ONELINER_FORMAT\"")" > $SONG_ONELINER
fi
)
fi

# Verbosity.
if [ "$VERBOSE" = "true" ]; then

tput cup 0 0
tput ed
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =

if [ "$ONELINE" = "false" ]; then

printf "$(tput cup 1 0)Title: $(cat $SONG_METADATA | grep "xesam:title:" | sed 's/xesam:title: //')\n\nArtist: $(cat $SONG_METADATA | grep "xesam:artist:" | sed 's/xesam:artist: //')\n\nAlbum: $(cat $SONG_METADATA | grep "xesam:album:" | sed 's/xesam:album: //')\n"

else

printf "$(tput cup 1 0)$(cat $SONG_ONELINER)\n"

fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =

fi

sleep 1

)

# END MAIN LOOP

trap save_and_clean EXIT INT TERM

done
