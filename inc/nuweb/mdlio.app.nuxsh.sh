@syntax nuweb/html

nux.use nuweb/mdlio
nux.use nuweb/mdlio.app.defaults
nux.use nuweb/router
nux.use nux.mime

@prefix h nuweb.html
@prefix router nuweb.router

@block:rewrite:call2 e +e -e ;

@namespace mdlio.app {

  function mdlio.app {
    nux.exec.optional app.init
    mdlio.app.html "$@"
  }

  function :custom func {
    nux.exec.or $func app.$func "$@";
  }

  function :html {
    nuweb.content_type text/html
    echo
    local spec="$1"; shift;
    $spec "$@";

    local app_uri="${NUWEB_SCRIPT_URI}";
    local appName=$(nux.exec.optional app.name);
    local title="$(nux.exec.optional title)";
    echo "<!doctype html>"
    h:html {
      h:head {
        h:meta @charset utf-8
        h:meta @http-equiv x-ua-compatible @content ie=edge
        h:meta @name "viewport" @content "width=device-width, initial-scale=1.0, minimum-scale=1.0"
        mdlio.css $(mdlio.app.custom color.primary) $(mdlio.app.custom color.accent)
        h:link @rel stylesheet @href "$NUWEB_SCRIPT_URI/action:asset/mdlio-app.css"
        h:link @rel stylesheet @href "https://unpkg.com/simplelightbox@1.11.0/dist/simplelightbox.css"

        nux.exec.optional app.custom.head
        h:title "$(app.title) - $appName"
      }
      h:body .mdl-base {
        +mdlio.layout .mdl-layout--fixed-header
          e.mdlio.header++ "$appName"
              mdlio.app.custom header
            -e div
          -e header
          if nux.check.function app.drawer ; then
            h:div .mdl-layout__drawer {
              app.drawer
              nux.exec.optional drawer
            }
          fi
          +mdlio.main
            nux.exec.optional app.main.start

            nux.exec.or app.template-main app.content "$@"




          -e main
        -e div

        mdlio.app.photoswipe.html

        h:div .scripts {
          h:script @src "https://code.jquery.com/jquery-3.2.1.min.js"
          h:script @src "https://unpkg.com/masonry-layout@4/dist/masonry.pkgd.js"
          h:script @src "https://unpkg.com/photoswipe@4.1.2/dist/photoswipe.js"
          h:script @src "https://unpkg.com/photoswipe@4.1.2/dist/photoswipe-ui-default.js"
          h:link @rel stylesheet @href https://unpkg.com/photoswipe@4.1.2/dist/photoswipe.css
          h:link @rel stylesheet @href https://unpkg.com/photoswipe@4.1.2/dist/default-skin/default-skin.css
          h:script @src "https://unpkg.com/infinite-scroll@3/dist/infinite-scroll.pkgd.js"
          h:script @src "$NUWEB_SCRIPT_URI/action:asset/mdlio-app.js"
          h:script @src "https://code.getmdl.io/1.3.0/material.min.js"
          nux.exec.optional scripts
        }
      }
    }
  }

  function :grid-sizer {
    h:div @id scooter {
      h:div .mdl-grid @id sizer {
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet

        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
        h:div @id gutter .gutter .mdl-cell .mdl-cell--1-col .mdl-cell--1-col-phone .mdl_cell--1-col-tablet
      }
    }
  }

  function :infinity container item nextPage {
  local outlayer="";
  e script """
  var infScroll = new InfiniteScrolldocument.querySelector('$container'); grid, {
    path: '$nextPage',
    append: '$item',
    $outlayer
    status: '.page-load-status',
    elementScroll: '.mdl-layout__content'
  });
  """
}

function :masonry grid gridItem lightBoxItem gutter nextPage {
  e script """
    var gallery = new mdlio.cardsGallery(document.querySelector('$grid'), '$gridItem', '$lightBoxItem');
  """

}

function :action.uri action path args {
  echo "$NUWEB_SCRIPT_URI/action:${action}${path}${args}"
}

function :thumb.uri filename mimetype {
  local thumb_name="$(thumby.name.shared "$filename")"
  local dirname=$(dirname "$filename")
  local thumb_path="$dirname/.sh_thumbnails/large/$thumb_name"

  if thumby.thumb.can.generate "$filename" "$mimetype"; then
    if thumby.thumb.should.generate "$filename" "$mimetype"; then
      :action.uri thumb "$NUWEB_REQUEST_PATH/$filename"
      return 0;
    fi
  fi


  if [ -e "$thumb_path" ] ; then
    nux.dirty.urlencode "$thumb_path"
  fi
}

function :thumb.get {
  img_path="${@##/}"
  nux.log info "Generating thumb for" $(pwd) "$img_path"
  thumb_path="$(thumby.thumb.get "${DOCUMENT_ROOT}/$img_path")";
  if [ -n "$thumb_path" ]; then
    nux.dirty.urlencode "${thumb_path#$DOCUMENT_ROOT}";
  fi
}


function :run {
  nuweb.router.exec mdlio.app.routes
}

function :routes {
  function :post uri_spec {
    router:post "$uri_spec" mdlio.app "$@"
  }

  function :get uri_spec {
    router:get "$uri_spec" mdlio.app "$@"
  }

  function :get.paginate {
    function app.content {
      #nux.exec.optional before "$@";
      before=before after=after nuweb.paginate div .gallery .mdl-grid items per-item next-page 20;
      #nux.exec.optional after "$@";
    }
    function next-page {
      h:div .mdl-grid {
        h:div .mdl-cell .mdl-cell--11-col .mdl-cell--col-3-phone .mdl-cell--col-7-tablet
        h:div .mdl-cell .mdl-cell--1-col {
          h:a .next-page .mdl-button.mdl-button--colored @href "${REQUEST_URI%%?*}?page=$1&per_page=$2" Next
        }
      }
    }
    :get "$@"
  }

  #nuweb.get "/action:zip:serve/@+" mdlio.action.zip.serve
  router:get "/action:thumb/@+" nuweb.redirect.exec mdlio.app.thumb.get
  router:get "/action:asset/@" mdlio.app.asset
  nux.exec.optional app.routes;
  :get "/" app.main;
}


function :asset name {
  local file="$NUX_ENV_DIR/assets/nuweb/$name";
  if [ -e "$file" ]; then
    mime=$(nux.mime "$file");
    echo Content-Type: $mime
    echo
    cat "$file"
  fi
}

function :photoswipe.html {
  echo "<div></div>"
}

}
