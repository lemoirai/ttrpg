#!/bin/bash

DIR="./Open_Hooks"
WORKFLOW_FILE=".github/workflows/hook_close.yml"
INPUT_NAME="hook_template"

cd "$DIR"
files=( $(ls -1 | sort) )
cd ..

# Output for debugging
echo "Filenames array:"
printf "%s\n" "${files[@]}"

# Write as JSON array to options file
printf "%s\n" "${files[@]}" | jq -R . | jq -s . > /tmp/options.json

# Compare and update workflow file input options
set -e
wf="$WORKFLOW_FILE"
input="$INPUT_NAME"

new_opts=$(cat /tmp/options.json)
current_opts=$(yq '.on.workflow_dispatch.inputs["'${input}'"].options' $wf 2>/dev/null || echo '[]')

if [ "$new_opts" = "$current_opts" ]; then
  echo "No changes needed."
  exit 0
fi

# Update the workflow file with new options, which is now an array of strings
yq -i '
  .on.workflow_dispatch.inputs["'"${input}"'"].options = load("/tmp/options.json")
' "$wf"

# Preserve emojis
echo -e "$(cat $wf | yq eval)" > $wf
