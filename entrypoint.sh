#!/bin/bash

set -e

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

BASE_DIR="$PWD"
TMP_DIR="$BASE_DIR/tmp"
BUILDS_DIR="$BASE_DIR/builds"
CONFIG_DIR="$BASE_DIR/etc"

test -s "$CONFIG_DIR"/"terraform.conf" && source "$CONFIG_DIR"/"terraform.conf" || ( echo "E: No config file [terraform.conf]" > /dev/stderr &&  exit 1 )

source "$CONFIG_DIR"/"terraform.conf"

ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/"$BASECODENAME"

build () {
  BUILD_ARCH="$1"

  if [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR/*"
    mkdir -p "$TMP_DIR/$BUILD_ARCH"
  else
    mkdir -p "$TMP_DIR/$BUILD_ARCH"
  fi

  cd "$TMP_DIR/$BUILD_ARCH" || exit

  # remove old configs and copy over new
  rm -rf config auto terraform.conf
  cp -rf "$CONFIG_DIR"/* .

  # Symlink chosen package lists to where live-build will find them
  ln -s "package-lists.$PACKAGE_LISTS_SUFFIX" "config/package-lists"

  echo -e "
#------------------#
# LIVE-BUILD CLEAN #
#------------------#
"
  lb clean

  echo -e "
#-------------------#
# LIVE-BUILD CONFIG #
#-------------------#
"
  lb config

  echo -e "
#------------------#
# LIVE-BUILD BUILD #
#------------------#
"
  lb build

  echo -e "
#---------------------------#
# MOVE OUTPUT TO BUILDS DIR #
#---------------------------#
"

    YYYYMMDD="$(date +%Y%m%d%H%M)"
    OUTPUT_DIR="$BUILDS_DIR/$BUILD_ARCH"
    mkdir -p "$OUTPUT_DIR"
    if [ "$CHANNEL" == dev ]; then
      FNAME="$OUTPUT_PREFIX-$VERSION-$CHANNEL-$YYYYMMDD-$OUTPUT_SUFFIX-$ARCH"
    elif [ "$CHANNEL" == stable ] && [ "BETA" == true ]; then
      FNAME="$OUTPUT_PREFIX-$VERSION-beta-$OUTPUT_SUFFIX-$ARCH"
    elif [ "$CHANNEL" == stable ] && [ "BETA" == false ]; then
      FNAME="$OUTPUT_PREFIX-$VERSION-$OUTPUT_SUFFIX-$ARCH"
    else
      echo -e "Error: invalid channel name!"
    fi
    mv "$TMP_DIR/$BUILD_ARCH/live-image-$BUILD_ARCH.hybrid.iso" "$OUTPUT_DIR/${FNAME}.iso"

    md5sum "$OUTPUT_DIR/${FNAME}.iso" > "$OUTPUT_DIR/${FNAME}.md5.txt"
    sha256sum "$OUTPUT_DIR/${FNAME}.iso" > "$OUTPUT_DIR/${FNAME}.sha256.txt"
}

# remove old builds before creating new ones
rm -rf "$BUILDS_DIR/*"

build "$ARCH"
