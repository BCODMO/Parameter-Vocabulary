#!/bin/bash
SETTINGS_DIR=/settings
mkdir -p $SETTINGS_DIR

cd /data

mkdir -p dumps

if [ ! -f ./virtuoso.ini ];
then
  mv /virtuoso.ini . 2>/dev/null
fi

chmod +x /clean-logs.sh
mv /clean-logs.sh . 2>/dev/null

original_port=`crudini --get virtuoso.ini HTTPServer ServerPort`
# NOTE: prevents virtuoso to expose on port 8890 before we actually run
#		the server
crudini --set virtuoso.ini HTTPServer ServerPort 27015

if [ ! -f "$SETTINGS_DIR/.config_set" ];
then
  echo "Converting environment variables to ini file"
  printenv | grep -P "^VIRT_" | while read setting
  do
    section=`echo "$setting" | grep -o -P "^VIRT_[^_]+" | sed 's/^.\{5\}//g'`
    key=`echo "$setting" | sed -E 's/^VIRT_[^_]+_(.*)=.*$/\1/g'`
    value=`echo "$setting" | grep -o -P "=.*$" | sed 's/^=//g'`
    echo "Registering $section[$key] to be $value"
    crudini --set virtuoso.ini $section $key "$value"
  done
  echo "`date +%Y-%m%-dT%H:%M:%S%:z`" >  $SETTINGS_DIR/.config_set
  echo "Finished converting environment variables to ini file"
fi

if [ ! -f ".backup_restored" -a -d "backups" -a ! -z "$BACKUP_PREFIX" ] ;
then
    echo "Start restoring a backup with prefix $BACKUP_PREFIX"
    cd backups
    virtuoso-t +restore-backup $BACKUP_PREFIX +configfile /data/virtuoso.ini
    if [ $? -eq 0 ]; then
        cd /data
        echo "`date +%Y-%m-%dT%H:%M:%S%:z`" > .backup_restored
    else
        exit -1
    fi
fi

if [ ! -f ".dba_pwd_set" ] ;
then
  touch /sql-query.sql
  if [ "$DBA_PASSWORD" ] ;
  then
    echo "DBA Password env var"
    echo "user_set_password('dba', '$DBA_PASSWORD');" >> /sql-query.sql
  fi
  if [ "$SPARQL_UPDATE" = "true" ]; then echo "GRANT SPARQL_UPDATE to \"SPARQL\";" >> /sql-query.sql ; fi
  virtuoso-t +wait && isql-v -U dba -P dba < /dump_nquads_procedure.sql && isql-v -U dba -P dba < /sql-query.sql
  kill "$(ps aux | grep '[v]irtuoso-t' | awk '{print $2}')"
  echo "`date +%Y-%m-%dT%H:%M:%S%:z`" >  .dba_pwd_set
fi

if [ ! -f ".data_loaded" ] ;
then

    if [ ! -f ".data_downloaded" ] ;
    then
        # Downlaod NERC Parameter vocabularies
        DOWNLOAD=/data/toLoad/NERC
        mkdir -p ${DOWNLOAD}
        GRAPH_URI=http://vocab.nerc.ac.uk/collection/P01/
        echo "Downloading NERC Vocabularies..."
        curl -o ${DOWNLOAD}/P01.xml http://vocab.nerc.ac.uk/collection/P01/current/
        echo "P01 downloaded"
        curl -o ${DOWNLOAD}/P02.xml http://vocab.nerc.ac.uk/collection/P02/current/
        echo "P02 downloaded"
        curl -o ${DOWNLOAD}/S01.xml http://vocab.nerc.ac.uk/collection/S01/current/
        echo "S01 downloaded"
        curl -o ${DOWNLOAD}/S02.xml http://vocab.nerc.ac.uk/collection/S02/current/
        echo "S02 downloaded"
        curl -o ${DOWNLOAD}/S03.xml http://vocab.nerc.ac.uk/collection/S03/current/
        echo "S03 downloaded"
        curl -o ${DOWNLOAD}/S04.xml http://vocab.nerc.ac.uk/collection/S04/current/
        echo "S04 downloaded"
        curl -o ${DOWNLOAD}/S05.xml http://vocab.nerc.ac.uk/collection/S05/current/
        echo "S05 downloaded"
        curl -o ${DOWNLOAD}/S06.xml http://vocab.nerc.ac.uk/collection/S06/current/
        echo "S06 downloaded"
        curl -o ${DOWNLOAD}/S07.xml http://vocab.nerc.ac.uk/collection/S07/current/
        echo "S07 downloaded"
        curl -o ${DOWNLOAD}/S25.xml http://vocab.nerc.ac.uk/collection/S25/current/
        echo "S25 downloaded"
        curl -o ${DOWNLOAD}/S26.xml http://vocab.nerc.ac.uk/collection/S26/current/
        echo "S26 downloaded"
        curl -o ${DOWNLOAD}/S27.xml http://vocab.nerc.ac.uk/collection/S27/current/
        echo "S27 downloaded"
        curl -o ${DOWNLOAD}/S29.xml http://vocab.nerc.ac.uk/collection/S29/current/
        echo "S29 downloaded"
    fi

    echo "Building load_data.sql..."
    echo "ld_dir('toLoad/NERC', '*', '${GRAPH_URI}');" >> /load_data.sql
    echo "rdf_loader_run();" >> /load_data.sql
    echo "exec('checkpoint');" >> /load_data.sql
    echo "WAIT_FOR_CHILDREN; " >> /load_data.sql

    if [ ! -f ".data_downloaded" ] ;
    then
        # DOWNLOAD BCO-DMO Dataset and Parameters
        DOWNLOAD=/data/toLoad/BCODMO
        mkdir -p ${DOWNLOAD}
        GRAPH_URI=http://www.bco-dmo.org/
        echo "Downloading BCO-DMO dataset parameters..."
        curl -o ${DOWNLOAD}/parameters.xml https://www.bco-dmo.org/rdf/dumps/parameter.rdf
        echo "BCO-DMO Master Parameters downloaded"
        curl -o ${DOWNLOAD}/dataset-parameters.xml https://www.bco-dmo.org/rdf/dumps/dataset_parameter.rdf
        echo "BCO-DMO Dataset Parameters downloaded"
        curl -o ${DOWNLOAD}/dataset.xml https://www.bco-dmo.org/rdf/dumps/dataset.rdf
        echo "BCO-DMO Datasets downloaded"
        echo "`date +%Y-%m-%dT%H:%M:%S%:z`" > .data_downloaded
    fi

    echo "ld_dir('toLoad/BCODMO', '*', '${GRAPH_URI}');" >> /load_data.sql
    echo "rdf_loader_run();" >> /load_data.sql
    echo "exec('checkpoint');" >> /load_data.sql
    echo "WAIT_FOR_CHILDREN; " >> /load_data.sql

    echo "Start data loading from toLoad folder"
    pwd="dba"

    if [ "$DBA_PASSWORD" ]; then pwd="$DBA_PASSWORD" ; fi
    echo "$(cat /load_data.sql)"
    virtuoso-t +wait && isql-v -U dba -P "$pwd" < /load_data.sql
    kill $(ps aux | grep '[v]irtuoso-t' | awk '{print $2}')
    echo "`date +%Y-%m-%dT%H:%M:%S%:z`" > .data_loaded
fi

crudini --set virtuoso.ini HTTPServer ServerPort ${VIRT_HTTPServer_ServerPort:-$original_port}

exec virtuoso-t +wait +foreground

