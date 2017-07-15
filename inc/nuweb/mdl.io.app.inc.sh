nux.use nuweb/mdl.io
nux.use nuweb/router
nux.use nux.mime

mdlio.app() {
  mdlio.app.html "$@"
}

app.header() {
  :
}

mdlio.app.custom() {
  local func=$1; shift;
  nux.exec.or $func app.$func "$@";
}

mdlio.app.html() {
  nuweb.content_type text/html
  echo
  local spec="$1"; shift;
  $spec "$@";

  local appName=$(nux.exec.optional app.name);
  local title="$(nux.exec.optional title)";
  echo "<!doctype html>"
  +e html
    +e head
      e meta @charset utf-8
      e meta @http-equiv x-ua-compatible @content ie=edge
      e meta @name "viewport" @content "width=device-width, initial-scale=1.0, minimum-scale=1.0"
      mdlio.css $(mdlio.app.custom color.primary) $(mdlio.app.custom color.accent)
      e link @rel stylesheet @href "$NUWEB_SCRIPT_URI/action:asset/mdlio-app.css"
      e link @rel stylesheet @href "https://unpkg.com/simplelightbox@1.11.0/dist/simplelightbox.css"

      nux.exec.optional app.custom.head
      e title "$title - $appName"
    -e head
    +e body .mdl-base
      +mdlio.layout .mdl-layout--fixed-header
        e.mdlio.header++ "$appName"
            mdlio.app.custom header
          -e div
        -e header
        if nux.check.function app.drawer ; then
          +e div .mdl-layout__drawer
            app.drawer
            nux.exec.optional drawer
          -e div
        fi
        +mdlio.main
          nux.exec.optional app.main.start
          main "$@"


          +e div @id scooter
            +e div .mdl-grid @id sizer
              e div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
            -e div
          -e div

          nux.exec.optional app.main.end
        -e main
      -e div
      mdlio.app.photoswipe.html

      e script @src https://code.jquery.com/jquery-3.2.1.min.js
      e script @src https://unpkg.com/masonry-layout@4/dist/masonry.pkgd.js
      #e script @src https://unpkg.com/simplelightbox@1.11.0/dist/simple-lightbox.js
      e script @src https://unpkg.com/photoswipe@4.1.2/dist/photoswipe.js
      e script @src https://unpkg.com/photoswipe@4.1.2/dist/photoswipe-ui-default.js
      e link @rel stylesheet @href https://unpkg.com/photoswipe@4.1.2/dist/photoswipe.css
      e link @rel stylesheet @href https://unpkg.com/photoswipe@4.1.2/dist/default-skin/default-skin.css
      e script @src https://unpkg.com/infinite-scroll@3/dist/infinite-scroll.pkgd.js
      e script @src "$NUWEB_SCRIPT_URI/action:asset/mdlio-app.js"
      e script @src "https://code.getmdl.io/1.3.0/material.min.js"
      nux.exec.optional scripts

    -e body
  -e html
}

app.color.primary() {
  echo teal
}

app.color.accent() {
  echo cyan
}

mdlio.app.infinity() {
  # outlayer: msnry,
  local container=$1;
  local item=$2;
  local nextPage=$3;
  local outlayer="";
  e script """
  var grid = document.querySelector('$container');
  var infScroll = new InfiniteScroll( grid, {
    path: '$nextPage',
    append: '$item',
    $outlayer
    status: '.page-load-status',
    elementScroll: '.mdl-layout__content',
  });
  """

}

function mdlio.app.masonry() {
  local grid="$1"
  local gridItem="$2"
  local lightBoxItem="$3"
  local gutter="$4"
  local nextPage="$5";
  e script """
    var gallery = new mdlio.cardsGallery(document.querySelector('$grid'), '$gridItem', '$lightBoxItem');
"""

}


function mdlio.app.thumb.uri() {
  local filename="$1";
  local mimetype="$2";

  #if [ -d "$filename" ] ; then
  #  nux.log info "File $filename is folder."
  #  filename=$(find "$1" -maxdepth 1 -iname "*.jpg" -or -iname "*.png" | head -n1)
  #  nux.log info "Using $filename for thumbnail."
  #fi

  local thumb_name="$(thumby.name.shared "$filename")"
  local dirname=$(dirname "$filename")
  local thumb_path="$dirname/.sh_thumbnails/large/$thumb_name"
  if [ -e "$thumb_path" ] ; then
    nux.dirty.urlencode $thumb_path
  elif thumby.thumb.can.generate "$filename" "$mimetype"; then
    echo "$NUWEB_SCRIPT_URI/action:thumb/$NUWEB_REQUEST_PATH/$filename"
  fi
}

function mdlio.app.thumb.get() {
  img_path="${@##/}"
  nux.log info "Generating thumb for" $(pwd) "$img_path"
  thumb_path=$(thumby.thumb.get "${DOCUMENT_ROOT}/$img_path");
  if [ -n "$thumb_path" ]; then
    nux.dirty.urlencode ${thumb_path#$DOCUMENT_ROOT};
  fi
}


mdlio.app.run() {
  nuweb.router.exec mdlio.app.routes
}

mdlio.app.routes() {
  get() {
    local uri_spec="$1"; shift;
    nuweb.get "$uri_spec" mdlio.app "$@"
  }

  get.paginate() {
    main() {
      #nux.exec.optional before "$@";
      before=before after=after nuweb.paginate div .gallery .mdl-grid items per-item next-page 20;
      #nux.exec.optional after "$@";
    }
    next-page() {
      +e div .mdl-grid
        e div .mdl-cell .mdl-cell--11-col .mdl-cell--col-3-phone .mdl-cell--col-7-tablet
        +e div .mdl-cell .mdl-cell--1-col
        e a .next-page .mdl-button.mdl-button--colored @href "${REQUEST_URI%%?*}?page=$1&per_page=$2" Next
        -e div
      -e div
    }
    get "$@"
  }

  #nuweb.get "/action:zip:serve/@+" mdlio.action.zip.serve
  nuweb.get "/action:thumb/@+" nuweb.redirect.exec mdlio.app.thumb.get
  nuweb.get "/action:asset/@" mdlio.app.asset
  nux.exec.optional app.routes;
}


mdlio.app.asset() {
  file="$NUX_ENV_DIR/assets/nuweb/$1";
  if [ -e "$file" ]; then
    mime=$(nux.mime "$file");
    echo Content-Type: $mime
    echo
    cat "$file"
  fi
}


mdlio.app.photoswipe.html() {
  cat <<EOF
  <!-- Root element of PhotoSwipe. Must have class pswp. -->
  <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true">

      <!-- Background of PhotoSwipe.
           It's a separate element as animating opacity is faster than rgba(). -->
      <div class="pswp__bg"></div>

      <!-- Slides wrapper with overflow:hidden. -->
      <div class="pswp__scroll-wrap">

          <!-- Container that holds slides.
              PhotoSwipe keeps only 3 of them in the DOM to save memory.
              Don't modify these 3 pswp__item elements, data is added later on. -->
          <div class="pswp__container">
              <div class="pswp__item"></div>
              <div class="pswp__item"></div>
              <div class="pswp__item"></div>
          </div>

          <!-- Default (PhotoSwipeUI_Default) interface on top of sliding area. Can be changed. -->
          <div class="pswp__ui pswp__ui--hidden">

              <div class="pswp__top-bar">

                  <!--  Controls are self-explanatory. Order can be changed. -->

                  <div class="pswp__counter"></div>

                  <button class="pswp__button pswp__button--close" title="Close (Esc)"></button>

                  <button class="pswp__button pswp__button--share" title="Share"></button>

                  <button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button>

                  <button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button>

                  <!-- Preloader demo http://codepen.io/dimsemenov/pen/yyBWoR -->
                  <!-- element will get class pswp__preloader--active when preloader is running -->
                  <div class="pswp__preloader">
                      <div class="pswp__preloader__icn">
                        <div class="pswp__preloader__cut">
                          <div class="pswp__preloader__donut"></div>
                        </div>
                      </div>
                  </div>
              </div>

              <div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">
                  <div class="pswp__share-tooltip"></div>
              </div>

              <button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)">
              </button>

              <button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)">
              </button>

              <div class="pswp__caption">
                  <div class="pswp__caption__center"></div>
              </div>

          </div>

      </div>

  </div>

EOF
}
