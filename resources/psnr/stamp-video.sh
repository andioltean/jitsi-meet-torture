#!/bin/sh -e
#
# Copyright @ 2015 Atlassian Pty Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

VIDEO_SZ=1280x720
VIDEO_FPS=60
VIDEO_FMT=yuv4mpegpipe 
VIDEO_PIXEL_FMT=yuv420p
VIDEO_IN_FILE="$1"
VIDEO_IN_FILE_BASENAME=$(basename "$VIDEO_IN_FILE")
VIDEO_OUT_FILE=output/stamped-$VIDEO_IN_FILE_BASENAME
IMAGE_EXTENSION=png
QR_IMAGE_FILE_PREFIX="qrcode"
QR_IMAGE_OUT_DIRECTORY=output/qrcode
RAW_IMAGE_FILE_PREFIX=$VIDEO_IN_FILE_BASENAME
RAW_IMAGE_FILE_PREFIX="${RAW_IMAGE_FILE_PREFIX%.*}"
RAW_IMAGE_OUT_DIRECTORY=output/raw
RAW_IMAGES_PATTERN=$RAW_IMAGE_OUT_DIRECTORY/$RAW_IMAGE_FILE_PREFIX-%03d.$IMAGE_EXTENSION
STAMPED_IMAGE_FILE_PREFIX=stamped-$RAW_IMAGE_FILE_PREFIX
STAMPED_IMAGE_OUT_DIRECTORY=output/stamped
STAMPED_IMAGES_PATTERN=$STAMPED_IMAGE_OUT_DIRECTORY/$STAMPED_IMAGE_FILE_PREFIX-%03d.$IMAGE_EXTENSION 
FFMPEG=ffmpeg
FFMPEG_VIDEO_IN_ARGS="-i $VIDEO_IN_FILE"
FFMPEG_IMAGE_OUT_ARGS="-r $VIDEO_FPS -s $VIDEO_SZ -f image2 $RAW_IMAGES_PATTERN"
FFMPEG_IMAGE_IN_ARGS="-f image2 -framerate $VIDEO_FPS -i $STAMPED_IMAGES_PATTERN"
FFMPEG_VIDEO_OUT_ARGS="-s $VIDEO_SZ -f $VIDEO_FMT -pix_fmt $VIDEO_PIXEL_FMT $VIDEO_OUT_FILE"

# Create output directories.
mkdir -p $QR_IMAGE_OUT_DIRECTORY $RAW_IMAGE_OUT_DIRECTORY $STAMPED_IMAGE_OUT_DIRECTORY

# Extract images from video
RAW_IMAGE_FILES_COUNT=$(ls -1 $RAW_IMAGE_OUT_DIRECTORY/*.$IMAGE_EXTENSION|wc -l)
if [ "$RAW_IMAGE_FILES_COUNT" = "0" ]
then
  $FFMPEG $FFMPEG_VIDEO_IN_ARGS $FFMPEG_IMAGE_OUT_ARGS
  RAW_IMAGE_FILES_COUNT=$(ls -1 $RAW_IMAGE_OUT_DIRECTORY/*.$IMAGE_EXTENSION|wc -l)
fi

# Stamp each output image.
STAMPED_IMAGE_FILES_COUNT=$(ls -1 $STAMPED_IMAGE_OUT_DIRECTORY/*.$IMAGE_EXTENSION|wc -l)
if [ "$STAMPED_IMAGE_FILES_COUNT" = "0" ]
then
  for i in $(seq -f "%03g" $RAW_IMAGE_FILES_COUNT)
  do
    QR_IMAGE_FILE="$QR_IMAGE_OUT_DIRECTORY/$QR_IMAGE_FILE_PREFIX-$i.$IMAGE_EXTENSION"
    RAW_IMAGE_FILE="$RAW_IMAGE_OUT_DIRECTORY/$RAW_IMAGE_FILE_PREFIX-$i.$IMAGE_EXTENSION" 
    STAMPED_IMAGE_FILE="$STAMPED_IMAGE_OUT_DIRECTORY/$STAMPED_IMAGE_FILE_PREFIX-$i.$IMAGE_EXTENSION"

    qrencode --size=12 --level=H -o "$QR_IMAGE_FILE" "$i"
    $FFMPEG -i $RAW_IMAGE_FILE -i $QR_IMAGE_FILE -filter_complex overlay=10:10 $STAMPED_IMAGE_FILE
  done
fi

# Creating a video from many images
$FFMPEG $FFMPEG_IMAGE_IN_ARGS $FFMPEG_VIDEO_OUT_ARGS
