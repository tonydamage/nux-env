@syntax nuweb/html
@prefix h nuweb.html
@prefix hd nuweb.html.dynamic
nux.use nuweb/html

function mdlio.css() {
  e.link stylesheet "https://fonts.googleapis.com/css?family=Roboto:regular,bold,italic,thin,light,bolditalic,black,medium&lang=en"
  e.link stylesheet "https://fonts.googleapis.com/icon?family=Material+Icons"
  e.link stylesheet "https://code.getmdl.io/1.3.0/material.${1}-${2}.min.css"

}

function e.mdlio.header++() {
  +e header .mdl-layout__header .mdl-color--primary
    +e div .mdl-layout__header-row
      e span .mdl-layout-title $1
      e div .mdl-layout-spacer
}

@namespace nuweb.mdlio.tag {

  function :textfield id type label {
    h:div .mdl-textfield.mdl-js-textfield.mdl-textfield--floating-label {
      hd:input .mdl-textfield__input @type "$type" @id "$id" "$@"
      h:label .mdl-textfield__label @for $id {
          echo $label
      }
    }
  }

  function :submit name {
    hd:input @type submit .mdl-button.mdl-js-button.mdl-button--raised.mdl-button--accent @value "$name" "$@"
  }

  function :nav-link href {
    h:a .mdl-navigation__link @href "$href" {
        echo "$@"
    }
  }

}

e.alias mdlio.layout "div" ".mdl-layout .mdl-js-layout"
e.alias mdlio.main "main" ".mdl-layout__content"
e.alias mdlio.card "div" ".mdl-card.mdl-shadow--2dp"

function .mdl_cell() {
  echo  mdl-cell mdl-cell--"$1"-col mdl-cell--"$2"-col-tablet mdl-cell--"$2"-col-phone
}
