window.mdlio = {

    outlayer: function(outlayer) {
        this.outlayers = [];
        if (outlayer) {
            if (Array.isArray(outlayer)) {
                for (var e of outlayer) {
                    this.outlayers.push(e);
                }
            } else {
                this.outlayers.push(outlayer);
            }
        }
        this.add = function(outlayer) {
            this.outlayers.push(outlayer);
        }
        ;
        this.appended = function(items) {
            mdlio.upgrade.appended(items);
            for (outlayer of this.outlayers) {
                outlayer.appended(items);
            }
        };
    },
    cards: {
        upgrade: function(element) {
            element.querySelectorAll(".mdl-card").forEach(mdlio.cards.upgradeCard)
        },
        upgradeCard: function(card) {
            console.log(card);
            
            if(card.querySelector(".mdl-card_title")) {
                card.classList.add("has-title");
            }
            if(card.querySelector(".mdl-card__actions")) {
                card.classList.add("has-actions");
            }

            const parent=card.parentNode;
            const as=card.querySelector(".action.select");

            /*if(parent.matches(".card-wrapper") && as) {
                parent.appendChild(as);
            }*/

            card.classList.remove("upgradeable");
            card.classList.add("upgraded");

        },
    },
    lightbox: function(grid, selector, options) {
        var pswpElement = document.querySelectorAll('.pswp')[0];
        if (pswpElement == null ) {
            pswpElement = mdlio.addPSWP();
        }
        /*this.box = $(grid).find(selector).simpleLightbox(options); */
        var items = [];
        this.items = items;
        const linkClicked = function(e) {
            console.log(this, this.lboxId);
            e.preventDefault();
            var options = {
                index: this.lboxId
            };
            var gallery = new PhotoSwipe(pswpElement,PhotoSwipeUI_Default,items,options);
            gallery.init();
        };
        this.appended = function(appendedItems) {
            //this.box.destroy();
            for (var item of appendedItems) {
                var link = item.querySelector(selector);
                if (link == null ) {
                    continue;
                }
                var img = link.querySelector('img');
                var width = img.naturalWidth;
                var height = img.naturalHeight;
                var maybeSize = link.getAttribute('data-img-size');
                if (maybeSize) {
                    console.log(maybeSize);
                    [ width , height ] = maybeSize.split('x').map(function(x) {
                        return Number.parseInt(x);
                    });
                }
                var slide = {
                    msrc: img.getAttribute('src'),
                    src: link.getAttribute('href'),
                    w: width,
                    h: height
                };
                console.log(slide);
                var slideId = items.push(slide) - 1;
                var links = item.querySelectorAll(selector);
                for (link of links) {
                    if (link.getAttribute('href') == slide.src) {
                        link.lboxId = slideId;
                        link.addEventListener("click", linkClicked);
                    }
                }
            }
            //this.box = $(grid).find(selector).simpleLightbox(options);
        }
    },
    infiniteScroll: function(grid, item, nextPage, outlayer) {
        var outlayers = new mdlio.outlayer(outlayer);
        var infScroll = new InfiniteScroll(grid,{
            path: nextPage,
            hideNav: nextPage,
            append: item,
            outlayer: outlayers,
            status: '.page-load-status',
            scrollThresold: 100,
            prefill: true //elementScroll: '.mdl-layout__content',
        });
        infScroll.outlayers = outlayers;
        return infScroll;
    },
    cardsGallery: function(grid, item, lightboxItem) {
        const lightbox = new mdlio.lightbox(grid,lightboxItem + " a");
        const msnry = new Masonry(grid,{
            itemSelector: 'none',
            // select none at first
            columnWidth: document.querySelector('#gutter'),
            gutter: 0,
            containerStyle: {
                width: 'calc(100% - 16px)',
                padding: '0px',
                position: 'relative'
            },
            percentPosition: true,
            // nicer reveal transition
            visibleStyle: {
                transform: 'translateY(0)',
                opacity: 1
            },
            hiddenStyle: {
                transform: 'translateY(100px)',
                opacity: 0
            },
        });
        this.lightbox = lightbox;
        this.masonry = msnry;
        imagesLoaded(grid, function() {
            grid.classList.remove('are-images-unloaded');
            msnry.options.itemSelector = item;
            var items = grid.querySelectorAll(item);
            lightbox.appended(items);
            msnry.appended(items);
        });
        if (document.querySelector(".next-page")) {
            this.infiniteScroll = new mdlio.infiniteScroll(grid,item,'.next-page',[msnry, this.lightbox]);
        }
    },
    addPSWP: function() {
        var body = document.querySelector('body');
        var pswp = document.createElement('div');
        pswp.classList.add('pswp');
        pswp.innerHTML = `
    <div class="pswp__bg"></div>

    <div class="pswp__scroll-wrap">

        <div class="pswp__container">
            <div class="pswp__item"></div>
            <div class="pswp__item"></div>
            <div class="pswp__item"></div>
        </div>

        <div class="pswp__ui pswp__ui--hidden">

            <div class="pswp__top-bar">

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

    </div>`
        body.appendChild(pswp);
        return pswp;
    },
    forms: {
        upgrade: function(element) {
            element.querySelectorAll('form .async[type="submit"]').forEach(function(button) {
                button.addEventListener("click", function(e) {
                    e.preventDefault();
                    const form = button.findParentBySelector("form");
                    $.ajax({
                        type: "POST",
                        cache: false,
                        url: form.action,
                        data: $(form).serialize(),
                        success: function(msg) {
                            console.log("Success", msg);
                        }
                    });
                });
            });
        }
    },
    upgrade: {
        initial: function() {
            mdlio.upgrade.appended([document.querySelector("body")]);
        },

        appended: function(items) {
            items.forEach(mdlio.upgrade.upgrade);      
        },

        upgrade: function(item) {
            for(const upgrader of mdlio.upgrade.upgraders) {
                upgrader.upgrade(item);
            }
        },

        upgraders: [],
    },
    selectable: new (function(){
        this.availableActions = new Set();
        
        const selected = new Set();

        this.selected = selected;

        const actionButtons = {};

         this.displayToolbar = function() {
            var toolbar;
            if(!this.toolbar) {
                toolbar = document.createElement("div");
                toolbar.classList.add("selection-bar");
                toolbar.classList.add("mdl-layout__header");
                toolbar.classList.add("mdl-color--white");
                const header = document.querySelector("header.mdl-layout__header");
                toolbar.innerHTML=`
                    <div class="mdl-layout__header-row" >
                      <button class="cancel mdl-layout__drawer-button">
                        <i class="material-icons">arrow_back</i>
                      </button>
                      <span class="mdl-layout_title"><span>0</span> Selected</span>
                      <div class="mdl-layout-spacer"></div>
                      <div class="actions"></div>
                    </div>
                `;


                header.parentNode.appendChild(toolbar);
                toolbar.querySelector("button.cancel").addEventListener("click",this.stopSelection);

                this.toolbar = {
                    toolbar: toolbar,
                    counter: toolbar.querySelector(".mdl-layout_title span"),
                    actions: toolbar.querySelector(".actions")
                };
            } 
            toolbar = this.toolbar;
            toolbar.counter.innerHTML = this.selected.size
        };

        this.addToolbarAction = function(action) {
            this.availableActions.add(action);
            var button = actionButtons[action];
            if(!button) {
                button = document.createElement("div");
                button.innerHTML='<i class="material-icons"></i>'
                button.classList.add("mdl-button");
                button.classList.add("mdl-button--icon");
                button.addEventListener("click", this.actionClickHandler);
                button.dataset.action = action; 
                actionButtons[action] = button;

            }
            this.toolbar.actions.appendChild(button);
            
        };

        this.removeToolbarAction = function(action) {
            this.availableActions.delete(action);
            var button = actionButtons[action];
            if (button) {
                this.toolbar.actions.removeChild(button)    
            }
        }

        this.startSelection = function() {
            this.displayToolbar();
            document.querySelector("body").classList.add("selection-mode");
            
        }

        this.stopSelection = function() {
            document.querySelector("body").classList.remove("selection-mode");
            for (item of mdlio.selectable.selected) {
                mdlio.selectable.unselect(item);
            }
        }

        this.select = function(item) {
            item.classList.add("selected");
            this.selected.add(item);
            
            this.startSelection();

            var actions = item.querySelectorAll("[data-selectable-action]");
            
            var actionsSet = new Set();
            for (const action of actions) {
                actionsSet.add(action.dataset.selectableAction);
            }
            console.log("actions", this.availableActions);
            
            if(this.selected.size == 1) {
                for(action of actionsSet) {
                    this.addToolbarAction(action);
                }
            } else {
                for (const action of this.availableActions) {
                    if(!actionsSet.has(action)) {
                        this.removeToolbarAction(action);
                    }
                }
            }

        };
        this.unselect = function(item) {
            item.classList.remove("selected");
            this.selected.delete(item);

            if(mdlio.selectable.selected.size == 0) {
                this.stopSelection();
            }
        };

        const actionsHandlers = {}
        this.action = function(key, fn) {
            actionsHandlers[key] = function(items) {items.forEach(fn)};
        };

        this.batchAction = function(key, fn) {
            actionsHandlers[key] = fn;
        };

        this.actionClickHandler = function(ev) {
            var action = this.dataset.action;
            console.log("Invoking action", action, ev);
            var handler = actionsHandlers[action];
            if(handler) {
                handler(Array.from(selected));
            }
            
            
        }

        this.upgrade = function(item) {
            var items=[];
            if (item.matches(".selectable")) {
                items=[item];
            } else {
                items=item.querySelectorAll(".selectable")
            }

            items.forEach(function(item) {

                var selectButton = item.querySelector('.action.select');
                if(!selectButton) {
                    selectButton = document.createElement("button");
                    selectButton.classList.add("mdl-button","mdl-button--icon");
                    selectButton.classList.add("action","select");
                    selectButton.innerHTML='<i class="material-icons">check</i>';
                    item.appendChild(selectButton);
                }

                selectButton.addEventListener("click", function(e) {
                    e.preventDefault();
                    if(item.classList.contains("selected")) {
                        mdlio.selectable.unselect(item);
                    } else {
                        mdlio.selectable.select(item);
                    }

                });   

            })

        };

    })()
};

mdlio.upgrade.upgraders.push(mdlio.cards);
mdlio.upgrade.upgraders.push(mdlio.forms);
mdlio.upgrade.upgraders.push(mdlio.selectable);


Element.prototype.findParentBySelector = function(selector) {
    console.log(this);
    var cur = this.parentNode;
    while (cur && !cur.matches(selector)) {
        //keep going up until you find a match
        cur = cur.parentNode;
        //go up
    }
    return cur;
    //will return null if not found
}
,
window.addEventListener('load', function() {
    mdlio.upgrade.initial();
});
window.addEventListener('load', function() {
    console.log("Content-loaded");
});
