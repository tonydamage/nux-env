#!/bin/sh

echo "Installing Oracle Java."

sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer

git config --global core.excludesfile ~/Environment/gitignore-global
