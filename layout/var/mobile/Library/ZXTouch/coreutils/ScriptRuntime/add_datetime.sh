#!/bin/bash
echo "`date "+%m-%d-%Y %T"`: Start running script. Script path: $1" >>  /var/jb/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output
while read line;
do
   echo "`date "+%m-%d-%Y %T"`: $line" >> /var/jb/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output;
done
