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

BASEDIR=/var/local/opus4

ZEND_LIB_URL='http://framework.zend.com/releases/ZendFramework-1.10.6/ZendFramework-1.10.6-minimal.tar.gz'
JPGRAPH_LIB_URL='http://jpgraph.net/download/download.php?p=1'
SOLR_SERVER_URL='http://www.apache.org/dist//lucene/solr/1.4.1/apache-solr-1.4.1.tgz'
SOLR_PHP_CLIENT_LIB_URL='http://solr-php-client.googlecode.com/svn/trunk/'
SOLR_PHP_CLIENT_LIB_REVISION=36
JQUERY_LIB_URL='http://code.jquery.com/jquery-1.4.3.min.js'

MYSQL_CLIENT=/usr/bin/mysql

cd $BASEDIR

if [ ! -d downloads ]
then
  mkdir -p downloads
  cd downloads
  wget -O zend.tar.gz "$ZEND_LIB_URL"
  if [ ! -f zend.tar.gz ]
  then
    echo "Unable to download $ZEND_LIB_URL"
    exit 1
  fi

  wget -O jpgraph.tar.gz "$JPGRAPH_LIB_URL"
  if [ ! -f jpgraph.tar.gz ]
  then
    echo "Unable to download $JPGRAPH_LIB_URL"
    exit 1
  fi

  wget -O solr.tgz "$SOLR_SERVER_URL"
  if [ ! -f solr.tgz ]
  then
    echo "Unable to download $SOLR_SERVER_URL"
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

# download jQuery JavaScript library
cd opus4/public/js
wget -O jquery.js "$JQUERY_LIB_URL"
cd $BASEDIR

# promt for username
echo "OPUS requires a dedicated system account under which Solr will be running."
echo "In order to create this account, you will be prompted for some information." 
read -p "System Account Name [opus4]: " OPUS_USER_NAME
if [ -z "$OPUS_USER_NAME" ]; then
  OPUS_USER_NAME=opus4
fi
useradd -c 'OPUS 4 Solr manager' --system $OPUS_USER_NAME

# add JETTY_USER information to Jetty configuration
cd install
mv opus4-solr-jetty.conf opus4-solr-jetty.conf.tmp
sed -e "s!^JETTY_USER=!JETTY_USER=$OPUS_USER_NAME!" opus4-solr-jetty.conf.tmp > opus4-solr-jetty.conf
rm opus4-solr-jetty.conf.tmp
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
echo ""


# set defaults if value is not given
if [ -z "$DBNAME" ]; then
   DBNAME=opus400
fi
if [ -z "$ADMIN" ]; then
   ADMIN=opus4admin
fi
if [ -z "$WEBAPP_USER" ]; then
   WEBAPP_USER=opus4
fi
if [ -z "$MYSQLROOT" ]; then
   MYSQLROOT=root
fi

# process creating mysql user and database
MYSQL="$MYSQL_CLIENT --default-character-set=utf8 -u $MYSQLROOT -p -v"
MYSQL_OPUS4ADMIN="$MYSQL_CLIENT --default-character-set=utf8 -u $ADMIN -p$ADMIN_PASSWORD -v"
if [ -n "$MYSQLHOST" ]
then
  MYSQL="$MYSQL -h $MYSQLHOST"
  MYSQL_OPUS4ADMIN="$MYSQL_OPUS4ADMIN -h $MYSQLHOST"
fi
if [ -n "$MYSQLPORT" ]
then
  MYSQL="$MYSQL -P $MYSQLPORT"
  MYSQL_OPUS4ADMIN="$MYSQL_OPUS4ADMIN -P $MYSQLPORT"
fi

echo "Next you'll be now prompted to enter the root password of your MySQL server"
$MYSQL <<LimitString
CREATE DATABASE $DBNAME DEFAULT CHARACTER SET = UTF8 DEFAULT COLLATE = UTF8_GENERAL_CI;
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$ADMIN'@'localhost' IDENTIFIED BY '$ADMIN_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE ON $DBNAME.* TO '$WEBAPP_USER'@'localhost' IDENTIFIED BY '$WEBAPP_USER_PASSWORD';
FLUSH PRIVILEGES;
LimitString

# create config.ini and set database related parameters
cd $BASEDIR/opus4/application/configs
sed -e "s!^db.params.host =!db.params.host ='$MYSQLHOST'!" \
    -e "s!^db.params.port =!db.params.port = '$MYSQLPORT'!" \
    -e "s!^db.params.username =!db.params.username = '$WEBAPP_USER'!" \
    -e "s!^db.params.password =!db.params.password = '$WEBAPP_USER_PASSWORD'!" \
    -e "s!^db.params.dbname =!db.params.dbname = '$DBNAME'!" config.ini.template > config.ini

# create createdb.sh and set database related parameters
cd $BASEDIR/opus4/db
sed -e "s!^user=!user='$ADMIN'!" \
    -e "s!^password=!password='$ADMIN_PASSWORD'!" \
    -e "s!^host=!host='$MYSQLHOST'!" \
    -e "s!^port=!port='$MYSQLPORT'!" \
    -e "s!^dbname=!dbname='$DBNAME'!" createdb.sh.template > createdb.sh
chmod +x createdb.sh
./createdb.sh

# install and configure Solr search server
cd $BASEDIR
read -p "Install and configure Solr server? [Y]: " INSTALL_SOLR
if [ -z "$INSTALL_SOLR" ] || [ "$INSTALL_SOLR" = "Y" ] || [ "$INSTALL_SOLR" = "y" ]
then
  tar xfvz downloads/solr.tgz
  ln -sf apache-solr-1.4.1 solr 
  cd solr
  cp -r example opus4
  cd opus4
  rm -rf example-DIH exampledocs multicore/exampledocs
  cd solr/conf
  ln -sf $BASEDIR/solrconfig/schema.xml
  ln -sf $BASEDIR/solrconfig/solrconfig.xml
  cd ../../
  ln -sf $BASEDIR/solrconfig/logging.properties

  read -p "Solr server port number [8983]: " SOLR_SERVER_PORT
  if [ -z "$SOLR_SERVER_PORT" ]; then
    SOLR_SERVER_PORT=8983;
  fi
  cd $BASEDIR/opus4/application/configs
  cp config.ini config.ini.tmp
  sed -e "s!^searchengine.index.host =!searchengine.index.host = 'localhost'!" \
      -e "s!^searchengine.index.port =!searchengine.index.port = '$SOLR_SERVER_PORT'!" \
      -e "s!^searchengine.index.app =!searchengine.index.app = 'solr'!" \
      -e "s!^searchengine.extract.host =!searchengine.extract.host = 'localhost'!" \
      -e "s!^searchengine.extract.port =!searchengine.extract.port = '$SOLR_SERVER_PORT'!" \
      -e "s!^searchengine.extract.app =!searchengine.extract.app = 'solr'!" config.ini.tmp > config.ini 
  rm config.ini.tmp

  cd $BASEDIR/install
  read -p "Install init.d script to start and stop Solr server automatically? [Y]: " INSTALL_INIT_SCRIPT
  if [ -z "$INSTALL_INIT_SCRIPT" ] || [ "$INSTALL_INIT_SCRIPT" = "Y" ] || [ "$INSTALL_INIT_SCRIPT" = "y" ]
  then
    ln -sf $BASEDIR/install/opus4-solr-jetty /etc/init.d/opus4-solr-jetty
    ln -sf $BASEDIR/install/opus4-solr-jetty.conf /etc/default/jetty
    chmod +x /etc/init.d/opus4-solr-jetty
    update-rc.d -f opus4-solr-jetty remove
    update-rc.d opus4-solr-jetty defaults
  fi

  #start Solr server
  mv opus4-solr-jetty.conf opus4-solr-jetty.conf.tmp
  sed -e "s!^JETTY_PORT=!JETTY_PORT=$SOLR_SERVER_PORT!" opus4-solr-jetty.conf.tmp > opus4-solr-jetty.conf
  rm opus4-solr-jetty.conf.tmp
  chmod +x opus4-solr-jetty
  ./opus4-solr-jetty start
fi

# import some test documents
read -p "Import test data? [Y]: " IMPORT_TESTDATA
if [ -z "$IMPORT_TESTDATA" ] || [ "$IMPORT_TESTDATA" = "Y" ] || [ "$IMPORT_TESTDATA" = "y" ]
then
  # import test data
  cd $BASEDIR
  for i in `find testdata/sql -name *.sql \( -type f -o -type l \) | sort`; do
    echo "Inserting file '${i}'"
    $MYSQL_OPUS4ADMIN $DBNAME < "${i}"
  done

  # copy test fulltexts to workspace directory
  cp -rv testdata/fulltexts/* workspace/files

  # sleep some seconds to ensure the server is running
  echo -e "\n\nsleep some seconds until the Solr server is running"
  i=0;
  while [ $i -lt 20 ]
  do
    sleep 1
    echo -n "."
    i=$[$i+1]
  done
  echo ""

  # start indexing of testdata
  php5 $BASEDIR/opus4/scripts/SolrIndexBuilder.php
fi

# change file owner to $OPUS_USER_NAME
chown -R $OPUS_USER_NAME:$OPUS_USER_NAME $BASEDIR

# delete tar archives
cd $BASEDIR
read -p "Delete downloads? [N]: " DELETE_DOWNLOADS
if [ "$DELETE_DOWNLOADS" = "Y" ] || [ "$DELETE_DOWNLOADS" = "y" ]; then
  rm -rf downloads
fi
  
echo
echo "OPUS 4 is running now! Point your browser to http://localhost/opus4/"
