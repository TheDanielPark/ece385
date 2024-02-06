#!/bin/sh

# Support spaces in path.  By nulling IFS, dirname will work
IFS=

FILEPATH=${0//\\/\/}
_this_script=$(cd ${FILEPATH%[/]*} && echo $(pwd 2>/dev/null)/${FILEPATH##*/})
_this_script_dir=$(dirname ${_this_script})
CMD="$0"
perl -I ${_this_script_dir} ${_this_script_dir}/pl_jar.pl "$CMD" "$@"
