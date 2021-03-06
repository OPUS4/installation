#!/bin/bash
#
# LICENCE
# This code is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# @author      Edouard Simon <edouard.simon@zib.de>
# @copyright   Copyright (c) 2013, OPUS 4 development team
# @license     http://www.gnu.org/licenses/gpl.html General Public License
# @version     $Id$

# Updates the ZendFramework library to Version 1.12.9

set -o errexit

DOWNLOADS_DIR="$OPUS_UPDATE_BASEDIR"/downloads 
LIB_DIR="$OPUS_UPDATE_BASEDIR"/libs
NEW_ZEND_FOLDER='ZendFramework-1.12.9-minimal'
ZEND_LIB_URL='https://packages.zendframework.com/releases/ZendFramework-1.12.9/ZendFramework-1.12.9-minimal.tar.gz'

echo "Updating Zend-Framework to Version 1.12.9"

echo "$LIB_DIR/$NEW_ZEND_FOLDER"
if [ -d "$LIB_DIR/$NEW_ZEND_FOLDER" ];
then
  echo "Zend-Framework Version 1.12.9 already installed. Nothing to do here."
  exit 0
fi

if [ ! -d "$DOWNLOADS_DIR" ];
then
    mkdir "$DOWNLOADS_DIR"
fi

if [ ! -d "$LIB_DIR" ];
then
    echo "Library directory $LIB_DIR not found. Please check."
    echo "NOT updating Zend-Framework!"
    exit 1
fi

echo "Downloading Zend-Framework Version 1.12.9"

if ! wget -O "$DOWNLOADS_DIR"/zend.tar.gz "$ZEND_LIB_URL";
then
  echo "Unable to download $ZEND_LIB_URL"
  exit 1
fi

tar xzf "$DOWNLOADS_DIR/zend.tar.gz" -C "$LIB_DIR"

echo "Updating Symlink to Zend-Framework"
cd "$LIB_DIR"
rm ZendFramework
ln -svf ZendFramework-1.12.9-minimal ZendFramework

echo "done"
exit 0
