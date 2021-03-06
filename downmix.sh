#!/bin/bash

addext ()
{   
    filename="$1"
    append="$2"
    base="${filename%.*}"
    ext="${filename##*.}"
    
    echo "${base}_${append}.${ext}"
}

cd /workdir

INPUT_FILENAME="$1"
## Set output_filename to arg#2 if given, else to {input_filename}_new.
if [ -z "$2" ]; then
    OUTPUT_FILENAME=$(addext $INPUT_FILENAME "new")
else
    OUTPUT_FILENAME="$2"
fi
TEMP_STEREO_AUDIO=".temp_stereo_audio_$RANDOM-$RANDOM-$RANDOM.m4a"

AUDIO_CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channel_layout -of default=noprint_wrappers=1:nokey=1 "$1")
#AUDIO_CHANNELS=$(ffprobe -v error -show_streams -select_streams a "$1" | grep -Po "(?<=^channel_layout\=)\d*\.\d*")

case $AUDIO_CHANNELS in
    '5.1')
        # 5.1 Surround
        echo "5.1 Surround detected."
        FL="0.5*FC+0.707*FL+0.707*BL+0.5*LFE"
        FR="0.5*FC+0.707*FR+0.707*BR+0.5*LFE"
        ;;
    '5.1(side)')
        # 5.1(side) Surround
        echo "5.1(side) Surround detected."
        FL="0.5*FC+0.707*FL+0.707*SL+0.5*LFE"
        FR="0.5*FC+0.707*FR+0.707*SR+0.5*LFE"
        ;;
    '6.1')
        # 6.1 Surround
        echo "6.1 Surround detected."
        FL="0.321953*FC+0.455310*FL+0.394310*SL+0.227655*SR+0.278819*BC+0.321953*LFE"
        FR="0.321953*FC+0.455310*FR+0.394310*SR+0.227655*SL+0.278819*BC+0.321953*LFE"
        ;;
    '7.1')
        # 7.1 Surround
        echo "7.1 Surround detected."
        FL="0.274804*FC+0.388631*FL+0.336565*SL+0.194316*SR+0.336565*BL+0.194316*BR+0.274804*LFE"
        FR="0.274804*FC+0.388631*FR+0.336565*SR+0.194316*SL+0.336565*BR+0.194316*BL+0.274804*LFE"
        ;;
    '5.1')
        echo "$INPUT_FILENAME: No primary surround sound source detected. Stereo sound primary may already be present."
        exit 0
        ;;
esac
echo "$INPUT_FILENAME: Using FL:$FL | FR:$FR"

## Audio bitrate is set the same as the incoming video. Fallback to 192k.
AUDIO_BRT=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$1")
if [ -z "$AUDIO_BRT" ]; then
    echo "Default bitrate: 192k"
    AUDIO_BRT="192k"
fi

## Audio codec set to libfdk_aac if available. Fallback to aac.
if ffmpeg -codecs 2>&1 | grep -q "aac libfdk_aac"; then
    echo "Audio Codec libfdk_aac available. Using libfdk_aac."
    AUDIO_FMT="libfdk_aac"
else
    echo "Audio Codec libfdk_aac NOT found. Falling back to aac.."
    AUDIO_FMT="aac"
fi

rm -f "$TEMP_STEREO_AUDIO"

ffmpeg -i "$INPUT_FILENAME" -vn \
    -acodec $AUDIO_FMT -b:a $AUDIO_BRT \
    -af "pan=stereo|FL=$FL|FR=$FR" \
    "$TEMP_STEREO_AUDIO"

    # to test a snippet of the video
    # -ss 0:00.0 -t 600 \

DOWNMIX_AUDIO_STATUS=$?

if [ $DOWNMIX_AUDIO_STATUS -eq 0 ]; then
    ffmpeg -i "$INPUT_FILENAME" -i "$TEMP_STEREO_AUDIO" -map 0:v:0 \
        -map 1:a -map 0:a \
        -map 0:s -c copy \
        -disposition:a:0 default \
        -shortest "$OUTPUT_FILENAME"
    
    RECOMBINE_FILE_STATUS=$?
fi

## If there was only one input given, delete input file and rename output file to original name.
#  This is really for automation purposes. If testing, specify the output filename to preserve both files.
if [ $DOWNMIX_AUDIO_STATUS -eq 0 ] && [ $RECOMBINE_FILE_STATUS -eq 0 ]; then
    if [ -z "$2" ]; then
        rm -f "$INPUT_FILENAME"
        mv "$OUTPUT_FILENAME" "$INPUT_FILENAME"
    fi
else
    rm -f "$OUTPUT_FILENAME"
fi

rm -f "$TEMP_STEREO_AUDIO"

exit 0

#Source for mix ratios : https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg