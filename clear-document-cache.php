#!/usr/bin/env php5
<?php
/**
 * This file is part of OPUS. The software OPUS has been originally developed
 * at the University of Stuttgart with funding from the German Research Net,
 * the Federal Department of Higher Education and Research and the Ministry
 * of Science, Research and the Arts of the State of Baden-Wuerttemberg.
 *
 * OPUS 4 is a complete rewrite of the original OPUS software and was developed
 * by the Stuttgart University Library, the Library Service Center
 * Baden-Wuerttemberg, the Cooperative Library Network Berlin-Brandenburg,
 * the Saarland University and State Library, the Saxon State Library -
 * Dresden State and University Library, the Bielefeld University Library and
 * the University Library of Hamburg University of Technology with funding from
 * the German Research Foundation and the European Regional Development Fund.
 *
 * LICENCE
 * OPUS is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the Licence, or any later version.
 * OPUS is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details. You should have received a copy of the GNU General Public License
 * along with OPUS; if not, write to the Free Software Foundation, Inc., 51
 * Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * @author      Jens Schwidder <schwidder@zib.de>
 * @copyright   Copyright (c) 2008-2014, OPUS 4 development team
 * @license     http://www.gnu.org/licenses/gpl.html General Public License
 * @version     $Id$
 */

/**
 * Dieses Skript soll den Dokument XML Cache in der Datenbank löschen, damit Änderungen durch das Update berücksichtigt
 * werden.
 */

$options = getopt('', array(
    "dbname:",
    "user:",
    "password:",
    "host::",
    "port::"
        ));

if (!isset($options['dbname']) || !isset($options['user']) || !isset($options['password'])) {
    echo "ERROR: argument is missing for update script\n";
    exit;
}

$dsnParts[] = "mysql:dbname={$options['dbname']}";
if (isset($options['host']))
    $dsnParts[] = "host={$options['host']}";
if (isset($options['port']))
    $dsnParts[] = "port={$options['port']}";

$dsn = implode(';', $dsnParts);

try {
    $pdo = new PDO($dsn, $options['user'], $options['password'],
        array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8'"));

    $result = $pdo->exec('truncate table document_xml_cache');

    if ($result === false) {
        $errorString = 'Unknown Error';
        $errorInfo = $pdo->errorInfo();
        if (isset($errorInfo[2]) && !empty($errorInfo[2])) {
            $errorString = $errorInfo[2];
        }
        throw new Exception('Clearing document cache failed: ' . $errorString);
    }

    echo "Clearing document cache " . ($result != 1 ? "FAILED." : "success.") . PHP_EOL;
}
catch (Exception $e) {
    echo "$e";
}