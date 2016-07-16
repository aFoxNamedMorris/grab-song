#!/bin/sh

tput civis
stty -echo

# Define some defaults.
if [ -z "$TMP_DIR" ]; then TMP_DIR=`mktemp -d /tmp/$0.XXXXXXXXXXX`; fi
if [ -z "$CONFIG_DIR" ]; then CONFIG_DIR=${CONFIG_DIR-Config}; fi
if [ -z "$SETTINGS_FILE" ]; then SETTINGS_FILE="$CONFIG_DIR/settings.conf"; fi
if [ -z "$VERBOSE" ]; then VERBOSE='true'; fi
if [ -z "$ONELINE" ]; then ONELINE='false'; fi
if [ -z "$ONELINER_FORMAT" ]; then ONELINER_FORMAT=' $a: $t - $i '; fi
if [ -z "$OUTPUT_DIR" ]; then OUTPUT_DIR='Output'; fi

mkdir -p $CONFIG_DIR
if [ ! -f $SETTINGS_FILE ]; then
    printf "verbose=$VERBOSE\n" >> $SETTINGS_FILE
    if [ -z "$PLAYER_SELECTION\n" ]; then break; else printf "last-used-player=$PLAYER_SELECTION" >> $SETTINGS_FILE; fi
    printf "output-directory=$OUTPUT_DIR\n" >> $SETTINGS_FILE
    printf "oneline=$ONELINE\n" >> $SETTINGS_FILE
    printf 'oneliner-format= $a: $t - $i \n' >> $SETTINGS_FILE
    printf "rm-output=$RM_OUTPUT\n" >> $SETTINGS_FILE
fi

# Define a function for cleaning up temporary files.
save_and_clean()
{

sed -i "/verbose=/ c\verbose=$VERBOSE" $SETTINGS_FILE
sed -i "/last-used-player=/ c\last-used-player=$PLAYER_SELECTION" $SETTINGS_FILE
sed -i "/output-directory=/ c\output-directory=$OUTPUT_DIR" $SETTINGS_FILE
sed -i "/oneline=/ c\oneline=$ONELINE" $SETTINGS_FILE
sed -i "/oneliner-format=/ c\oneliner-format=$ONELINER_FORMAT" $SETTINGS_FILE
sed -i "/rm-output=/ c\rm-output=$RM_OUTPUT" $SETTINGS_FILE

rm -r $TMP_DIR

if $RM_OUTPUT; then
rm -r $OUTPUT_DIR
fi
kill $(jobs -p)
stty echo
tput cnorm
reset
exit
}

# Load stored settings.
VERBOSE=${VERBOSE-$(cat $SETTINGS_FILE | grep "verbose=" | sed 's/verbose=//')}

PLAYER_SELECTION=${1-$(cat $SETTINGS_FILE | grep "last-used-player=" | sed 's/last-used-player=//')}

# Player argument sanity check.
if [ -z "$PLAYER_SELECTION" ]; then save_and_clean; exit; else break; fi

OUTPUT_DIR=${OUTPUT_DIR-$(cat $SETTINGS_FILE | grep "output-directory=" | sed 's/output-directory=//')}

ONELINE=${ONELINE-$(cat $SETTINGS_FILE | grep "oneline=" | sed 's/oneline=//')}
ONELINER_FORMAT=${ONELINER_FORMAT-$(cat $SETTINGS_FILE | grep "oneliner-format=" | sed 's/oneliner-format=//')}

RM_OUTPUT=${RM_OUTPUT-$(cat $SETTINGS_FILE | grep "rm-output=" | sed 's/rm-output=//')}

printf "$RM_OUTPUT"

SONG_METADATA="$TMP_DIR/SongMetaData.txt"
SONG_TITLE="$OUTPUT_DIR/SongTitle.txt"
SONG_ARTIST="$OUTPUT_DIR/SongArtist.txt"
SONG_ALBUM="$OUTPUT_DIR/SongAlbum.txt"
SONG_ONELINER="$OUTPUT_DIR/SongInfo.txt"

# Set up the locations of the output files.
mkdir -p $OUTPUT_DIR
touch $SONG_METADATA
touch $SONG_TITLE
touch $SONG_ARTIST
touch $SONG_ALBUM
touch $SONG_ONELINER

# Test to make sure everything is present in the settings file.
TEST_VERBOSE=$(cat $SETTINGS_FILE | grep "verbose=")
TEST_PLAYER_SELECTION=$(cat $SETTINGS_FILE | grep "last-used-player=")
TEST_OUTPUT_DIR=$(cat $SETTINGS_FILE | grep "output-directory=")
TEST_ONELINE=$(cat $SETTINGS_FILE | grep "oneline=")
TEST_ONELINER_FORMAT=$(cat $SETTINGS_FILE | grep "oneliner-format=")
TEST_RM_OUTPUT=$(cat $SETTINGS_FILE | grep "rm-output=")

if [ "$TEST_VERBOSE" = "" ]; then
printf "verbose=$VERBOSE" >> $SETTINGS_FILE
fi
if [ "$TEST_PLAYER_SELECTION" = "" ]; then
printf "last-used-player=$PLAYER_SELECTION" >> $SETTINGS_FILE
fi
if [ "$TEST_OUTPUT_DIR" = "" ]; then
printf "output-directory=$OUTPUT_DIR" >> $SETTINGS_FILE
fi
if [ "$TEST_ONELINE" = "" ]; then
printf "oneline=$ONELINE" >> $SETTINGS_FILE
fi
if [ "$TEST_ONELINER_FORMAT" = "" ]; then
printf "oneliner-format=$ONELINER_FORMAT" >> $SETTINGS_FILE
fi
if [ "$TEST_RM_OUTPUT" = "" ]; then
printf "rm-output=$RM_OUTPUT" >> $SETTINGS_FILE
fi

# Clean up validation variables
unset TEST_VERBOSE
unset TEST_PLAYER_SELECTION
unset TEST_OUTPUT_DIR
unset TEST_ONELINE
unset TEST_ONELINER_FORMAT
unset TEST_RM_OUTPUT

# BEGIN MAIN LOOP
while true; do

# Check for MPRIS data update.
if [ "$(qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)" != "$(cat $SONG_METADATA)" ]; then

qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata > $SONG_METADATA

# If no album art is found, use generic image instead.
if grep -q "mpris:artUrl:" $SONG_METADATA; then

SONG_ART="$(cat $SONG_METADATA | grep "mpris:artUrl:" | sed 's/mpris:artUrl: //' | sed "s/%20/ /g")"
convert "$SONG_ART" -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

else

convert Images/NoArt.* -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

fi
# Edit the junk out of the MPRIS data.
SONG_TITLE_VAR="$(cat $SONG_METADATA | grep "xesam:title:" | sed 's/xesam:title: //')"
SONG_ARTIST_VAR="$(cat $SONG_METADATA | grep "xesam:artist:" | sed 's/xesam:artist: //')"
SONG_ALBUM_VAR="$(cat $SONG_METADATA | grep "xesam:album:" | sed 's/xesam:album: //')"

t="$SONG_TITLE_VAR"
a="$SONG_ARTIST_VAR"
i="$SONG_ALBUM_VAR"

if [ "$ONELINE" = "false" ]; then
# Save the title, artist, and album data as individual text files.
printf "$SONG_TITLE_VAR" > $SONG_TITLE
printf "$SONG_ARTIST_VAR" > $SONG_ARTIST
printf "$SONG_ALBUM_VAR" > $SONG_ALBUM
else
# Same as above, except for oneline mode.
printf "$(eval "printf \"$ONELINER_FORMAT\"")" > $SONG_ONELINER
fi

fi

# Verbosity.
if [ "$VERBOSE" = "true" ]; then

tput cup 0 0
tput ed

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =

if [ "$ONELINE" = "false" ]; then

printf "Title: $SONG_TITLE_VAR\n\nArtist: $SONG_ARTIST_VAR\n\nAlbum: $SONG_ALBUM_VAR\n"

else

printf "$(eval "printf \"$ONELINER_FORMAT\"")\n"

fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =

fi

sleep 1

# END MAIN LOOP

trap save_and_clean EXIT INT TERM

done
