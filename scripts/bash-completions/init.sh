# (source this file to export definitions)

for SCRIPT in *_completion.sh; do
  source ${SCRIPT}
done

# If an argument is given, then pre-generate the cache

if [[ -n $1 ]]; then
  for FUN in $(declare -F | awk '/_generate_/ {print $3}'); do
    echo -n "Evaluating ${FUN}..."
    eval ${FUN}
    echo
  done
fi
