#!/bin/bash

###################################################################
# Copyright (c) Members of the EGEE Collaboration. 2004. See
# http://www.eu-egee.org/partners/ for details on the copyright holders.
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#
# Instantiates the configuration templates of this package.
#
# Author: Akos.Frohner@cern.ch
# Author: Joni.Hahkala@cern.ch
#
###################################################################

PACKAGENAME=trustmanager-tomcat
USAGE="$0 [--dryrun] [--silent] [--force] [--bouncycastledir dir] [--log4jdir dir] [install_root [config_values_filename [config_directory]]]"

SILENT_ECHO=echo
BC_DIR_PRE_41="/usr/share/java-ext/bouncycastle-jdk1.5/"
BC_DIR_41="/usr/share/java/"
BC_DIR=""
LOG4J_DIR="/usr/share/java/"
FORCE='false'
TOMCAT_VERSION=5

TEMP=$(getopt -o d -l dryrun -l silent -l force -l bouncycastledir: -l log4jdir: -- "$@")

eval set -- "$TEMP"

while true; do
    case "$1" in
        -d|--dryrun)
            DRYRUN='echo Info:'
            shift
            ;;
        --silent)
            SILENT_ECHO='set IGNORE_STRING='
            shift
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        --bouncycastledir)
	    BC_DIR=$2
            shift
	    shift
            ;;
        --log4jdir)
            LOG4J_DIR=$2
            shift
	    shift
            ;;
        --)
            # end of options
            shift
            break
            ;;
    esac
done

#################################################################
# link a file from dir to dest if it doesn't exist
# or when forced

function condLinkFile {
    file=$1
    searchDir=$2
    destDir=$3
    force=$4
    if [ $force == "true" ] || [ ! -e "$destDir/$file" ]; then
	$DRYRUN ln -sf $searchDir/$file $destDir 
    else
	$SILENT_ECHO "File $destDir/$file exists, skippind the linking. Use --force to FORCE linking"
    fi
}

#################################################################
# link a file from dir (falling back to other dir) to dest if it 
# doesn't exist or when forced

function condLinkFileBack {
    file=$1
    searchDir=$2
    backupDir=$3
    destDir=$4
    force=$5
    if [ -e "$searchDir/$file" ]; then
	condLinkFile $file $searchDir $destDir $force
    else
	$SILENT_ECHO "File $searchDir/$file not installed falling back to checking $backupDir/$file."
	condLinkFile $file $backupDir $destDir $force
    fi
}

#################################################################
# installation root directory
if [ "$1" == "" ]; then
    INSTALLROOT='/'
    $SILENT_ECHO "Info: using default install root: $INSTALLROOT"
else
    INSTALLROOT=$1
    shift
fi
if [ ! -d "$INSTALLROOT" ]; then
    echo "Error: Please specify the installation root directory!"
    echo " (e.g. /)"
    echo $USAGE
    exit 1
fi

#################################################################
# configuration file
if [ "$1" == "" ]; then
    VALUESFILE="$INSTALLROOT/var/lib/$PACKAGENAME/config.properties"
    $SILENT_ECHO "Info: using default configuration file: $VALUESFILE"
else
    VALUESFILE=$1
    shift
fi
if [ ! -f "$VALUESFILE" ]; then
    echo "Error: Please specify the configuration values file!"
    echo " (e.g. /var/lib/$PACKAGENAME/config.properties)"
    echo $VALUESFILE
    echo $USAGE
    exit 1
fi

#################################################################
# configuration directory
if [ "$1" == "" ]; then
    CONFIGDIR="$INSTALLROOT/var/lib/$PACKAGENAME"
    $SILENT_ECHO "Info: using default configuration directory: $CONFIGDIR"
else
    CONFIGDIR=$1
    shift
fi
if [ ! -d "$CONFIGDIR" ]; then
    echo "Error: Please specify the configuration directory!"
    echo " (e.g. /var/lib/$PACKAGENAME)"
    echo $USAGE
    exit 1
fi

#################################################################
# Tomcat directory
if [ -r "/etc/tomcat5/tomcat5.conf" ]; then
    source "/etc/tomcat5/tomcat5.conf"
    TCCONFIG_DIR="/etc/tomcat5"
    SERVER_LIB=${CATALINA_HOME}/server/lib

else
if [ -r "/etc/tomcat6/tomcat6.conf" ]; then
    source "/etc/tomcat6/tomcat6.conf"
    TCCONFIG_DIR="/etc/tomcat6"
    SERVER_LIB=${CATALINA_HOME}/lib
    TOMCAT_VERSION=6
    else
        if [ -z "$CATALINA_HOME" ]; then
	    echo "Please set the CATALINA_HOME environmental variable!"
	    exit 2
	fi
	$SILENT_ECHO "Warning: /etc/tomcat5/tomcat5.conf nor /etc/tomcat6/tomcat6.conf does not exists -- non default install."
	TCCONFIG_DIR="${CATALINA_HOME}/conf"
	if [ -d ${CATALINA_HOME}/server ]; then
	    # this it tomcat5
	    SERVER_LIB=${CATALINA_HOME}/server/lib
	else
	    # this it tomcat6
	    SERVER_LIB=${CATALINA_HOME}/lib
	    TOMCAT_VERSION=6
	fi
    fi
fi

SERVERXML="${TCCONFIG_DIR}/server.xml"

if [ ! -f "$SERVERXML" ]; then
    echo "Tomcat server configuraton file does not exists: $SERVERXML"
    exit 2
fi


#################################################################
# parsing the properties file and building a sed script:
#
#  - strip the package name prefix and the dot
#  - escape slashes
#  - turn the equal sign, surrounded with whitespaces, into slash
#  - prefix the line with "s/"
#  - suffix the line with "/g;"
#
sedscript=$(grep "^$PACKAGENAME" $VALUESFILE | sed -e "s/^$PACKAGENAME\.//" | sed -e 's/\//\\\//g; s/[ \t]*=[ \t]*/@\//; s/^/s\/@/; s/$/\/g;/;')
#
# add custom patterns: @INSTALLROOT@ -> $INSTALLROOT
#
sedscript=${sedscript}" "$(echo "INSTALLROOT=$INSTALLROOT" | sed -e 's/\//\\\//g; s/[ \t]*=[ \t]*/@\//; s/^/s\/@/; s/$/\/g;/;')
sedscript=${sedscript}" "$(echo "HOSTNAME="$(hostname -f) | sed -e 's/\//\\\//g; s/[ \t]*=[ \t]*/@\//; s/^/s\/@/; s/$/\/g;/;')
sedscript=${sedscript}" "$(echo "CATALINA_HOME=$CATALINA_HOME" | sed -e 's/\//\\\//g; s/[ \t]*=[ \t]*/@\//; s/^/s\/@/; s/$/\/g;/;')

#################################################################
# template instantiation
TEMPLATEDIR="$INSTALLROOT/var/lib/$PACKAGENAME"
if [ ! -d "$TEMPLATEDIR" ]; then
    echo "Error: template directory does not exist: $TEMPLATEDIR"
    echo $USAGE
    exit 3
fi

for template in $(ls $TEMPLATEDIR/*.template); do
    if [ ! -f "$template" ]; then
        echo "Error: $template file does not exist!"
        exit 3
    fi
    filename=$CONFIGDIR/$(basename $template .template)

    if [ -f "$filename" ]; then
        $SILENT_ECHO "Warning: $filename already exists! Saving old one as $filename.old."
        $DRYRUN mv $filename $filename.old
    fi
    
    # let be paranoid with passwords
    $DRYRUN touch $filename
    $DRYRUN chmod 0600 $filename
    # replace the autogenerated patterns
    cat $template | sed -e "$sedscript" | sed '/.*@.*@.*/d' >$filename
done


#################################################################
# configuration
OLDSERVERXML=$SERVERXML.old-trustmanager
ORIGSERVERXML=$SERVERXML.orig-trustmanager
if [ ! -e $ORIGSERVERXML ]; then
    if [ -e $OLDSERVERXML ]; then
	$DRYRUN cp $OLDSERVERXML $ORIGSERVERXML
    else
	$DRYRUN cp $SERVERXML $ORIGSERVERXML
    fi
fi

#if [ -e $OLDSERVERXML ]; then
#    echo "Error: $OLDSERVERXML already exists, so the server is configured"
#    exit 4
#fi

$DRYRUN cp -p $SERVERXML $OLDSERVERXML
$DRYRUN cp $CONFIGDIR/server.xml $SERVERXML
if [ ! -z "$TOMCAT_USER" ]; then
    $DRYRUN chown $TOMCAT_USER $SERVERXML
fi



# remove existing bcprov jar links or files to make sure there is no leftovers
rm -f ${SERVER_LIB}/bcprov*.jar

#user override
if [ ${BC_DIR}x != "x" ]; then
    # prefer version independent bcprov.jar
    if [ -e ${BC_DIR}/bcprov.jar ]; then
	$DRYRUN ln -sf ${BC_DIR}/bcprov.jar ${SERVER_LIB}
    else
	$DRYRUN ln -sf ${BC_DIR}/bcprov-*.jar ${SERVER_LIB}/bcprov.jar
    fi
else
    #prefer bouncycastle 1.41 and after location
    if [ -e ${BC_DIR_41}/bcprov.jar ]; then
	$DRYRUN ln -sf ${BC_DIR_41}/bcprov.jar ${SERVER_LIB}
    else
	# fall back to pre bouncycastle 1.41 jpackage location
	if [ -e ${BC_DIR_PRE_41}/bcprov.jar ]; then
	    $DRYRUN ln -sf ${BC_DIR_PRE_41}/bcprov.jar ${SERVER_LIB}
	    # prepare for the 1.41 bouncycastle structure
	    $DRYRUN ln -sf ${BC_DIR_41}/bcprov-1.41.jar ${SERVER_LIB}
	else
	    # fall back to the trustmanager packaged bouncycastle
	    # no automatic update when new trustmanager rpm with new
            # bcprov is installed and the one linked will be removed
            # so problem here, have to reconfigure in that case
	    $DRYRUN ln -sf ${TEMPLATEDIR}/bcprov-*.jar ${SERVER_LIB}/bcprov.jar
	fi
    fi
fi


#condLinkFileBack bcprov.jar $BC_DIR $TEMPLATEDIR $CATALINA_HOME/server/lib/ $FORCE
condLinkFileBack log4j.jar $LOG4J_DIR $TEMPLATEDIR ${SERVER_LIB} $FORCE


JARS2="trustmanager.jar trustmanager-tomcat.jar"
for jar in $JARS2; do
    condLinkFile $jar $INSTALLROOT/share/java ${SERVER_LIB} $FORCE
done

log4j="log4j-trustmanager.properties"
if [ ! -e "${TCCONFIG_DIR}/$log4j" ]; then
    $DRYRUN cp $CONFIGDIR/$log4j ${TCCONFIG_DIR}/$log4j
fi

if [ $TOMCAT_VERSION == "6" ]; then
    condLinkFile commons-logging.jar /usr/share/java ${SERVER_LIB} $FORCE
fi

$SILENT_ECHO "Info: you can clean up using the following commands"
$SILENT_ECHO "      mv -f $OLDSERVERXML $SERVERXML"
$SILENT_ECHO "      rm -f ${SERVER_LIB}/bcprov*.jar"
$SILENT_ECHO "      rm -f ${SERVER_LIB}/log4j*.jar"
$SILENT_ECHO "      rm -f ${SERVER_LIB}/trustmanager-*.jar"
$SILENT_ECHO "      rm -f $TCCONFIG_DIR/$log4j"
$SILENT_ECHO "      rm -f ${CONFIGDIR}/server.xml"
if [ $TOMCAT_VERSION == "6" ]; then
    $SILENT_ECHO "      rm -f ${SERVER_LIB}/commons-logging*.jar"
fi

