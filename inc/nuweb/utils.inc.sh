function nuweb.paginate() {
  nuweb.html.element.spec --content-as-args nuweb.paginate0 "$@";
}


function nuweb.paginate00() {
  echo "<${element}${classes}{$attrs}>"
  while IFS= read -r f; do
    if [ $current -ge $stop_when ]; then
      let next_page=page+1;
      break;
    elif [ $current -ge $skip_till ]; then
      $processItem "$f"
    fi
    let current=$current+1;
  done
  echo "</${element}>"
  if [ -n "$next_page" ]; then
    $nextPage "$next_page" "$per_page"
  fi
}

function nuweb.paginate0() {
  local getItem=$1;
  local processItem=$2;
  local nextPage=$3;
  local perPageDefault=${4:-20};
  local current=0;
  local local items="$($getItem)"
  local page=$(nuweb.http.query.var page 0);
  local per_page=$(nuweb.http.query.var per_page $perPageDefault);
  local total_items="$(wc -l <<< "$items")"


  if [ "$total_items" -eq 1 -a -z "$items" ]; then
    total_items=0;
  fi

  let skip_till=$page*$per_page;
  let stop_when=($page+1)*$per_page;


  nux.log info "Functions: $getItem $processItem $nextPage";
  nux.log info "Displaying: $skip_till-$stop_when Total: $total_items (Page: $page Per page: $per_page)"



  if [ -n "$before" ]; then
    nux.exec.optional $before
  fi
  if [ "$total_items" -gt 0 ]; then
    nuweb.paginate00 <<< "$items"
  fi
  if [ -n "$after" ]; then
    nux.exec.optional $after $total_items
  fi

}
