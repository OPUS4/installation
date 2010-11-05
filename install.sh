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
# @author      Sascha Szott <szott@zib.de>
# @copyright   Copyright (c) 2010, OPUS 4 development team
# @license     http://www.gnu.org/licenses/gpl.html General Public License
# @version     $Id$

#set -ex
set -e

clear

BASEDIR=/var/local/opus4

ZEND_LIB_URL='http://framework.zend.com/releases/ZendFramework-1.10.6/ZendFramework-1.10.6-minimal.tar.gz'
JPGRAPH_LIB_URL='http://jpgraph.net/download/download.php?p=1'
SOLR_PHP_CLIENT_LIB_URL='http://solr-php-client.googlecode.com/svn/trunk/'
SOLR_PHP_CLIENT_LIB_REVISION=36
JQUERY_LIB_URL='http://code.jquery.com/jquery-1.4.3.min.js'

MYSQL_CLIENT=/usr/bin/mysql

cd $BASEDIR

if [ ! -d downloads ]; then
  mkdir -p downloads
  cd downloads
  wget -O zend.tar.gz "$ZEND_LIB_URL"
  if [ ! -f zend.tar.gz ]
  then
    echo "Unable to download $ZEND_LIB_URL"
    exit 1
  fi

  wget -O jpgraph.tar.gz "$JPGRAPH_LIB_URL"
  if false && [ ! -f jpgraph.tar.gz ]
  then
    echo "Unable to download $JPGRAPH_LIB_URL"
    exit 1
  fi

  cd -
fi


# create .htaccess
sed -e 's!<template>!/opus4!' opus4/public/htaccess-template > opus4/public/.htaccess

# download and install required libraries
cd libs
tar xfvz ../downloads/zend.tar.gz
ln -svf ZendFramework-1.10.6-minimal ZendFramework

mkdir -p jpgraph-3.0.7
cd jpgraph-3.0.7
tar xfvz ../../downloads/jpgraph.tar.gz
cd ..
ln -svf jpgraph-3.0.7 jpgraph

svn export --revision $SOLR_PHP_CLIENT_LIB_REVISION --force "$SOLR_PHP_CLIENT_LIB_URL" SolrPhpClient_r$SOLR_PHP_CLIENT_LIB_REVISION
if [ ! -d SolrPhpClient_r$SOLR_PHP_CLIENT_LIB_REVISION ]
then
  echo "Unable to download $SOLR_PHP_CLIENT_LIB_URL"
  exit 1
fi
ln -svf SolrPhpClient_r$SOLR_PHP_CLIENT_LIB_REVISION SolrPhpClient
cd $BASEDIR 

# download jQuery library
cd opus4/public/js
wget -O jquery.js "$JQUERY_LIB_URL"
cd $BASEDIR

# prompt for database parameters
read -p "New OPUS Database Name [opus400]: "          DBNAME
read -p "New OPUS Database Admin Name [opus4admin]: " ADMIN
read -p "New OPUS Database Admin Password: " -s       ADMIN_PASSWORD
echo ""
read -p "New OPUS Database User Name [opus4]: "       WEBAPP_USER
read -p "New OPUS Database User Password: " -s        WEBAPP_USER_PASSWORD
echo ""
read -p "MySQL DBMS Host [leave blank for using Unix domain sockets]: " MYSQLHOST
read -p "MySQL DBMS Port [leave blank for using Unix domain sockets]: " MYSQLPORT
read -p "MySQL Root User [root]: "                                      MYSQLROOT
#read -p "MySQL Root Password: " -s                                      MYSQLROOT_PASSWORD
echo ""


# set defaults if value is not given
if [ -z $DBNAME ]; then
   DBNAME=opus400
fi
if [ -z $ADMIN ]; then
   ADMIN=opus4admin
fi
if [ -z $WEBAPP_USER ]; then
   WEBAPP_USER=opus4
fi
if [ -z $MYSQLROOT ]; then
   MYSQLROOT=root
fi

# process creating mysql user and database
MYSQL="$MYSQL_CLIENT --default-character-set=utf8 -u $MYSQLROOT -p$MYSQLROOT_PASSWORD -v"
MYSQL_OPUS4ADMIN="$MYSQL_CLIENT --default-character-set=utf8 -u $ADMIN -p$ADMIN_PASSWORD -v"
if [ ! -z $MYSQLHOST]; then
  MYSQL="$MYSQL -h $MYSQLHOST"
  MYSQL_OPUS4ADMIN="$MYSQL_OPUS4ADMIN -h $MYSQLHOST"
fi
if [ ! -z $MYSQLPORT]; then
  MYSQL="$MYSQL -P $MYSQLPORT"
  MYSQL_OPUS4ADMIN="$MYSQL_OPUS4ADMIN -P $MYSQLPORT"
fi

$MYSQL <<LimitString
CREATE DATABASE $DBNAME DEFAULT CHARACTER SET = UTF8 DEFAULT COLLATE = UTF8_GENERAL_CI;
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$ADMIN'@'localhost' IDENTIFIED BY '$ADMIN_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE ON $DBNAME.* TO '$WEBAPP_USER'@'localhost' IDENTIFIED BY '$WEBAPP_USER_PASSWORD';
FLUSH PRIVILEGES;
LimitString

# create config.ini and set database related parameters
cd opus4/application/configs
sed -e "s!<db.params.host>!'$MYSQLHOST'!" -e "s!<db.params.port>!'$MYSQLPORT'!" -e "s!<db.params.username>!'$WEBAPP_USER'!" -e "s!<db.params.password>!'$WEBAPP_USER_PASSWORD'!" -e "s!<db.params.dbname>!'$DBNAME'!" config.ini.template > config.ini
cd -

# create createdb.sh and set database related parameters
cd opus4/db
sed -e "s!<user>!'$ADMIN'!" -e "s!<password>!'$ADMIN_PASSWORD'!" -e "s!<host>!'$MYSQLHOST'!" -e "s!<port>!'$MYSQLPORT'!" -e "s!<dbname>!'$DBNAME'!" createdb.sh.template > createdb.sh
chmod +x createdb.sh
cd -

read -p "Import test data? [Y]: " IMPORT_TESTDATA
if [ -z $IMPORT_TESTDATA ] || [ $IMPORT_TESTDATA = 'Y' ]; then
  # import test data
  cd testdata/sql
  for i in `find . -name *.sql \( -type f -o -type l \) | sort`; do
    echo "Inserting file '${i}'"
    $MYSQL_CLIENT --$MYSQL $DBNAME < "${i}"
  done
  cd -

  # copy test fulltexts to workspace directory
  cp -rv testdata/fulltexts/* workspace/files
fi

read -p "KeepDelete downloads? [N]: " DELETE_DOWNLOADS
if [ ! -z $DELETE_DOWNLOADS ] && [ $DELETE_DOWNLOADS != 'N' ]; then
  rm -rf downloads
fi
  
