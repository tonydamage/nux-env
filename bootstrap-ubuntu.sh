#!/bin/sh


echo Removing Unity Scopes

sudo apt-get  remove unity-scope-musicstores unity-scope-openclipart unity-scope-yelp

echo Installing Unity Tweak Tool

sudo add-apt-repository ppa:freyja-dev/unity-tweak-tool-daily
sudo apt-get update 
sudo apt-get install unity-tweak-tool


echo Installing Indicators

sudo apt-get install indicator-multiload
