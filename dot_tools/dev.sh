#!/bin/bash

dev() {
    CURRENT_DIRECTORY=${PWD##*/}
    WINDOW_NAME=${1:-$CURRENT_DIRECTORY}

    tmux rename-window -t 0 $WINDOW_NAME
    tmux split-window -v -p 25 -c "#{pane_current_path}"
}

