#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/tmp"
LOG_DIR="/tmp"

cd "$SCRIPT_DIR"

for script in $(ls *.sh | grep -v run_all.sh | sort); do
    log_file="$LOG_DIR/${script%.sh}.log"
    
    if [[ -f "$log_file" ]]; then
#        echo "⏭ Skipping $script (already completed)"
        continue
    fi

    echo "➡️ Running $script..."
    chmod +x "$script"
    sudo bash "$script" 2>&1 | tee "$log_file"
    echo "✔ Completed: $script (Log: $log_file)"
done
