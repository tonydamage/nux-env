@namespace nux.array {

  function :contains array value {
    local array_ref="$array[@]";
    for c in "${!array_ref}"; do
      if [ "$c" == "$value" ]; then
        return 0;
      fi
    done
    return 1
  }

}
