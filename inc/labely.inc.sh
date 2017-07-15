##
## Set of support functions for labelImg Xmls

labely.labels.get() {
  local path="$1"
  local filename=$(basename "$1")
  local dirname=$(dirname "$1")
  local labelXml="$dirname/.labely/${filename%.*}.xml"
  nux.log info Looking for $labelXml
  if [ -e $labelXml ] ; then
  xmlstarlet sel -T -t \
   -m "/annotation/object" \
      -v "name" -o " " \
      -m "bndbox" \
        -v "/annotation/size/width" -o " " \
        -v "/annotation/size/height" -o " " \
        -v "xmin" -o " " \
        -v "ymin" -o " " \
        -v "xmax" -o " " \
        -v "ymax" -n $labelXml
  fi
}
