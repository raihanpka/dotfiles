#!/usr/bin/env bash
# spinner.sh - show / \ animation while running a command
# Usage: spinner.sh <title> <command...>

TITLE="$1"
shift

Y='\033[1;33m'
G='\033[0;32m'
NC='\033[0m'

spin_chars='\/'
i=0

"$@" >/dev/null 2>&1 &
pid=$!

while kill -0 "$pid" 2>/dev/null; do
  ch="${spin_chars:$i:1}"
  printf "\r  ${Y}%s${NC} %s" "$ch" "$TITLE"
  i=$(( (i + 1) % ${#spin_chars} ))
  sleep 0.1
done

wait "$pid"
rc=$?

if [ $rc -eq 0 ]; then
  printf "\r  ${G}OK${NC}  %s\n" "$TITLE"
else
  printf "\r  ${Y}!!${NC}  %s\n" "$TITLE"
fi

exit $rc
