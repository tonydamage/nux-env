window.mdlio = {

  outlayer: function (outlayer) {
    this.outlayers = [];
    if (outlayer) {
      if(Array.isArray(outlayer)) {
        for (var e of outlayer) {
          this.outlayers.push(e);
        }
      } else {
        this.outlayers.push(outlayer);
      }
    }
    this.add = function (outlayer) {
        this.outlayers.push(outlayer);
    };
    this.appended = function (items) {
      for (outlayer of this.outlayers) {
        outlayer.appended(items);
      }
    };
  },

  lightbox: function (grid, selector, options) {
    var pswpElement = document.querySelectorAll('.pswp')[0];
    if (pswpElement == null) {
      pswpElement = mdlio.addPSWP();
    }
    /*this.box = $(grid).find(selector).simpleLightbox(options); */
    var items = [];

    this.items = items;

    const linkClicked = function (e) {
      console.log(this, this.lboxId);
      e.preventDefault();
      var options = {
        index: this.lboxId
      };
      var gallery = new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, items, options);
      gallery.init();
    };

    this.appended = function (appendedItems) {
      //this.box.destroy();
      for (var item of appendedItems) {
        var link = item.querySelector(selector);
        if (link == null) {
          continue;
        }
        var img = link.querySelector('img');

        var width = img.naturalWidth;
        var height = img.naturalHeight;

        var maybeSize = link.getAttribute('data-img-size');
        if (maybeSize) {
          console.log(maybeSize);

          [width, height] = maybeSize.split('x').map(function (x) { return Number.parseInt(x); });
        }

        var slide = {
          msrc: img.getAttribute('src'),
          src: link.getAttribute('href'),
          w: width,
          h: height
        };
        console.log(slide);
        var slideId=items.push(slide)-1;


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

  infiniteScroll: function (grid, item, nextPage, outlayer) {
    var outlayers = new mdlio.outlayer(outlayer);
    var infScroll = new InfiniteScroll( grid, {
      path: nextPage,
      hideNav: nextPage,
      append: item,
      outlayer: outlayers,
      status: '.page-load-status',
      scrollThresold: 100,
      prefill: true
      //elementScroll: '.mdl-layout__content',
    });
    infScroll.outlayers = outlayers;
    return infScroll;
  },

  cardsGallery: function(grid, item, lightboxItem) {
    const lightbox = new mdlio.lightbox(grid,lightboxItem+" a");
    const msnry = new Masonry( grid, {
      itemSelector: 'none', // select none at first
      columnWidth: document.querySelector('#gutter'),
      gutter: 0,
      containerStyle: {
        width: 'calc(100% - 16px)',
        padding: '0px',
        position: 'relative'
      },
      percentPosition: true,
      // nicer reveal transition
      visibleStyle: { transform: 'translateY(0)', opacity: 1 },
      hiddenStyle: { transform: 'translateY(100px)', opacity: 0 },
    });
    this.lightbox = lightbox;
    this.masonry = msnry;

    imagesLoaded( grid, function() {
      grid.classList.remove('are-images-unloaded');
      msnry.options.itemSelector = item;
      var items = grid.querySelectorAll(item);
      lightbox.appended( items);
      msnry.appended( items );
    });
    if(document.querySelector(".next-page")) {
      this.infiniteScroll = new mdlio.infiniteScroll(grid,item,'.next-page',[msnry,this.lightbox]);
    }
  },

  addPSWP: function () {
    var body = document.querySelector('body');
    var pswp = document.createElement('div');
    pswp.classList.add('pswp');
    pswp.innerHTML=`<!-- Background of PhotoSwipe.
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

    </div>`
    body.appendChild(pswp);
    return pswp;
  }

};
