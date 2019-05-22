#!/bin/bash

# Lighten a file and output an mp4 without b frames
ffmpeg -i $INVID -vf "split [main][tmp]; [tmp] lutyuv="y=val*5" [tmp2]; [main][tmp2] overlay" -x264opts bframes=0 $OUTVID

# Get sum length of videos in a directory
find . -maxdepth 1 -iname '*.mp4' -exec ffprobe -v quiet -of csv=p=0 -show_entries format=duration {} \; | paste -sd+ -| bc

# extract first frame from a video
ffmpeg -i $INVID -ss 00:00:00 -vframes 1 $OUTFILE


# Extract a one second vid with a false positive
ffmpeg -ss <false_positive_first_frame_time> -i <false_positive_vid> -t 1 -c copy short_fp_vid.mp4
# Extract all frames to tif
ffmpeg -i short_fp_vid.mp4 frame_%00d.tif
# None of the full color tif files false positive
zbarimg *.tif
# Use ffmpeg to convert all tif files to grayscale
FRAMES=$(find . -iname "*.tif*")
for FRAME in $FRAMES; do
ffmpeg -i $FRAME -vf format=gray ${FRAME%.*}_bw.tif
done
# Now false positive with grayscale tif
zbarimg *_bw.tif

    
# Merge two audio channels
# https://stackoverflow.com/questions/14498539/how-to-overlay-two-audio-files-using-ffmpeg
ffmpeg -i $INPUT1 -i $INPUT2 -filter_complex amerge -ac 2 -c:a libmp3lame $OUTPUT

# Scale a video, no b frame output
# Note that crf is an arbitrary number I used to replicate revl camera settings. 
ffmpeg -i $INPUT -vf scale=w=$WIDTH:h=$HEIGHT -crf 16 -bf 0 $OUTPUT

# Get timebase, profile, level and lots of other info on a video's streams
ffprobe -show_streams $INPUT

# Print all keyframe times
ffprobe -loglevel error -skip_frame nokey -select_streams v:0 -show_entries frame=pkt_pts_time -of csv=print_section=0 $INPUT

# Get frame count
ffprobe -show_frames -pretty INPUT | grep <video|audio> | wc -l

# Make a video with two audio streams
ffmpeg -i $INPUT_VID -i $INPUT_SONG -map 0:v -map 0:a -map 1:a -codec copy $OUTPUT

# Change the sample rate of an audio file
ffmpeg -i $INPUT_AUDIO -ar $SAMPLE_RATE $OUTPUT_AUDIO

# Change the number of channels and bitrate of an audio file
ffmpeg -i $INPUT_AUDIO -ac $CHANNEL_NUM -ab 128k $OUTPUT_AUDIO
