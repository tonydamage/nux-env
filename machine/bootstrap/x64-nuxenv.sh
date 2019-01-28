#!/bin/bash
function .not_present() {
  if which "$1" &> /dev/null; then
    return 1
  fi
  return 0;
}

if .not_present yaml; then
  wget https://github.com/mikefarah/yaml/releases/download/1.11/yaml_linux_amd64 -O ~/bin/yaml
  chmod +x ~/bin/yaml
fi

if .not_present jq; then
  apt install jq
fi
