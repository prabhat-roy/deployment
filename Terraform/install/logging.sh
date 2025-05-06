# logging.sh
log() {
    local type="$1"; shift
    local message="$*"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    case "$type" in
        INFO) color="\e[34m";;
        WARN) color="\e[33m";;
        ERROR) color="\e[31m";;
        SUCCESS) color="\e[32m";;
        *) color="\e[0m";;
    esac

    echo -e "${color}[$timestamp] [$type] $message\e[0m"
}
