#!/bin/bash

#
#   Grep all kinks in html page.
#   Use Regex to adapt a pattern if you need.
#   copyright (c) 2019 Medour Mehdi
#   
#   https://github.com/MedourMehdi
#

#   URL where we want get downloads links (here a random url is provided)
link="http://strider.untergrund.net/toxicmag/down.htm"
# Pattern to keep 
regex="(ftp|http|https)://[a-zA-Z0-9./?=_-]*"
# final filename where we grep
down_file=$(basename ${link})

if [ -f $down_file ];then
# avoiding unwanted page
    rm -f ${down_file};
# get html web page
    wget ${link}
fi

# Main loop
if [ -f $down_file ];then
    for url in $(grep -Eo "${regex}" ${down_file});do 
        wget $url ; 
    done
fi