#!/bin/bash

GRAFANA_AGENT_VER="0.41.1-1"
DEB_URL="https://github.com/grafana/agent/releases/download/v0.41.1/grafana-agent-${GRAFANA_AGENT_VER}.amd64.deb"
RPM_URL="https://github.com/grafana/agent/releases/download/v0.41.1/grafana-agent-${GRAFANA_AGENT_VER}.amd64.rpm"

VERBOSE_MODE=false

usage() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo " -h, --help           Display this help message"
    echo " -v, --verbose        Enable verbose mode"
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
echo "Grafana Agent installation script."
echo "----------------------------------------"

if [ $VERBOSE_MODE = true ]; then
    echo "Verbose mode enabled."
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
case $OS in
    ubuntu|debian)
        GRAFANA_AGENT_URL=$DEB_URL
        PACKAGE=".deb"
        ;;
    centos|centoslinux|rhel|redhatenterpriselinuxserver|fedora|rocky|almalinux)
        GRAFANA_AGENT_URL=$RPM_URL
        PACKAGE=".rpm"
        ;;
    *)
        exit_with_failure "Unsupported OS: '$OS'"
        ;;
esac

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

case $FETCHER in
    wget)
        OUTPUT_COMMAND="-O grafana-agent$PACKAGE"
        ;;
    curl)
        OUTPUT_COMMAND="-o grafana-agent$PACKAGE"
        ;;
esac

cd /tmp || exit_with_failure "Failed to change directory to /tmp."

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Downloading Grafana Agent..."
    echo
fi
$FETCHER $GRAFANA_AGENT_URL $OUTPUT_COMMAND || exit_with_failure "Failed to download Grafana Agent package."
if [ $VERBOSE_MODE = true ]; then
    echo "Grafana Agent downloaded at '$(pwd)/telegraf$PACKAGE'."
fi

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Installing Grafana Agent..."
fi
echo "This script requires superuser access to install packages."
echo "You will be prompted for your password by sudo."
echo
case $OS in
    ubuntu|debian)
        sudo dpkg -i grafana-agent$PACKAGE || exit_with_failure "Failed to install Grafana Agent."
        ;;
    centos|centoslinux|rhel|redhatenterpriselinuxserver|fedora|rocky|almalinux)
        sudo rpm -i grafana-agent$PACKAGE || exit_with_failure "Failed to install Grafana Agent."
        ;;
esac
if [ $VERBOSE_MODE = true ]; then
    echo "Grafana Agent installed."
fi

if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Configuring Grafana Agent..."
    echo
fi

sudo echo -e "server:\n  log_level: warn\n\nmetrics:\n  global:\n    scrape_interval: 1m\n    external_labels:\n      [[KEY]]: [[VALUE]]\n      [[KEY]]: [[VALUE]]\n    remote_write:\n    - url: https://[[DATASOURCE_ENDPOINT]]\n      basic_auth:\n        username: [[DATASOURCE_USERNAME]]\n        password: [[DATASOURCE_PASSWORD]]\n  wal_directory: '/var/lib/grafana-agent'\n  configs:\n\nintegrations:\n  agent:\n    enabled: true\n  node_exporter:\n    enabled: true\n    include_exporter_metrics: true\n    disable_collectors:\n      - "mdadm"" > /etc/grafana-agent.yaml || exit_with_failure "Failed to configure Grafana Agent."

read -p "Add PostgreSQL integration? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo echo -e "  postgres_exporter:\n    enabled: true\n    data_source_names:\n    - postgresql://[[POSTGRES_USER]]:[[POSTGRES_PASSWORD]]@localhost:5432/[[POSTGRES_DB]]?sslmode=disable" >> /etc/grafana-agent.yaml || exit_with_failure "Failed to configure Grafana Agent."
fi

if [ $VERBOSE_MODE = true ]; then
    echo "Grafana Agent configured."
fi


if [ $VERBOSE_MODE = true ]; then
    echo "----------------------------------------"
    echo "Enabling Grafana Agent Service..."
fi
sudo systemctl restart grafana-agent && sudo systemctl enable grafana-agent || exit_with_failure "Failed to restart Grafana Agent service."
if [ $VERBOSE_MODE = true ]; then
    echo "Grafana Agent service enabled."
fi

echo "----------------------------------------"
tput setaf 2
echo "[ SUCCESS ]"
tput sgr0
echo "Grafana Agent has been installed successfully."
echo
exit 0
