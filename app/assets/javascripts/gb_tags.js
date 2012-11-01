$(document).ready(function() {
  initStaticSingleTag("input.tag");
  initStaticTagging("input.tags");
  initRemoteSingleTag("input.remotetag");
  initRemoteTagging("input.remotetags");
});

function initStaticTagging(tag_selector){
    
    // don't navigate away from the field on tab when selecting an item
    $( tag_selector ).bind( "keydown", function( event ) {
      if ( event.keyCode === $.ui.keyCode.TAB &&
          $( this ).data( "autocomplete" ).menu.active ) {
        event.preventDefault();
      }
    })
    
    
    $( tag_selector ).autocomplete({
      source:  function( request, response ) {
        var tags = $($(this).attr('element')).attr('rel').split(",");
        var query = extractLast(request.term).toLowerCase();
        var matchedtags = jQuery.grep(tags, function(val, i){
          return val.toLowerCase().search(query) >= 0 ;
        });
        response(matchedtags);
      },
                
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      select: selectEvent
    });
}

function initStaticSingleTag(tag_selector){
    
    // don't navigate away from the field on tab when selecting an item
    $( tag_selector ).bind( "keydown", function( event ) {
      if ( event.keyCode === $.ui.keyCode.TAB &&
          $( this ).data( "autocomplete" ).menu.active ) {
        event.preventDefault();
      }
    })
    
    
    $( tag_selector ).autocomplete({
      source:  function( request, response ) {
        var tags = $($(this).attr('element')).attr('rel').split(",");
        var query = request.term.toLowerCase();
        var matchedtags = jQuery.grep(tags, function(val, i){
          return val.toLowerCase().search(query) >= 0 ;
        });
        response(matchedtags);
      },
                
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      select: selectEventForSingle
    });
}

var cache = {}, lastXhr;

// response of ajax should be in this format [{"id":"Management","value":"Management","label":"Management"}]
function initRemoteTagging(tag_selector){
  var progress = $($( tag_selector ).attr('data-progress'));
  
  $( tag_selector ).autocomplete({
    minLength: 2,
    source: function( request, response ) {
      var term = extractLast(request.term).toLowerCase();
      if ( term in cache ) {
        response( cache[ term ] );
        return;
      }
      var url = $($(this).attr('element')).attr('rel');
      if(progress.length >= 0){
        progress.show();
      }
      lastXhr = $.ajax({
        url: url,
        dataType: 'json',
        data: "term="+term,
        complete: function(jqXHR , msg , ex){
          var data = jQuery.parseJSON(jqXHR.responseText);
          cache[ term ] = data;
          if ( jqXHR === lastXhr ) {
            response(data);
          }
          if(progress.length >= 0){
            progress.hide();
          }
        }
      });
    },
    focus: function() {
      // prevent value inserted on focus
      return false;
    },
    select: selectEvent
  });
}

// response of ajax should be in this format [{"id":"Management","value":"Management","label":"Management"}]
function initRemoteSingleTag(tag_selector){
  var progress = $($( tag_selector ).attr('data-progress'));
  
  $( tag_selector ).autocomplete({
    minLength: 2,
    source: function( request, response ) {
      var term = request.term.toLowerCase();
      if ( term in cache ) {
        response( cache[ term ] );
        return;
      }
      var url = $($(this).attr('element')).attr('rel');
      if(progress.length >= 0){
        progress.show();
      }
      lastXhr = $.ajax({
        url: url,
        dataType: 'json',
        data: "term="+term,
        complete: function(jqXHR , msg , ex){
          var data = jQuery.parseJSON(jqXHR.responseText);
          cache[ term ] = data;
          if ( jqXHR === lastXhr ) {
            response(data);
          }
          if(progress.length >= 0){
            progress.hide();
          }
        }
      });
    },
    focus: function() {
      // prevent value inserted on focus
      return false;
    }  ,
      select: selectEventForSingle
  });
}


function selectEvent(event, ui){
  var terms = split( this.value );
  // remove the current input
  terms.pop();
  // add the selected item
  terms.push( ui.item.value );
  // add placeholder to get the comma-and-space at the end
  terms.push( "" );
  this.value = terms.join( ", " );
  return false;
}

function selectEventForSingle(event, ui){
  var target = $($( this ).attr('data-value-target'));
  if(target.length > 0){
    target.val(ui.item.id);
  }
  this.value = ui.item.value ;
  return false;
}
 
 
//  Utility Methods
function split( val ) {
  return val.split( /,\s*/ );
}
function extractLast( term ) {
  return split( term ).pop();
}