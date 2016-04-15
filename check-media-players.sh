#!/bin/bash

qdbus org.mpris.MediaPlayer2.* | grep "org.mpris.MediaPlayer2." | sed 's/org.mpris.MediaPlayer2.//'

exit

