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
# @author      Susanne Gottwald <gottwald@zib.de>
# @author      Jens Schwidder <schwidder@zib.de>
# @copyright   Copyright (c) 2011, OPUS 4 development team
# @license     http://www.gnu.org/licenses/gpl.html General Public License
# @version     $Id$

# Updates the OPUS4 *scripts* folder

set -o errexit

source update-common.sh

setVars

SCRIPTS_PATH=opus4/scripts
OLD_SCRIPTS="$BASEDIR/$SCRIPTS_PATH"
NEW_SCRIPTS="$BASE_SOURCE/$SCRIPTS_PATH"

echo -e "Updating $OLD_SCRIPTS ... \c "
# Files in the scripts folder are updated without checks
updateFolder "$NEW_SCRIPTS" "$OLD_SCRIPTS"
# Files that are not part of new distribution are deleted
deleteFiles "$NEW_SCRIPTS" "$OLD_SCRIPTS"

# Remove Update opus-apache-rewritemap-caller-secure.sh if present
FILE="opus-apache-rewritemap-caller-secure.sh"

if [[ -f "$OLD_SCRIPTS/$FILE" ]]; then 
    deleteFile "$OLD_SCRIPTS/$FILE"
fi

echo "done"

