#!/bin/bash
shopt -s dotglob
shopt -s nullglob
COMPONENTS=(*/)
for dir in "${COMPONENTS[@]}"; do 
	echo "$dir";
	temp=$(ls $dir*.tar.aa)
	TARGET_FILE=${temp::-3}
	cat $TARGET_FILE.a? > $TARGET_FILE
	sudo docker load --input $TARGET_FILE
done