#!/bin/bash

VERBOSE_MODE=false
CONFIG_FILE_URL=""

usage() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo " -h, --help           Display this help message"
    echo " -v, --verbose        Enable verbose mode"
    echo " -c, --config URL     Specify a config file URL"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
    echo "${2:-${1#*=}}"
}

handle_options() {
    while [ $# -gt 0 ]; do
        case $1 in
            -h | --help)
                usage
                exit 0
            ;;
            -v | --verbose)
                VERBOSE_MODE=true
            ;;
            -c | --config*)
                if ! has_argument $@; then
                    echo
                    echo "File not specified." >&2
                    usage
                    exit 1
                fi
                CONFIG_FILE_URL=$(extract_argument $@)
                shift
            ;;
            *)
                echo
                echo "Invalid option: $1" >&2
                usage
                exit 1
            ;;
        esac
        shift
    done
}

handle_options "$@"

function exit_with_failure() {
    echo "----------------------------------------"
    tput setaf 1
    echo "[ FAILED ]"
    tput sgr0
    echo "FAILURE: $1" >&2
    echo
    exit 1
}

function command_exists() {
    hash $1 >/dev/null 2>&1
}

clear
echo " ________ ,---.    ,---.    ,-----.    ,---.   .--."
echo "|        ||    \  /    |  .'  .-,  '.  |    \  |  |"
echo "|   .----'|  ,  \/  ,  | / ,-.|  \ _ \ |  ,  \ |  |"
echo "|  _|____ |  |\_   /|  |;  \  '_ /  | :|  |\_ \|  |"
echo "|_( )_   ||  _( )_/ |  ||  _\`,/ \ _/  ||  _( )_\  |"
echo "(_ o._)__|| (_ o _) |  |: (  '\_/ \   ;| (_ o _)  |"
echo "|(_,_)    |  (_,_)  |  | \ \`\"/  \  ) / |  (_,_)\  |"
echo "|   |     |  |      |  |  '. \_/\`\`\".'  |  |    |  |"
echo "'---'     '--'      '--'    '-----'    '--'    '--'"
echo
echo "Fluent-bit installation script."
echo "----------------------------------------"

if [ $VERBOSE_MODE = true ]; then
    echo "Detecting OS..."
fi
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "${ID}")
elif command_exists lsb_release; then
    OS=$(lsb_release -is)
else
    OS=$(uname -s)
fi
if [ $VERBOSE_MODE = true ]; then
    echo "Detected OS: $OS."
fi
OS=$(echo $OS | tr '[:upper:]' '[:lower:]')

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Detecting available fetcher..."
fi
if command_exists wget; then
    FETCHER="wget"
elif command_exists curl; then
    FETCHER="curl"
else
    exit_with_failure "Neither 'wget' nor 'curl' command found."
fi
if [ $VERBOSE_MODE = true ]; then
    echo "Detected fetcher: $FETCHER."
fi

cd /tmp || exit_with_failure "Failed to change directory to /tmp."

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Installing Fluent-bit..."
    echo
fi
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh || exit_with_failure "Failed to install Fluent-bit."
if [ $VERBOSE_MODE = true ]; then
    echo "Fluent-bit installed."
fi

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Configuring Fluent-bit..."
    echo
fi
case $CONFIG_FILE_URL in
    "")
        echo "No configuration file provided. Will use default configuration."
        ;;
    *)
        case $FETCHER in
            wget)
                OUTPUT_COMMAND="-O fluent-bit.conf"
                ;;
            curl)
                OUTPUT_COMMAND="-o fluent-bit.conf"
                ;;
        esac

        $FETCHER $CONFIG_FILE_URL $OUTPUT_COMMAND || exit_with_failure "Failed to download Fluent-bit configuration file."
        if [ $VERBOSE_MODE = true ]; then
            echo "Fluent-bit config downloaded at '/tmp/fluent-bit.conf'."
        fi

        sudo cp fluent-bit.conf /etc/fluent-bit/fluent-bit.conf || exit_with_failure "Failed to copy Fluent-bit configuration file."
        if [ $VERBOSE_MODE = true ]; then
            echo "Fluent-bit configured."
        fi
        ;;
esac

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Enabling Fluent-bit Service..."
fi
sudo systemctl restart fluent-bit && sudo systemctl enable fluent-bit || exit_with_failure "Failed to restart Fluent-bit service."
if [ $VERBOSE_MODE = true ]; then
    echo "Fluent-bit service enabled."
fi

echo
tput setaf 2
echo "[ SUCCESS ]"
tput sgr0
echo "Fluent-bit has been installed successfully."
exit 0
