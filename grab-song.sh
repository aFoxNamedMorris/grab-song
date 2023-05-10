#!/bin/sh

export LC_ALL=C.UTF-8

tput civis
stty -echo

generate_settings()
{
  printf "verbose=%s\n" "$VERBOSE"
  if [ -z "$PLAYER_SELECTION" ]; then return; else printf "last-used-player=%s\n" "$PLAYER_SELECTION"; fi
  printf "output-directory=%s\n" "$OUTPUT_DIR"
  printf "oneline=%s\n" "$ONELINE"
  printf "oneliner-format= \$a: \$t - \$i \n"
  printf "rm-output=%s\n" "$RM_OUTPUT" 
} >> "$SETTINGS_FILE"

# Define a function for cleaning up temporary files.
save()
{
  sed -i "/verbose=/ c\verbose=$VERBOSE" "$SETTINGS_FILE"
  sed -i "/last-used-player=/ c\last-used-player=$PLAYER_SELECTION" "$SETTINGS_FILE"
  sed -i "/output-directory=/ c\output-directory=$OUTPUT_DIR" "$SETTINGS_FILE"
  sed -i "/oneline=/ c\oneline=$ONELINE" "$SETTINGS_FILE"
  sed -i "/oneliner-format=/ c\oneliner-format=$ONELINER_FORMAT" "$SETTINGS_FILE"
  sed -i "/rm-output=/ c\rm-output=$RM_OUTPUT" "$SETTINGS_FILE"
}

save_and_quit()
{
  save
  rm -r "$TMP_DIR"
  if $RM_OUTPUT; then
    rm -r "$OUTPUT_DIR"
  fi
  kill "$(jobs -p)"
  stty echo
  tput cnorm
  reset
  exit
}

if [ -z "$CONFIG_DIR" ]; then CONFIG_DIR=${CONFIG_DIR-Config}; fi
if [ -z "$TMP_DIR" ]; then TMP_DIR=$(mktemp -d /tmp/grab-song.XXXXXXXXXXX); fi
if [ "$OUTPUT_DIR" = "" ]; then OUTPUT_DIR='Output'; fi
if [ "$SETTINGS_FILE" = "" ]; then SETTINGS_FILE="$CONFIG_DIR/settings.conf"; fi

# Make sure config directory is present
mkdir -p "$CONFIG_DIR"

# Generate a default config if not present
if [ ! -f "$SETTINGS_FILE" ]; then
  generate_settings
  save
fi

# Load stored settings, if any.
VERBOSE=${VERBOSE-$(cat < "$SETTINGS_FILE" | grep "verbose=" | sed 's/verbose=//')}

PLAYER_SELECTION=${1-$(cat < "$SETTINGS_FILE" | grep "last-used-player=" | sed 's/last-used-player=//')}

# Function for listing compatible media players. (TODO: Create interactive menus!)
list_media_players()
{
  qdbus org.mpris.MediaPlayer2.* | grep "org.mpris.MediaPlayer2." | sed 's/org.mpris.MediaPlayer2.//'
}

  OUTPUT_DIR=${OUTPUT_DIR-$(cat < "$SETTINGS_FILE" | grep "output-directory=" | sed 's/output-directory=//')}

  ONELINE=${ONELINE-$(cat < "$SETTINGS_FILE" | grep "oneline=" | sed 's/oneline=//')}
  ONELINER_FORMAT=${ONELINER_FORMAT-$(cat < "$SETTINGS_FILE" | grep "oneliner-format=" | sed 's/oneliner-format=//')}

  RM_OUTPUT=${RM_OUTPUT-$(cat < "$SETTINGS_FILE" | grep "rm-output=" | sed 's/rm-output=//')}

  # Test to make sure everything is present in the settings file.
  TEST_VERBOSE=$(cat < "$SETTINGS_FILE" | grep "verbose=")
  TEST_PLAYER_SELECTION=$(cat < "$SETTINGS_FILE" | grep "last-used-player=")
  TEST_OUTPUT_DIR=$(cat < "$SETTINGS_FILE" | grep "output-directory=")
  TEST_ONELINE=$(cat < "$SETTINGS_FILE" | grep "oneline=")
  TEST_ONELINER_FORMAT=$(cat < "$SETTINGS_FILE" | grep "oneliner-format=")
  TEST_RM_OUTPUT=$(cat < "$SETTINGS_FILE" | grep "rm-output=")

  if [ "$TEST_VERBOSE" = "" ]; then
    printf "verbose=%s\n" "$VERBOSE" >> "$SETTINGS_FILE"
  fi
  if [ "$TEST_PLAYER_SELECTION" = "" ]; then
    printf "last-used-player=%s\n" "$PLAYER_SELECTION" >> "$SETTINGS_FILE"
  fi
  if [ "$TEST_OUTPUT_DIR" = "" ]; then
    printf "output-directory=%s\n" "$OUTPUT_DIR" >> "$SETTINGS_FILE"
  fi
  if [ "$TEST_ONELINE" = "" ]; then
    printf "oneline=%s\n" "$ONELINE" >> "$SETTINGS_FILE"
  fi
  if [ "$TEST_ONELINER_FORMAT" = "" ]; then
    printf "oneliner-format=%s\n" "$ONELINER_FORMAT" >> "$SETTINGS_FILE"
  fi
  if [ "$TEST_RM_OUTPUT" = "" ]; then
    printf "rm-output=%s\n" "$RM_OUTPUT" >> "$SETTINGS_FILE"
  fi

# If no media player is specified, throw an error and list currently available media players.
if [ "$(qdbus org.mpris.MediaPlayer2."$PLAYER_SELECTION" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)" = "" ]; then
  stty echo
  tput cnorm
  printf "Please specify a media player and try again.\n\nAvailable media players are listed below:\n\n%s\n\n" "$(list_media_players)"
  printf "If the media player is listed but does not work\nplease make sure that your media is playing and\nthat MPRIS is supported by and enabled in your\nmedia player of choice.\n\n"
  exit
fi

  # Clean up validation variables
  unset TEST_VERBOSE
  unset TEST_PLAYER_SELECTION
  unset TEST_OUTPUT_DIR
  unset TEST_ONELINE
  unset TEST_ONELINER_FORMAT
  unset TEST_RM_OUTPUT

  # Set defaults if settings aren't present.
  if [ "$ONELINER_FORMAT" = "" ]; then ONELINER_FORMAT=" $a: $t - $i "; fi
  if [ "$FIRSTRUN" = "" ]; then FIRSTRUN='true'; fi
  if [ "$VERBOSE" = "" ]; then VERBOSE='true'; fi
  if [ "$ONELINE" = "" ]; then ONELINE='false'; fi
  if [ "$PLAYER_SELECTION" = "" ]; then PLAYER_SELECTION=''; fi
  if [ "$RM_OUTPUT" = "" ]; then RM_OUTPUT='false'; fi

  SONG_METADATA="$TMP_DIR/SongMetaData.txt"
  SONG_TITLE="$OUTPUT_DIR/SongTitle.txt"
  SONG_ARTIST="$OUTPUT_DIR/SongArtist.txt"
  SONG_ALBUM="$OUTPUT_DIR/SongAlbum.txt"
  SONG_ONELINER="$OUTPUT_DIR/SongInfo.txt"

  # Set up the locations of the output files.
  mkdir -p "$OUTPUT_DIR"
  touch "$SONG_METADATA"
  touch "$SONG_TITLE"
  touch "$SONG_ARTIST"
  touch "$SONG_ALBUM"
  touch "$SONG_ONELINER"

  # BEGIN MAIN LOOP
  while true; do

    # Check for MPRIS data update.
    if [ "$(qdbus org.mpris.MediaPlayer2."$PLAYER_SELECTION" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata)" != "$(cat "$SONG_METADATA")" ]; then

      qdbus org.mpris.MediaPlayer2."$PLAYER_SELECTION" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata > "$SONG_METADATA"

      # If no album art is found, use generic image instead.
      if grep -q "mpris:artUrl:" "$SONG_METADATA"; then

        SONG_ART="$(cat < "$SONG_METADATA" | grep "mpris:artUrl:" | sed 's/mpris:artUrl: //' | sed "s/%20/ /g")"

        # Working around the broken image urls that spotify gives mpris
        if [ "$PLAYER_SELECTION" = "spotify" ]; then
          SONG_ART=$(echo "$SONG_ART" | sed "s/open.spotify.com/i.scdn.co/g")
        fi

        convert "$SONG_ART" -resize 500x500! "$OUTPUT_DIR/AlbumArt.jpg" >/dev/null

      else

        convert Images/NoArt.* -resize 500x500! "$OUTPUT_DIR/AlbumArt.jpg" >/dev/null

      fi
      # Edit the junk out of the MPRIS data.
      SONG_TITLE_VAR="$(cat < "$SONG_METADATA" | grep "xesam:title:" | sed 's/.*title: //')"
      SONG_ARTIST_VAR="$(cat < "$SONG_METADATA" | grep "xesam:artist:" | sed 's/.*artist: //')"
      SONG_ALBUM_VAR="$(cat < "$SONG_METADATA" | grep "xesam:album:" | sed 's/.*album: //')"

      export t="$SONG_TITLE_VAR"
      export a="$SONG_ARTIST_VAR"
      export i="$SONG_ALBUM_VAR"

      if [ "$ONELINE" = "false" ]; then
        # Save the title, artist, and album data as individual text files.
        printf "%s" "$SONG_TITLE_VAR" > "$SONG_TITLE"
        printf "%s" "$SONG_ARTIST_VAR" > "$SONG_ARTIST"
        printf "%s" "$SONG_ALBUM_VAR" > "$SONG_ALBUM"
      else
        # Same as above, except for oneline mode.
        printf "%s\n" "$(eval "printf \"$ONELINER_FORMAT\"")" > "$SONG_ONELINER"
      fi

    fi

    # Verbosity.
    if [ "$VERBOSE" = "true" ]; then

      tput cup 0 0
      tput ed

      printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =

      if [ "$ONELINE" = "false" ]; then

        if [ "$SONG_TITLE_VAR" != "" ]; then
          printf "\nTitle: %s\n" "$SONG_TITLE_VAR"
        fi

        if [ "$SONG_ARTIST_VAR" != "" ]; then
          printf "\nArtist: %s\n" "$SONG_ARTIST_VAR"
        fi

        if [ "$SONG_ALBUM_VAR" != "" ]; then
          printf "\nAlbum: %s\n" "$SONG_ALBUM_VAR"
        fi

      else

        printf "%s\n" "$(eval "printf \"$ONELINER_FORMAT\"")"

      fi

      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =

    fi

    sleep 1

    # END MAIN LOOP

    trap save_and_quit EXIT INT TERM

  done
