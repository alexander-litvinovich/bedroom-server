#!/bin/bash

TARGET_USER="$PAM_USER"

# Get the current (new) session
CURRENT_SESSION=$(loginctl list-sessions --no-legend | awk -v u="$TARGET_USER" '$3==u {print $1}' | tail -n 1)

# Terminate all other sessions for this user
for SESS in $(loginctl list-sessions --no-legend | awk -v u="$TARGET_USER" '$3==u {print $1}'); do
  if [ "$SESS" != "$CURRENT_SESSION" ]; then
    loginctl terminate-session "$SESS"
  fi
done

exit 0
