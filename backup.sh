#!/usr/bin/env bash

script_name=$(basename "$0")
version="1.0.0"

backup_files_and_dirs=()
backup_to_dir=${backup_to_dir:-}
files_from_file=${files_from_file:-}
include_from_file=${include_from_file:-}
exclude_from_file=${exclude_from_file:-}

quiet=

backup() {
    if [ -z "$quiet" ]; then
        echo "running backup command:"
        echo "  rsync `build_rsync_args_list`"
        read -p "continue? (y/n) " continue
        [ ! $(expr "$continue" : "[yY]$") -ne 0 ] && echo "aborting!" && exit 0
    fi
    rsync `build_rsync_args_list`
}

build_rsync_args_list() {
    rsync_args=()
    [ ! -z "$files_from_file" ] && rsync_args+=(--files-from="$files_from_file")
    [ ! -z "$include_from_file" ] && rsync_args+=(--include-from="$include_from_file")
    [ ! -z "$exclude_from_file" ] && rsync_args+=(--exclude-from="$exclude_from_file")
    [ ! -z "$quiet" ] && rsync_args+=(--quiet)
    rsync_args+=(--delete -avzzr "${backup_files_and_dirs[@]}" "$backup_to_dir")
    echo "${rsync_args[@]}"
}

print_backup_param_values() {
    echo    "Printing values of backup parameters:"
    echo -e "  backup directory  : ${backup_to_dir}"
    echo -e "  files-from file   : ${files_from_file}"
    echo -e "  include-from file : ${include_from_file}"
    echo -e "  exclude-from file : ${exclude_from_file}"
    echo
    read -p "Display files / directories to be backed up? (y/n) " display
    [ $(expr "$display" : "[yY]$") -ne 0 ] && \
        for file_or_dir in "${backup_files_and_dirs[@]}"; do
            echo "  $file_or_dir"
        done
    return 0
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
            -f|--files-from)
                [ ! -z "${2:+defined}" ] && files_from_file="$2" || cli_error "files-from file is required"
                [ ! -f "$files_from_file" ] && cli_error "'$files_from_file' does not exist"
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
            -q|--quiet)
                print_values=
                quiet=yes
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
    [ "${#backup_files_and_dirs[@]}" -eq 0 ] && cli_error "no file(s) / directory(ies) to backup"
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
  -f,--files-from FILE      The file containing files to include in the backup
  -i,--include-from FILE    The file containing patterns to include in the backup
  -e,--exclude-from FILE    The file containing patterns to exclude from the backup
  -q,--quiet                Only display output if there are errors
     --print                Print backup parameter values without performing a backup

  -h,--help                 Display this help message and exit
  -v,--version              Display version information and exit
EOF
}

version() {
    echo "$script_name v $version"
}

process_cmd_args "$@"
backup
