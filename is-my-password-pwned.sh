#!/usr/bin/env bash
set -euo pipefail

readonly script_name="${BASH_SOURCE[0]##*/}"

function usage()
{
    cat << EOF
Usage: ${script_name} [OPTIONS] [PASSWORD]

Check, if a password is pwned or compromized, with then help of
https://haveibeenpwned.com api.

With no PASSWORD, or when the PASSWORD is -, read from the standard input.
Caveat, when providing PASSWORD as an argument, it leaves the PASSWORD in the
shell's history buffer.

  -h  display this help and exit
  -p  input plain text password, default
  -q  quiet mode
  -s  input password's sha1sum
  -v  output version information and exit
EOF
}

function version()
{
    cat << EOF
${script_name} 1.0

Copyright (0) 2018 public domain.

License CC0 or public domain: Creative Commons Zero version 1.0 or later
<https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt>.
EOF
}

function log()
{
    local message=
    message="$*"

    if [[ "${quiet}" != "true" ]]; then
        echo "${message}"
    fi
}

function read_input()
{
    local argument=
    argument="$*"
    local input=

    if [[ -n "${argument}" ]] && [[ "${argument}" != "-" ]]; then
        log >&2 "Please note that the ${input_type} remains visible in the shell's" \
            "history. Consider clearing it from there."
        input="${argument}"
    else
        log >&2 "Please enter the ${input_type}:"
        read -a input -r -s -t 10
    fi

    if [[ -z "${input:-}" ]]; then
        log >&2 "No input."
        exit 1
    fi

    echo "${input}"
}

function validate_input()
{
    local input_type=
    input_type=$1

    if [[ "${input_type}" == "password" ]]; then
        return
    fi

    local input=
    input=$2

    readonly sha1_length=40

    if [[ "${#input}" != "${sha1_length}" ]]; then
        log >&2 "The input length ${#input} for ${input_type} does not match" \
            "the expected length "${sha1_length}"."
        exit 1
    fi 

    local input_pattern="^[a-fA-F0-9]+$"
    
    if ! [[ "${input}" =~ ${input_pattern} ]]; then
        log >&2 "The input contains illegal characters to be ${input_type}."
        exit 1
    fi
}

function get_sha1()
{
    local input=
    input=$1

    local sha1=

    if [[ "${input_type}" == "password" ]]; then
        sha1=$(echo -n "${input}" | sha1sum -)
        sha1="${sha1/[[:space:]]*}"
    else
        sha1="${input}"
    fi

    echo -n "${sha1}"
}

function get_sha1_sums_from_server()
{
    local hash_key=
    hash_key="$1"
    local user_agent=
    user_agent=$2
    local api="https://api.pwnedpasswords.com/range"

    curl \
        --fail \
        --header "Accept: application/json" \
        --header "Content-Type: application/json" \
        --include \
        --request GET "${api}/${hash_key}" \
        --show-error \
        --silent \
        --user-agent "${user_agent}"
}

function check_if_pwned()
{
    local input=
    input="$1"
    local user_agent=
    user_agent="$2"

    local hash_key=
    hash_key=$(get_sha1 "${input}")
    local hash_key_first_5=
    hash_key_first_5="${hash_key:0:5}"
    local hash_key_rest=
    hash_key_rest="${hash_key:5}"

    # Temporary variable is used to avoid grep cutting the pipe too early for
    # curl.
    local output=
    output=$(get_sha1_sums_from_server "${hash_key_first_5}" "${user_agent}")

    if echo "${output}" \
        | grep --quiet --ignore-case "${hash_key_rest}"; then

        log >&2 "This password is pwned! Please, consider changing it for" \
            "the accounts it is currently used, and avoid using it in the" \
            "future for any other account."
        exit 1
    else
        log "This password is not pwned! Feel free to keep using it."
    fi
}

quiet=false
input_type=password

while getopts ":hpqsv" options; do
    case "${options}" in
        h)
            usage
            exit
            ;;
        p)
            input_type=password
            ;;
        q)
            quiet=true
            ;;
        s)
            input_type=sha1
            ;;
        v)
            version
            exit
            ;;
        \?)
            usage >&2
            exit 1
            ;;
    esac
done

shift "$((OPTIND - 1))"
readonly user_input=$(read_input "$@")
shift "$#"

validate_input "${input_type}" "${user_input}"

check_if_pwned "${user_input}" "${script_name}"
