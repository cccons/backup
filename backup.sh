#!/usr/bin/env bash

script_name=$(basename "$0")
version="1.0.0"

backup_files_and_dirs=()
backup_to_dir=${backup_to_dir:-}
include_from_file=${include_from_file:-$HOME/includes.txt}
exclude_from_file=${exclude_from_file:-$HOME/excludes.txt}

backup() {
    echo "Starting backup..."
    if [ -f $include_from_file -a -d $backup_to_dir ]; then
        echo "  backing up files in      : ${include_from_file}"
        if [ -f $exclude_from_file ]; then
            echo "  excluding patterns from   : ${exclude_from_file}"
        else
            echo "  excluding these patterns : ${excluded_patterns}"
        fi
        echo
        echo "  backing files up from : ${HOME}"
        echo "  backing files up to   : ${backup_directory}"
        echo
        read -p "continue? (y/n) " continue
        if [ "$continue" == "y" ]; then
            if [ -f $exclude_from_file ]; then
                rsync --files-from=$include_from_file --exclude-from=$exclude_from_file --delete -avzzr $HOME $backup_to_dir
            else
                rsync --files-from=$include_from_file --exclude=$excluded_patterns --delete -avzzr $HOME $backup_to_dir
            fi
            return_code=$?
            echo "done"
        else
            echo "aborting!"
            return_code=1
        fi
        exit $return_code
    else
        echo "error: '$backup_to_dir' is not available"
        exit -1
    fi
}

process_cmd_args() {
    while [ ! -z "${1:+defined}" ]; do
        case "$1" in
            -b|--backup-dir)
                backup_dir_set=yes
                [ ! -z "${2:+defined}" ] && backup_to_dir="$2" || cli_error "backup directory is required"
                [ ! -d "$backup_to_dir" ] && cli_error "'$backup_to_dir' does not exist"
                shift
                ;;
            -i|--include-from)
                [ ! -z "${2:+defined}" ] && include_from_file="$2" || cli_error "include-from file is required"
                [ ! -f "$include_from_file" ] && cli_error "'$include_from_file' does not exist"
                shift
                ;;
            -e|--exclude-from)
                [ ! -z "${2:+defined}" ] && exclude_from_file="$2" || cli_error "exclude-from file is required"
                [ ! -f "$exclude_from_file" ] && cli_error "'$exclude_from_file' does not exist"
                shift
                ;;
            --print)
                print_values=yes
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                version
                exit 0
                ;;
            *)
                [ -d "$1" -o -f "$1" ] && \
                    backup_files_and_dirs+=("$1") || \
                        cli_error "unrecognized argument: $1"
                ;;
        esac
        shift
    done

    [ ! -z "$print_values" ] && print_backup_param_values && exit 0
    [ -z "$backup_dir_set" ] && cli_error "-b or --backup-dir flag is required"
}

cli_error() {
    echo "error: ${1:-an unrecognized error occurred}"
    usage
    exit 1
}

usage() {
    version
    cat <<EOF
usage: $script_name -h | --help
       $script_name -v | --version
       $script_name [options...] <directory... | file...>

note: required parameters to long options are required for short options, too

options:
  -b,--backup-dir DIR       The directory in which to backup the files (required)
  -i,--include-from FILE    The file containing patterns to include in the backup
                               (default: $include_from_file)
  -e,--exclude-from FILE    The file containing patterns to exclude from the backup
                               (default: $exclude_from_file)
     --print                Print backup parameter values without performing a backup

  -h,--help                 Display this help message and exit
  -v,--version              Display version information and exit
EOF
}

version() {
    echo "$script_name v $version"
}

print_backup_param_values() {
    echo    "Printing values of backup parameters:"
    echo -e "  backup directory  : ${backup_to_dir}"
    echo -e "  include-from file : ${include_from_file}"
    echo -e "  exclude-from file : ${exclude_from_file}"
    echo
    read -p "Display files / directories to be backed up? (y/n) " display
    [ "$display" = "y" -o "$display" = "Y" ] && \
        for file_or_dir in "${backup_files_and_dirs[@]}"; do
            echo "  $file_or_dir"
        done
}

process_cmd_args "$@"
