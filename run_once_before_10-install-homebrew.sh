#!/bin/sh
if ! command -v brew >/dev/null 2>&1 \
  && [ ! -x /opt/homebrew/bin/brew ] \
  && [ ! -x /usr/local/bin/brew ] \
  && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
