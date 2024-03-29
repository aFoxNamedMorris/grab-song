# grab-song
## Tool for scraping the song data from MPRIS enabled media players under Linux for use in streaming applications like OBS.

Requires qdbus and ImageMagick to run.
Supports any MPRIS enabled media player.

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
./grab-song.sh io.github.Pithos
./grab-song.sh audacious
./grab-song.sh clementine
./grab-song.sh vlc
./grab-song.sh NuvolaAppSpotify
```


The script will remember the last player specified, so it can be run without having to specify the player each time.
### Options:
```
ONELINE=<true/false>
```
*Determines whether or not the song data is saved as multiple individual files, or in a single line in a single file. Default is "false". This value is stored.*
```
ONELINER_FORMAT=<format>
```
*Sets the formatting used for when ONELINE is set to 'true'. If set via command line, formatting MUST be enclosed in single quotes. Valid parameters are $t (title), $a (artist), and $i (album), and can be seperated via spaces, other letters and/or symbols. Default is ' $a: $t - $i '. This value is stored.*
```
VERBOSE=<true/false>
```
*Determines whether or not the song data is displayed in the terminal window. Defaults to "true". This value is stored.*
```
OUTPUT_DIR=<Desired directory>
```
*Sets the folder where song data gets saved. Default is the "Output" subdirectory. This value is stored.*
```
RM_OUTPUT=<true/false>
```
*When "true", the files generated by the script will be removed on exit. This value is stored.*
### Examples:
```
VERBOSE=true ./grab-song.sh
VERBOSE=true ./grab-song.sh io.github.Pithos
VERBOSE=false OUTPUT_DIR=Output2 ./grab-song.sh
OUTPUT_DIR=OtherOutput ./grab-song.sh
VERBOSE=true ONELINE=true ./grab-song.sh
VERBOSE=true ONELINE=true ONELINER_FORMAT=' $t - $a - $i ' ./grab-song.sh
RM_OUTPUT=true ./grab-song.sh
```

### Setting up OBS:
In OBS, add the necessary text and/or image sources, and point them to their respective files in the 'Output' subdirectory. OBS will automatically reload the sources each time grab-song.sh updates them.

### Contributing:
If you would like to contribute, please feel free to fork the project on GitHub. <https://github.com/aFoxNamedMorris/grab-song>

### Found a bug? Have a suggestion?
If you find a bug, something is broken, or you want to suggest a new feature or improvement, you can post it either here:
<https://github.com/aFoxNamedMorris/grab-song/issues>

or here, in the 'bugs' or 'suggestions' room, respectively:
<https://discord.gg/0ygznlvzvNXXY1Qt>
