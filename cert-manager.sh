#!/usr/bin/env bash

# Some "constants"
AVAILABLE_ACTIONS=('generate','renew')
DEFAULT_PORT=8000

# Determine absolute path that the script will execute from.
DIRNAME=$(dirname ${0})
if [[ $DIRNAME = '.' ]]; then
  DIRNAME=$PWD
fi

# Unset the variables used for the Docker run command.
ACTION=""
ENV_FILE=""
PORT=""

# Function to print usage.
function print_usage() {
  cat <<EOF

Usage
=====

./$(basename $0) -a <ACTION> -f <FILE> [-p <PORT>]

-a | --action <ACTION>    The action to perform. Valid values are "generate" or
                          "renew".
-f | --env-file <FILE>    The filename containing required environment
                          variables.
-p | --port <PORT>        This is an optional value to set the port that the
                          container will be exposed to. The default value is
                          8000.

EOF
}

# Function for error handling.
function handle_error() {
  case ${1:-USAGE} in
    USAGE)
      print_usage
      ;;
    FILE_NOT_FOUND)
      echo "File not found."
      ;;
    INVALID_PORT)
      echo "Invalid port number"
      ;;
  esac
  exit 1
}

while [[ $# -gt 0 ]]; do
  key="${1}"
  case ${key} in
    -a|--action)
      if [[ -z ${ACTION} ]]; then
        _value=$(echo ${2} | tr '[:upper:]' '[:lower:]')
        if [[ ${AVAILABLE_ACTIONS[*]} =~ "${_value}" ]]; then
          ACTION=$_value
        else
          handle_error
        fi
      fi
      shift
      ;;
    -f|--env-file)
      if [[ -z ${ENV_FILE} ]]; then
        if [[ -f ${2} ]]; then
          ENV_FILE=${2}
        else
          handle_error FILE_NOT_FOUND
        fi
      fi
      shift
      ;;
    -p|--port)
      PORT=${2}
      if [[ ! ${PORT} =~ ^[0-9]+$ ]] || (( ${PORT} < 1 || ${PORT} > 65536 )); then
        handle_error INVALID_PORT
      fi
      shift
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

# Action and enviroment file are required.
if [[ -z ${ACTION} || -z ${ENV_FILE} ]]; then
  handle_error USAGE
fi

# Set default port value if not specified.
PORT=${PORT:-$DEFAULT_PORT}

# Run the container.
docker run --rm \
  -p $PORT:80 \
  --env-file ${DIRNAME}/${ENV_FILE} \
  -v $DIRNAME/letsencrypt:/etc/letsencrypt:z \
  -v $DIRNAME/.oci:/root/.oci \
  oci-le-cert-manager \
  cert-manager ${ACTION}
