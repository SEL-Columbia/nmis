//jQuery.inDom() is a shortcut for jQuery(elem).closest('html').length !== 0
// jQuery.fn.inDom = function(){ return jQuery(this).closest("html").length !== 0; };

(function($){
  $.fn.inDom = function(){
    var h = $(this).closest("html");
    if (h.length === 0) {
      return false;
    } else if(h[0] === document.documentElement) {
      // closest html element should be the same as document.documentElement
      return true;
    } else if($('html').get(0) === h.get(0)) {
      // in case document.documentElement is not supported.
      return true;
    }
    // if the closest 'html' is not the one in the dom.
    return false;
  }
})(jQuery);
