# grab-song
## Tool for scraping the song data from MPRIS enabled media players under Linux for use in streaming applications like OBS.

Requires qdbus and ImageMagick to run.
Supports any MPRIS enabled media player.

Must (for now) be run from the directory that it's stored in.
WIP! There are a few bugs, and it is not entirely finished.

Outputs the song title, artist, and album data, as well as the album art to the 'Output' subdirectory.
If no album art is found, a generic one is substituted in. The album art is always converted to a 500x500px AlbumArt.jpg so as to keep your OBS scene composition uniform between data updates.

### Usage:
```
./grab-song.sh <player>
```

Keep in mind that you must have your player of choice running or the script will produce errors.

### Examples:
```
./grab-song.sh pithos
./grab-song.sh audacious
./grab-song.sh clementine
./grab-song.sh vlc
./grab-song.sh NuvolaAppSpotify
```


The script will remember the last player specified, so it can be run without having to specify the player each time.
### Options:
```
VERBOSE=<true/false> 
```
*_Defaults to "false"_*.
```
OUTPUT_DIR=<Desired directory> 
```
*_Defaults to the "Output" subdirectory._*

### Examples:
```
VERBOSE=true ./grab-song 
VERBOSE=true ./grab-song pithos
VERBOSE=false OUTPUT_DIR=Output2 ./grab-song 
```

A utility is included which will list the available players' arguments, so you don't have to guess. It can also be paired with the 'watch -t' command to give a real(ish)-time update, so as to avoid having to rerun the utility each time a new media player is started. 

### Usages:
```
./check-media-players.sh
watch -t ./check-media-players.sh
```

### Setting up OBS:
In OBS, add the necessary text and/or image sources, and point them to their respective files in the 'Output' subdirectory. OBS will automatically reload the sources each time grab-song.sh updates them.

### Contributing:
If you would like to contribute, please feel free to fork the project on GitHub. https://github.com/aFoxNamedMorris/grab-song
