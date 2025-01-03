#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export SCRIPT_ROOT_DIR

STACK="${STACK:-:}${this_file}"':'
export STACK

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/parse_installer_json.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

verbose=0
all_deps=0
help=0
output_file='-'

while getopts ':a:f:h:o:v' opt; do
    case $opt in
      (v)   # shellcheck disable=SC2003
            verbose=$(expr "${verbose}" + 1) ;;
      (f)   filename=$OPTARG ;;
      (a)   all_deps=$OPTARG ;;
      (o)   output_file=$OPTARG ;;
      (h)   help=$OPTARG ;;
      (*) ;;
    esac
done
export verbose

shift "$((OPTIND - 1))"
remaining="$*"

if [ "${help}" -ge 1 ]; then
  # shellcheck disable=SC2016
  >&2 printf 'Create install.sh from JSON.\n
\t-f filename
\t-o output file (use `-` or omit for stdout)
\t-a whether to install all dependencies (required AND optional)
\t-v verbosity (can be specified multiple times)
\t-h show help text\n\n'
  exit 2
elif [ -z "${filename+x}" ]; then
  # shellcheck disable=SC2016
  >&2 printf 'JSON file must be specified with `-f`\n'
  exit 2
elif [ ! -f "${filename}" ]; then
  # shellcheck disable=SC2016
  >&2 printf 'JSON file specified with `-f` must exist\n'
  exit 2
fi

if [ -n "${remaining}" ]; then
  >&2 printf '[W] Extra arguments provided: %s\n' "${remaining}"
fi

export output_file
export all_deps

parse_json "${filename}"