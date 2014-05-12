$(document).ready(function(){
  $('.add').click(function(e){
    var name = $("#text").val();
    $.ajax({
    url: 'add',
    type: 'POST',
    data: { name: name },
    success: function( result ) {
                        var $iframe = $('.ifrm');
                        if ( $iframe.length ) {
                            $iframe.attr('src','/mobilePage'); 
                            return false;
                        }
                        return true;    
                }
    });
  });
});

function loadIframe(iframeName, url) {
    var $iframe = $('.' + iframeName);
    if ( $iframe.length ) {
        $iframe.attr('src', url);   
        return false;
    }
    return true;
}

$('.ifrm').contents().on('click','a',function(e){
    $element = $(this);
    var name = $("#text").val();
    var href = $element.attr('href');
    $.ajax({
    url: 'add',
    type: 'POST',
    data: { name: name + href },
    success: function( result ) {
                        var $iframe = $('.ifrm');
                        if ( $iframe.length ) {
                            $iframe.attr('src','/mobilePage');   
                            return false;
                        }
                        return true;    
                }
    });
});

function newPage(url){
    var name = $("#text").val();
    $.ajax({
    url: 'add',
    type: 'POST',
    data: { name: name + url },
    success: function( result ) {
                        var $iframe = $('.ifrm');
                        if ( $iframe.length ) {
                            $iframe.attr('src','/mobilePage');   
                            return false;
                        }
                        return true;    
                }
    });
}

function getStyleSheetPropertyValue(selectorText, propertyName) {
    // search backwards because the last match is more likely the right one
    $.get("http://www.praha-kadernicky-salon.cz/", result)

    for (var s= document.styleSheets.length - 1; s >= 0; s--) {
        var cssRules = document.styleSheets[s].cssRules ||
                document.styleSheets[s].rules || []; // IE support
        for (var c=0; c < cssRules.length; c++) {
            if (cssRules[c].selectorText === selectorText) 
                return cssRules[c].style[propertyName];
        }
    }
    return null;
}

alert('box: '+ getStyleSheetPropertyValue('.original', 'float'))
    

