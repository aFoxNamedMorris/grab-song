#!/bin/sh

tput civis
stty -echo

cd "${0%/*}"

# Define some defaults.
TMP_DIR=`mktemp -d /tmp/$0.XXXXXXXXXXX`
CONFIG_DIR=${CONFIG_DIR-Config}
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
ONELINER_FORMAT=' $a: $t - $i '
OUTPUT_DIR='Output'

mkdir -p $CONFIG_DIR
if [ ! -f $SETTINGS_FILE ]; then
    echo "verbose=false" >> $SETTINGS_FILE
    echo "last-used-player=" >> $SETTINGS_FILE
    echo "output-directory=$OUTPUT_DIR" >> $SETTINGS_FILE
    echo "oneline=false" >> $SETTINGS_FILE
    echo 'oneliner-format= $a: $t - $i ' >> $SETTINGS_FILE
    echo "rm-output=$RM_OUTPUT" >> $SETTINGS_FILE
fi

VERBOSE=${VERBOSE-$(cat $SETTINGS_FILE | grep "verbose=" | sed 's/verbose=//')}

PLAYER_SELECTION=${1-$(cat $SETTINGS_FILE | grep "last-used-player=" | sed 's/last-used-player=//')}

OUTPUT_DIR=${OUTPUT_DIR-$(cat $SETTINGS_FILE | grep "output-directory=" | sed 's/output-directory=//')}

ONELINE=${ONELINE-$(cat $SETTINGS_FILE | grep "oneline=" | sed 's/oneline=//')}
ONELINER_FORMAT=${ONELINER_FORMAT-$(cat $SETTINGS_FILE | grep "oneliner-format=" | sed 's/oneliner-format=//')}

RM_OUTPUT=${RM_OUTPUT-$(cat $SETTINGS_FILE | grep "rm-output=" | sed 's/rm-output=//')}

SONG_METADATA="$TMP_DIR/SongMetaData.txt"
SONG_TITLE="$OUTPUT_DIR/SongTitle.txt"
SONG_ARTIST="$OUTPUT_DIR/SongArtist.txt"
SONG_ALBUM="$OUTPUT_DIR/SongAlbum.txt"
SONG_ONELINER="$OUTPUT_DIR/SongInfo.txt"

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
echo "verbose=$VERBOSE" >> $SETTINGS_FILE
fi
if [ "$TEST_PLAYER_SELECTION" = "" ]; then
echo "last-used-player=$PLAYER_SELECTION" >> $SETTINGS_FILE
fi
if [ "$TEST_OUTPUT_DIR" = "" ]; then
echo "output-directory=$OUTPUT_DIR" >> $SETTINGS_FILE
fi
if [ "$TEST_ONELINE" = "" ]; then
echo "oneline=$ONELINE" >> $SETTINGS_FILE
fi
if [ "$TEST_ONELINER_FORMAT" = "" ]; then
echo "oneliner-format=$ONELINER_FORMAT" >> $SETTINGS_FILE
fi
if [ "$TEST_RM_OUTPUT" = "" ]; then
echo "rm-output=$RM_OUTPUT" >> $SETTINGS_FILE
fi

# Clean up validation variables
unset TEST_VERBOSE
unset TEST_PLAYER_SELECTION
unset TEST_OUTPUT_DIR
unset TEST_ONELINE
unset TEST_ONELINER_FORMAT
unset TEST_RM_OUTPUT

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

# BEGIN MAIN LOOP
while true; do
(

# Check for MPRIS data update.
if [ "$(qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)" != "$(cat $SONG_METADATA)" ]; then
(

qdbus org.mpris.MediaPlayer2.$PLAYER_SELECTION /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata > $SONG_METADATA

# If no album art is found, use generic image instead.
if grep -q "mpris:artUrl:" $SONG_METADATA; then

SONG_ART="$(cat $SONG_METADATA | grep "mpris:artUrl:" | sed 's/mpris:artUrl: //' | sed "s/%20/ /g")"
convert "$SONG_ART" -resize 500x500! $OUTPUT_DIR/AlbumArt.jpg &>/dev/null

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
