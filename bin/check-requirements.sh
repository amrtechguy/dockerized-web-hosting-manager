#!/bin/bash

EXIT_CODE=0

# check dirs
while read -r REQUIRED_DIR; do
	if ! [ -d $REQUIRED_DIR ]; then
		echo "[error] dir missing: $REQUIRED_DIR"
		EXIT_CODE=1
	fi
done < $FRAMEWORK_ROOT_DIR/data/required_dirs

# check files
while read -r REQUIRED_FILE; do
	if ! [ -f $REQUIRED_FILE ]; then
		echo "[error] file missing: $REQUIRED_FILE"
		EXIT_CODE=1
	fi
done < $FRAMEWORK_ROOT_DIR/data/required_files

# check commands
while read -r REQUIRED_COMMAND; do
	if ! which $REQUIRED_COMMAND > /dev/null 2>&1; then
		echo "[error] command missing: $REQUIRED_COMMAND"
		EXIT_CODE=1
	fi
done < $FRAMEWORK_ROOT_DIR/data/required_commands

exit $EXIT_CODE
