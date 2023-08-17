#!/bin/bash
echo "This file removes all the tar images. You can quickly regenerate them by executing mergeAndCreate.sh"


read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        do_something
        shopt -s dotglob
		shopt -s nullglob
		COMPONENTS=(*/)
		for dir in "${COMPONENTS[@]}"; do 
			echo "$dir";
			TARGET_FILE=$(ls $dir*.tar)
			if test -z "$TARGET_FILE"
				then
				rm -v $TARGET_FILE
			fi
		done

    *)
        do_something_else
        echo "Wise choice. Make sure you have sufficient HDD space"
esac
