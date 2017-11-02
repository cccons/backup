#!/usr/bin/env bash

INCLUDE_FROM_FILE=$HOME/includes.txt
EXCLUDE_FROM_FILE=$HOME/excludes.txt
EXCLUDED_PATTERNS=node_modules
BACKUP_DIRECTORY=/run/media/cameron/5ad43362-df05-4fc4-bb7c-9623bf3bd09a/`hostname`/

echo "Starting backup..."
if [ -f $INCLUDE_FROM_FILE -a -d $BACKUP_DIRECTORY ]; then
    echo "  backing up files in      : ${INCLUDE_FROM_FILE}"
    if [ -f $EXCLUDE_FROM_FILE ]; then
        echo "  excluding patterns from   : ${EXCLUDE_FROM_FILE}"
    else
        echo "  excluding these patterns : ${EXCLDED_PATTERNS}"
    fi
    echo
    echo "  backing files up from : ${HOME}"
    echo "  backing files up to   : ${BACKUP_DIRECTORY}"
    echo
    read -p "continue? (y/n) " continue
    if [ "$continue" == "y" ]; then
        if [ -f $EXCLUDE_FROM_FILE ]; then
            rsync --files-from=$INCLUDE_FROM_FILE --exclude-from=$EXCLUDE_FROM_FILE --delete -avzzr $HOME $BACKUP_DIRECTORY
        else
            rsync --files-from=$INCLUDE_FROM_FILE --exclude=$EXCLUDED_PATTERNS --delete -avzzr $HOME $BACKUP_DIRECTORY
        fi
        return_code=$?
        echo "done"
    else
        echo "aborting!"
        return_code=1
    fi
    exit ${return_code}
else
    echo "error: '${BACKUP_DIRECTORY}' is not available"
    exit -1
fi
