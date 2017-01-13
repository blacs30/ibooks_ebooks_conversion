#!/bin/bash
function describe {
    echo " "
    echo "#########################################################"
    echo "Usage: e.g. bash $0 $HOME/Desktop/Exportfolder $HOME/Desktop/debug.log"
    echo " "
    echo "The folder where the epub files should be exported to has to exist already. Create it before running the script."
    echo " "
    echo "This script will read the iTunes books from $STARTFOLDER"
    echo "#########################################################"
    echo " "
    }


START_temp=$HOME/Library/Containers/com.apple.BKAgentService
STARTFOLDER=$START_temp/Data/Documents/iBooks/Books

if [ -z "$1" ] || [ ! -d "$1" ]; then
echo >&2 "Error: You must supply the export folder argument as an existing directory!"
    describe
exit 1
elif [ -z "$2" ] || [ -d "$2" ]; then
echo >&2 "Error: You must supply the debug-log as a filename!"
    describe
exit 1
fi

EXPFOLDER="$1"
DEBUGLOG="$2"
TEMPDIR="$EXPFOLDER/tmp/" && mkdir -p "$TEMPDIR"


# ****************************************************************
# get file list of existing books/files in the startfolder for debugging only
# ****************************************************************
cd "$STARTFOLDER" || ( echo "The folder $STARTFOLDER does not exist" && exit 1 )
FILES="$(find . -type d -maxdepth 1)" #$FILES is only for debugging
echo "Starting the program $0:" && echo "Starting the program $0 at $(date)" > "$DEBUGLOG" # second part only for debugging
echo "Following files found:" >> "$DEBUGLOG" # only for debugging
echo "$FILES" >> "$DEBUGLOG" # only for debugging


# ***************************************************************************** *************
# exclude the root dir and ds store file in the start folder
# for each book (actually folder in iTunes) process the following steps
#     - remove iTunesMetadata
#     - get the title of the book from the opf file
#     - add mimetype file to epub zip
#     - add iTunesArtwork file to epub zip
#     - add META-INF folder to epub zip
#     - add all other files to epub zip
# ***************************************************************************** *************
for f in ./*
do
cd "$STARTFOLDER" || ( echo "The folder $STARTFOLDER does not exist" && exit 1 )
if [ "$f" == "." ] || [ "$f" == ".." ] || [ "$f" == "./.DS_Store" ] || [ ! -d "$f" ]
then
continue
fi
cp -r "$f" "$TEMPDIR/"
cd "$TEMPDIR/$f" || ( echo "The folder $TEMPDIR/$f does not exist" && exit 1 )
echo "Working now in following folder:" >> "$DEBUGLOG" # - only for debugging
echo "$f" >> "$DEBUGLOG" # - only for debugging


# ****************************************
# remove iTunesMetadata
# ****************************************
rm -rf iTunesMetadata*


# ************************************************
# get the title of the book from the opf file
# ************************************************
value=$(find . -type f -name "*.opf" -exec cat {} \;)
title=$( sed -n 's/.*<dc:title.*>\([^<]*\)<\/dc:title>.*/\1/p' <<< "$value" )
title=$( echo "$title" | cut -c 1-93 )
title=$(echo ${title/:/ })
title=$(echo ${title/\//_})
title=$(echo ${title/&amp;/&})
echo "The following book title was generated:" >> "$DEBUGLOG" # - only for debugging
echo "$title" >> "$DEBUGLOG" # - only for debugging


# ****************************************
# add mimetype file to epub zip
# ****************************************
if [ -f ./mimetype ]
then
echo "Add mimetypes to book $title" >> "$DEBUGLOG" # - only for debugging
zip -X0 "$EXPFOLDER/$title.epub" "mimetype" >> "$DEBUGLOG"
rm -rf mimetype
rm -rf ./.DS_Store
else
echo the file "mimetype" does not exist, without that file you will not have a valid epub file
exit 1
fi

# ****************************************
# add iTunesArtwork file to epub zip
# ****************************************
if [ -f ./iTunesArtwork ]
then
    cp ./iTunesArtwork ./cover.png
echo "Add iTunesArtwork to book $title" >> "$DEBUGLOG" # - only for debugging
zip -Xr "$EXPFOLDER/$title.epub" "iTunesArtwork" "cover.png" >> "$DEBUGLOG"
rm -rf ./iTunesArtwork
rm -rf ./cover.png
fi


# ****************************************
# add META-INF folder to epub zip
# ****************************************
if [ -d ./META-INF ]
then
echo "Add META-INF to book $title" >> "$DEBUGLOG" # - only for debugging
zip -Xr "$EXPFOLDER/$title.epub" "META-INF" >> "$DEBUGLOG"
rm -rf ./META-INF
fi


# ****************************************
# add all other files to epub zip
# ****************************************
FILESINDIR="./*"
for g in $FILESINDIR
do
echo "Add rest of the files to book $title" >> "$DEBUGLOG" # - only for debugging
zip -Xr "$EXPFOLDER/$title.epub" "$g" >> "$DEBUGLOG"
done
done


# ****************************************
# rename .ibooks into .epub files
# ****************************************
string='.ibooks'
cd "$EXPFOLDER" || ( echo "The folder $EXPFOLDER does not exist" && exit 1 )
for h in ./*
do
if [[ $h == *$string* ]]
then
for i in * ; do mv "$i" "${i//.ibooks/.epub}" ; done
fi
done


# ****************************************
# Remove temporary work directory
# ****************************************
echo "Remove temporary directory" >> "$DEBUGLOG"
rm -rf "$TEMPDIR"


echo "finished" && echo "Finished at $(date)" >> "$DEBUGLOG"
echo "Please find the following files in $EXPFOLDER"
echo " "
ls -a "$EXPFOLDER"
echo "Please find the log file here: $DEBUGLOG"
exit 0
