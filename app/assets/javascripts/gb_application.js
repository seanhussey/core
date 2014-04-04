var editingInProgress = false;
var changedSinceLastAutoSave = false;

$(document).ready(function() {
  dragTreeManager.init();
  initNestable();
  initClickEventsForAssetLinks($("body"));
  initSlugManagement();
  initBetterSlugManagement();
  initSettingDropdownAjax();
  initPublishedDateTime();
  initBulkDeleteAsset();
  initGluttonbergUI();
  initFormValidation();
  setUpAudio();
  WarnNavigateAway.init();
  AutoSave.init();
  $(".chzn-select").chosen();
  initPublishingButton();
  initPreview();
  shortcodeNameValidation();
});

/*
  General UI fixes.
*/
function initGluttonbergUI(){
  if ($('table').length > 0) {
    $('table').find('tr:last').css('background-image', 'none !important');
  }
  if( $('.page_flash').length > 0){
    if($(".model-error").length > 0){
      $('.page_flash').remove();
    }else{
      $('.page_flash').insertBefore(".page-header");
    }
  }

  $("ul.nav a.active").each(function(){
    $(this).parent("li").addClass('active');
  });
}

function initFormValidation(){
  $("form.validation").validate();
}



// Initalize a tags for asset selector and remove button
// It also handles autosave mode of asset selector
function initClickEventsForAssetLinks(element) {
  element.find(".thumbnails a.choose_button").click(function(e) {
    var p = $(this).parent().parent().parent(".asset_selector_wrapper");
    var link = $(this);
    AssetBrowser.showOverlay();
    $.get(link.attr("href"), null, function(markup) {
      AssetBrowser.load(p, link, markup);
    });
    e.preventDefault();
  });

  element.find(".thumbnails a.remove").click(function(e) {
    var p = $(this).parent().parent().parent(".asset_selector_wrapper");
    var link = $(this);
    var parent = link.parents(".thumbnails");
    parent.find('.choose_asset_hidden_field').val('');
    parent.find('h5').html('');
    parent.find('img').remove();
    if(!blank(link.attr('data_url'))){
      $.ajax({
        url: link.attr('data_url'),
        data: 'gluttonberg_setting[value]=',
        type: "PUT",
        success: function(data) {}
      });
    }else{
      changedSinceLastAutoSave = true;
    }

    e.preventDefault();
  });

}

/*
  All functioanlity for asset selector
  Listing, searching, ajax upload, auto save, inserting image in redactor, filters
*/
var AssetBrowser = {
  overlay: null,
  dialog: null,
  imageDisplay: null,
  Wysiwyg: null,
  logo_setting: false,
  filter: null,
  filter_value: null,
  actualLink: null,
  link_parent: null,
  load: function(p, link, markup, Wysiwyg) {
    AssetBrowser.link_parent = p;
    AssetBrowser.actualLink = link;
    // it is required for asset selector in jWysiwyg
    AssetBrowser.Wysiwyg = null;
    if (Wysiwyg != undefined) {
      AssetBrowser.Wysiwyg = Wysiwyg;
    }
    // its used for category filtering on assets and collections
    AssetBrowser.filter = $("#filter_" + $(link).attr("rel"));
    if(!blank(link)){
      AssetBrowser.filter_value = getParameterByName(link.attr('href'), "filter");
      if(!blank(AssetBrowser.filter_value) && !blank(AssetBrowser.filter)){
        AssetBrowser.filter_value = AssetBrowser.filter.val();
      }
    }

    if ($(link).is(".logo_setting")) {
      AssetBrowser.logo_setting = true;
      AssetBrowser.logo_setting_url = $(link).attr("data_url");
    } else {
      AssetBrowser.logo_setting = false;
      AssetBrowser.logo_setting_url = "";
    }
    // Set everthing up
    AssetBrowser.showOverlay();
    $("body").append(markup);
    AssetBrowser.browser = $("#assetsDialog");
    try {
      AssetBrowser.target = $("#" + $(link).attr("rel"));
      AssetBrowser.imageDisplay = $("#image_" + $(link).attr("rel"));
      AssetBrowser.nameDisplay = $("#show_" + $(link).attr("rel"));
      if (AssetBrowser.nameDisplay !== null) {
        AssetBrowser.nameDisplay = p.find("h5");
      }
    } catch(e) {
      AssetBrowser.target = null;
      AssetBrowser.nameDisplay = p.find("h5");
    }

    threeSixtyPlayer.init();

    // Grab the various nodes we need
    AssetBrowser.display = AssetBrowser.browser.find("#assetsDisplay");
    AssetBrowser.offsets = AssetBrowser.browser.find("> *:not(#assetsDisplay)");
    // Calculate the offsets
    AssetBrowser.offsetHeight = 0;
    AssetBrowser.offsets.each(function(i, element) {
      AssetBrowser.offsetHeight += $(element).outerHeight();
    });
    // Initialize
    AssetBrowser.resizeDisplay();
    $(window).resize(AssetBrowser.resizeDisplay);
    // Cancel button
    AssetBrowser.browser.find(".cancel").click(AssetBrowser.close);
    // Capture anchor clicks
    AssetBrowser.display.find("a").click(AssetBrowser.click);
    // Capture size selector change
    AssetBrowser.display.find("select.size_selector").change(AssetBrowser.sizeSelectHandler);

    $("#assetsDialog form#asset_search_form").submit(AssetBrowser.search_submit);
    $("#assetsDialog #asset_date_filter").blur(AssetBrowser.date_filter);
    $("#assetsDialog #asset_date_filter").change(AssetBrowser.date_filter);
    $("#assetsDialog #asset_date_filter").bsdatepicker();

    AssetBrowser.browser.find("#ajax_new_asset_form").submit(function(e) {
      if($("#ajax_new_asset_form #ajax_asset_file").val() != null && $("#ajax_new_asset_form #asset_name").val() != null && $("#ajax_new_asset_form #ajax_asset_file").val() != "" && $("#ajax_new_asset_form #asset_name").val() != ""){
        $("#ajax_new_asset_form").addClass('uploading');
        ajaxFileUploadForAssetLibrary(link);
      }
      e.preventDefault();
    });

    // same height for all elements within same row
    $.each(AssetBrowser.browser.find(".tab-pane") , function(index , element){
      AssetBrowser.sameHeightForAllElementsOfSameRow($(element));
    });

    try{
      $().collapse({parent: "#accordion_for_collections"});
    }catch(e){}

    try {
      $("#assetsDialog form#ajax_new_asset_form").validate();
    } catch(e) {}

  },
  sameHeightForAllElementsOfSameRow: function(parent_element){

    var all_spans = parent_element.find(".thumbnails .span3");
    var row_num = 1;
    var ASSET_MAX_COLUMNS = 5;
    var row_max_height = 0;
    $.each(all_spans , function(index , element){
      if($(element).height() > row_max_height){
        row_max_height = $(element).height();
      }
      if(row_max_height < 210){
        row_max_height = 210;
      }

      $(element).attr('data-row' , row_num);
      if( (index+1) % ASSET_MAX_COLUMNS == 0 ){
        if(row_max_height > 0){
          parent_element.find("[data-row="+row_num+"]").height(row_max_height);
        }
        row_num++;
        row_max_height = 0;
      }
    });
  },
  resizeDisplay: function() {
    $("#assetsDialog").css({
      height: ($(window).height()*0.9) + "px",
      width: ($(window).width()*0.7) + "px",
      "margin-top": "-" + (($(window).height()*0.9)/2) + "px",
      "margin-left": "-" + (($(window).width()*0.7)/2) + "px"
    });

    $(".modal-body").css({
      "max-height": (($(window).height()*0.9) - 135) + "px",
      "height": (($(window).height()*0.9) - 135) + "px"
    });
  },
  showOverlay: function() {
    AssetBrowser.overlay = $("#assetsDialogOverlay");
    if (!AssetBrowser.overlay || AssetBrowser.overlay.length == 0) {
      var height = $('#wrapper').height() + 50;
      AssetBrowser.overlay = $('<div id="assetsDialogOverlay" class="modal-backdrop"><div class="progress progress-striped active"><div class="bar" style="width: 100%;"></div></div></div>');
      $("body").append(AssetBrowser.overlay);
    } else {
      AssetBrowser.overlay.css({
        display: "block"
      });
    }
    set_height = wrapper_height = $("body").height();
    window_height = $(window).height() + $(window).scrollTop();
    if (set_height < window_height)
      set_height = window_height;
    $("#assetsDialogOverlay").height(set_height);
  },
  close: function() {
    AssetBrowser.overlay.css({
      display: "none"
    });
    AssetBrowser.browser.remove();

    if(threeSixtyPlayer != null){
      try{
        threeSixtyPlayer.stopSound(threeSixtyPlayer.lastSound);
      }catch(e){}
    }

  },
  handleJSON: function(json) {
    AssetBrowser.updateDisplay(json.markup);
  },
  updateDisplay: function(markup) {
    AssetBrowser.display.html(markup);
    AssetBrowser.display.find("a").click(AssetBrowser.click);

    try {
      $("#assetsDialog form#ajax_new_asset_form").validate();
    } catch(ex) {}
    AssetBrowser.browser.find("#ajax_new_asset_form").submit(function(e) {
      if($("#ajax_new_asset_form #ajax_asset_file").val() != null && $("#ajax_new_asset_form #asset_name").val() != null && $("#ajax_new_asset_form #ajax_asset_file").val() != "" && $("#ajax_new_asset_form #asset_name").val() != ""){
        ajaxFileUpload(AssetBrowser.actualLink);
      }
      e.preventDefault();
    });
  },
  search_submit: function(e) {
    $("#progress_ajax_upload").ajaxStart(function() {
      $(this).show();
    }).ajaxComplete(function() {
      $(this).hide();
    });
    var url = $("#assetsDialog form#asset_search_form").attr("action");
    url += ".json?" + $("#assetsDialog form#asset_search_form").serialize();
    $.getJSON(url, null, function(json){
      $("#search_tab_results").html(json.markup);
      $("#search_tab_results").find("a").click(AssetBrowser.click);
    });
    e.preventDefault();
  },
  date_filter: function(e){
    console.log($(this).val());
    var dateTokens = $(this).val().split("/");
    console.log(dateTokens)
    if(dateTokens.length == 3){
      var day = parseInt(dateTokens[0]);
      var month = parseInt(dateTokens[1]);
      var year = parseInt(dateTokens[2]);
      if(day > 0 && day <= 31 && month > 0 && month <= 12 && year > 1971 && year <= 2050){
        var date = new Date(year,month-1, day); 
        var formattedDate = year + "-" + month + "-" + day;
        console.log(date);

        var serverDateFormat = "";

        $("#progress_ajax_upload").ajaxStart(function() {
          $(this).show();
        }).ajaxComplete(function() {
          $(this).hide();
        });
        var url = "/admin/filter_assets_by_date.json?asset_date_filter=" + formattedDate;
        $.getJSON(url, null, function(json){
          $("#search_tab_results").html(json.markup);
          $("#search_tab_results").find("a").click(AssetBrowser.click);
        });
      }

    }
    

    e.preventDefault();
  },
  sizeSelectHandler: function(){
    var target = $(this);
    var image_url = target.val();
    var file_title = target.attr("data-title");
    insertImageInWysiwyg(image_url,"image",file_title);
    AssetBrowser.close();
  },
  click: function() {
    var target = $(this);
    if (target.is(".assetLink")) {
      var id = target.attr("href").match(/\d+$/);
      var name = target.attr("data-title");

      // assets only
      if (AssetBrowser.target !== null) {
        AssetBrowser.actualLink.parents(".caption").find(".choose_asset_hidden_field").attr("value", id);
        AssetBrowser.actualLink.parents(".caption").find(".choose_asset_hidden_field").trigger( "selected", [target.attr("data-title"), target.attr("data-credits")] );
        var image_src = target.attr("data-thumb");

        image_url = target.attr("data-jwysiwyg");
        file_type = target.attr("data-category");
        file_title = name;
        insertImageInWysiwyg(image_url,file_type,file_title);

        AssetBrowser.nameDisplay.html(name);

        if(file_type == "image"){
          if (AssetBrowser.link_parent.find("img").length > 0) {
            AssetBrowser.link_parent.find("img").attr('src', image_src);
          } else {
            AssetBrowser.link_parent.prepend("<img src='" + image_src + "' />");
          }
        }else if(file_type == "video"){
          if (AssetBrowser.link_parent.find("img").length > 0) {
            AssetBrowser.link_parent.find("img").attr('src', image_src);
          } else {
            AssetBrowser.link_parent.prepend("<img src='" + image_src + "' />");
          }
        }else if(file_type == "audio"){
          if (AssetBrowser.link_parent.find("div.ui360 a").length > 0) {
            AssetBrowser.link_parent.find("div.ui360 a").attr('href', image_url);
            AssetBrowser.link_parent.find("div.ui360 a").text(name);
          } else {
            AssetBrowser.link_parent.prepend("<div class='ui360'><a href='" + image_url + "' >"+name+"</a><div>");
            threeSixtyPlayer.init();
            AssetBrowser.nameDisplay.html('');
          }
        }
        changedSinceLastAutoSave = true;
        autoSaveAsset(AssetBrowser.logo_setting_url, id); //auto save if it is required
      } else {

      }

      AssetBrowser.close();
    } else if (target.parent().is(".pagination")) {
      if (target.attr("href") != '') {
        $.getJSON(target.attr("href"), null, AssetBrowser.handleJSON);
      }
    } else if(target.is(".accordion-toggle")){
      var accordionContent = $(target.attr('href'));
      var accordionContentInner = accordionContent.find(".accordion-inner");
      var collectionID = accordionContentInner.attr('data-id');

      if(accordionContentInner.attr("content-loaded") == "false"){
        accordionContentInner.prepend("<img src='/assets/gb_spinner.gif' class='gb_spinner'/>");
        $.get("/admin/browser-collection/"+collectionID+".json?filter="+AssetBrowser.filter_value, function(data){
          $(".gb_spinner").remove();
          accordionContentInner.prepend(data['markup']);
          accordionContentInner.find("a").click(AssetBrowser.click);
        });
        accordionContentInner.attr("content-loaded",true);
      }

      return true;
    } else if(target.is(".no-ajax")){
      return true;
    }
     else if (!target.is(".tab_link")) {
      $("#progress_ajax_upload").ajaxStart(function() {
        $(this).show();
      }).ajaxComplete(function() {
        $(this).hide();
      });

      var url = target.attr("href") + ".json";
      // its collection url then add category filter for filtering assets
      if (target.hasClass("collection")) {
        url += "?filter=" + AssetBrowser.filter_value;
      }
      $.getJSON(url, null, AssetBrowser.handleJSON);
    }
    return false;
  }

};


function insertImageInWysiwyg(image_url,file_type,title) {
  if (AssetBrowser.Wysiwyg != undefined && AssetBrowser.Wysiwyg !== null) {
    Wysiwyg = AssetBrowser.Wysiwyg;
    if(file_type == undefined){
      file_type = "";
    }
    if(title == undefined){
      title = "";
    }
    Wysiwyg.selectionRestore();
    if(!blank(Wysiwyg.getSelectionText())){
      title = Wysiwyg.getSelectionText();
    }
    description = "";
    style = "";
    if(file_type == "image" && !AssetBrowser.actualLink.hasClass("attach")){
      image = "<img src='" + image_url + "' title='" + title + "' alt='" + description + "'" + style + "/>";
    }else{
      image = "<a href='"+image_url+"' target='_blank' >"+title+"</a>";
    }
    Wysiwyg.insertHtml(image);
  }

}


function autoSaveAsset(url, new_id) {
  // HACK FOR LOGO SETTINGS
  if (AssetBrowser.logo_setting != undefined && AssetBrowser.logo_setting != null && AssetBrowser.logo_setting == true) {
    new_value = new_id;

    $.ajax({
      url: url,
      data: 'gluttonberg_setting[value]=' + new_value,
      type: "PUT",
      success: function(data) {}
    });
  }
}



/* Setup settings page */

function initSettingDropdownAjax() {
  $(".setting_dropdown").change(function() {
    url = $(this).attr("rel");
    id = $(this).attr("data_id");
    new_value = $(this).val();
    $("#progress_" + id).show("fast");

    $.ajax({
      url: url,
      data: 'gluttonberg_setting[value]=' + new_value,
      type: "PUT",
      success: function(data) {
        $("#progress_" + id).hide("fast");
        WarnNavigateAway.removeEventHandler();
      }
    });

  });
  initHomePageSettingDropdownAjax();
}

/* Home page dropdown setting is special case on settings page in backend, it is handled by 
  a seperate ajax call.
*/
function initHomePageSettingDropdownAjax() {
  $(".home_page_setting_dropdown").change(function() {
    url = $(this).attr("rel");
    id = "home_page";
    new_value = $(this).val();
    $("#progress_" + id).show("fast");
    $.ajax({
      url: url,
      data: 'home=' + new_value,
      type: "POST",
      success: function(data) {
        $("#progress_" + id).hide("fast");
        WarnNavigateAway.removeEventHandler();
      }
    });

  });
}


/* Setup Ajax file upload */

function ajaxFileUploadForAssetLibrary(link) {
  //starting setting some animation when the ajax starts and completes
  $("#loading").ajaxStart(function() {
    $(this).show();
  }).ajaxComplete(function() {
    $(this).hide();
  });
  link = $(link);

  asset_name = $('#ajax_new_asset_form input[name$="asset[name]"]').val();
  var formData = {
    "asset[name]": asset_name,
    "asset[asset_collection_ids]": $("#ajax_new_asset_form #asset_asset_collection_ids").val(),
    "new_collection[new_collection_name]": $('#ajax_new_asset_form input[name$="new_collection[new_collection_name]"]').val()
  };

  /*
    prepareing ajax file upload
    url: the url of script file handling the uploaded files
                fileElementId: the file type of input element id and it will be the index of  $_FILES Array()
    dataType: it support json, xml
    secureuri:use secure protocol
    success: call back function when the ajax complete
    error: callback function when the ajax failed

  */
  $.ajaxFileUpload({
    url: '/admin/add_asset_using_ajax',
    secureuri: false,
    fileElementId: 'ajax_asset_file',
    dataType: 'json',
    data: formData,
    success: function(data, status) {
      if (typeof(data.error) != 'undefined') {
        if (data.error != '') {
          //console.log(data.error);
        } else {
          //console.log(data.msg);
        }
      }


      new_id = data["asset_id"];
      file_path = data["url"];
      jwysiwyg_image = data["jwysiwyg_image"];

      try{
        AssetBrowser.target.attr("value", new_id);
        AssetBrowser.nameDisplay.html(asset_name);
        if (AssetBrowser.link_parent.find("img").length > 0) {
          AssetBrowser.link_parent.find("img").attr('src', file_path);
        } else {
          AssetBrowser.link_parent.prepend("<img src='" + file_path + "' />");
        }
      }catch(e){}
      if(data["category"] == "image")
        insertImageInWysiwyg(jwysiwyg_image,data["category"],data["title"]);
      else
        insertImageInWysiwyg(file_path,data["category"],data["title"]);

      data_id = $(this).attr("data_id");
      url = AssetBrowser.logo_setting_url;
      autoSaveAsset(url, new_id); // only if autosave is required

      AssetBrowser.close();
    },
    error: function(data, status, e) {
      console.log(data);
      console.log(e);
    }
  });

  $(".ajax-upload-progress").show();
  window.setTimeout(function(){
    $("#ajax_asset_file").blur();
  }, 10);

  return false;

}

/* Setup jcrop - image cropping library for asset library */

function initJcrop(image_type, w, h) {
  var ratio = w/(h*1.0);
  $('#' + image_type + "_image").Jcrop({
    aspectRatio: ratio,
    onSelect: function(c) {
      $('#' + image_type + '_x').val(c.x);
      $('#' + image_type + '_y').val(c.y);
      $('#' + image_type + '_w').val(c.w);
      $('#' + image_type + '_h').val(c.h);
    },
    setSelect: [0, 0, w, h],
    minSize: [w, h]
  });
}



/* Setup publish date and time fields */

function initPublishedDateTime() {
  $(".publishing_state").change(function(){
    updatePublishedDateField();
  });

  function updatePublishedDateField(){
    if($(".publishing_state").val()=="published"){
      $(".published_at").show();
    }else{
      $(".published_at").hide();
    }
  }
  updatePublishedDateField();
}


/* Setup Bulk actions for asset library */

var selected_assets_ids = [];
function initBulkDeleteAsset(){
  $(".delete_selected_assets").hide();
  $(".select_asset_checkbox").click(function(e){
    if($(this).is(':checked')){
      selected_assets_ids.push($(this).attr("rel"));
      $(".delete_selected_assets").show();
    }else{
      selected_assets_ids.remove($(this).attr("rel"));
      if(selected_assets_ids.length <= 0){
        $(".delete_selected_assets").hide();
      }
    }
  });

  $(".select_all_assets").click(function(e){
    var status = $(".select_all_assets").is(':checked');
    $(".select_asset_checkbox").attr('checked', status);
    selected_assets_ids = [];
    if($(".select_all_assets").is(':checked')){
      $(".select_asset_checkbox").each(function(){
        selected_assets_ids.push($(this).attr("rel"));
      });
      $(".delete_selected_assets").show();
    }else{
      selected_assets_ids = [];
      $(".delete_selected_assets").hide();
    }
  });

  $(".delete_selected_assets").click(function(e){
    if(selected_assets_ids == null || selected_assets_ids.length <= 0){
      alert("Please select at least one asset.");
    }else{
      var answer = confirm("Are you sure to delete all selected assets?");
      if(answer){
        $("form#delete_selected_assets_form input").val(selected_assets_ids);
        $("form#delete_selected_assets_form").submit();
      }
    }

  });
}


/* Setup Audio */

function setUpAudio(){
  soundManager.setup({
    useFlashBlock: true, // optional - if used, required flashblock.css
    url: '/assets/gb_swf/', // required: path to directory containing SM2 SWF files
    debugMode: true
  });
}

function stopAudio(){
  if(!blank(basicMP3Player) && basicMP3Player.lastSound !== null){
    basicMP3Player.stopSound(basicMP3Player.lastSound);
  }
}

function initCollectionAccordion(){
  $(".collapse").collapse({parent: "#accordion_for_collections"});
  $(".accordion-heading a").click(function(e){
    var target = $(this);
    var accordionContent = $(target.attr('href'));
      var accordionContentInner = accordionContent.find(".accordion-inner");
      var collectionID = accordionContentInner.attr('data-id');

      if(accordionContentInner.attr("content-loaded") == "false"){
        accordionContentInner.prepend("<img src='/assets/gb_spinner.gif' class='gb_spinner'/>");
        $.get("/admin/browser-collection/"+collectionID+".json?open_link=true", function(data){
          $(".gb_spinner").remove();
          accordionContentInner.prepend(data['markup']);
        });
        accordionContentInner.attr("content-loaded",true);
      }
    });
}



/* Redactor wysiwyg Setup and its plugins */
var linkCount = 0;
function enableRedactor(selector, _linkCount) {
  $(document).ready(function() {
    linkCount = _linkCount;
    $(selector).redactor({
      linkEmail: true,
      linkAnchor: true,
      minHeight: 200,
      autoresize: false,
      buttons: ['formatting', '|', 'bold',
        'italic', 'underline',  '|', 'alignment', '|',
        'unorderedlist', 'orderedlist',
        'outdent', 'indent', '|', 'video',
        'table', '|', 'html', '|', 'fullscreen'
      ],
      plugins: ['asset_library_image', 'gluttonberg_embeds', 'gluttonberg_pages', 'fullscreen'],
      keyupCallback : function(){
        WarnNavigateAway.changeEventHandler();
        AutoSave.changeEventHandler();
      }
    });

  });
}



/* Setup Slug management */
function initBetterSlugManagement() {
  var str = $('#page_slug_holder .domain').html();
  var pt = $('#page_title');
  var pb = $('#page_slug .edit');
  var ps = $('#page_slug span');
  var hs = $('#page_hidden_slug');
  var regex = /[\!\*'"″′‟‛„‚”“”˝\(\);:.@&=+$,\/?%#\[\]]/gim;
  var doNotEdit = ps.attr('donotedit');
  var editPage = false;
  var slugLength = 0;
  var slug = "";
  var currentSlug = "";

  if (typeof doNotEdit == 'string') {
    doNotEdit = true;
    editPage = true;
  } else {
    doNotEdit = false;
  }

  if(pt.length > 0 && ps.length > 0 && hs.length > 0 ){

    $('#page_slug_holder .domain').html($.trim(str));

    pt.keyup(function(){
      if (!doNotEdit) {
        slug = pt.val().toLowerCase().replace(/\s/gim, '-').replace(regex, '');
        ps.html(slug);
        hs.val(slug);
      }
    });

    pb.click(function(){
      hs.show();
      ps.hide();
      pb.hide();
      hs.focus();
      doNotEdit = true;
      slugLength = hs.val().length;
      currentSlug = hs.val();
    });

    hs.focusout(function(){
      var len = hs.val().length;
      if (doNotEdit) {
        if (len == 0) {
          hs.hide();
          ps.show();
          pb.show();
          if (!editPage) {
            doNotEdit = false;
            slug = pt.val().toLowerCase().replace(/\s/gim, '_').replace(regex, '');
            ps.html(slug);
            hs.val(slug);
          } else {
            hs.val(currentSlug);
          }
        } else {
          hs.hide();
          ps.show();
          pb.show();
          ps.html(hs.val().toLowerCase().replace(/\s/gim, '_').replace(regex, ''));
          doNotEdit = true;
        }
      }
    });
  }

}


// This method initialize slug related event on a title text box.
function initSlugManagement() {
  try {
    var pt = $('#page_title');
    var ps = $('#page_slug');
    var donotmodify = (ps.attr('donotmodify') == 'true') || ps.val().length > 1;

    if(pt.length > 0 && ps.length > 0 ){
      var regex = /[\!\*'"″′‟‛„‚”“”˝\(\);:.@&=+$,\/?%#\[\]]/gim;
      var pt_function = function() {
        if (!donotmodify)
          ps.val(pt.val().toLowerCase().replace(/\s/gim, '-').replace(regex, ''));
      };

      pt.bind("keyup", pt_function);
      pt.bind("blur", pt_function);

      ps.bind("blur", function() {
        ps.val(ps.val().toLowerCase().replace(/\s/gim, '-').replace(regex, ''));
        ps.attr('donotmodify', 'true');
      });
    }
  } catch(e) {}
}

function enable_slug_management_on(src_class){
  $("."+src_class).attr('id','page_title');
}
/*
  Nestable is used for reordering pages. 
*/

function initNestable(){
  window.nestableSerializedDataOnPageLoad = [];
  $(".collapse_all").click(function(e){
    $.get("/admin/pages/collapse_all", function( data ) {
    });
    $('.dd').nestable('collapseAll');
    e.preventDefault();
  });

  $(".expand_all").click(function(e){
    $.get("/admin/pages/expand_all", function( data ) {});
    $('.dd').nestable('expandAll');
    e.preventDefault();
  });

  $('.dd.dd-sortable').each(function(){
    var $list = $(this);
    var $saveButton = $($list.attr('data-saveButton'));
    $saveButton.attr('disabled', 'disabled');
    $listNestable = $list.nestable({
      /* config options */
      maxDepth: 10
    }).on("change", function(){
      if(doesListReallyChanged($list) ){
        enableButton($saveButton);
      }
    });

    $saveButton.click(function(e){
      if(blank($saveButton.attr('disabled'))){
        saveNestableData($list, $saveButton);
      }
      e.preventDefault();
    });

    updateCurrentState($list);

    $(".nestable_dragtree button[data-action='collapse']").click(function(e){
      var pageID = $(this).parents(".dd-item").attr('data-id');
      $.get( "/admin/pages/"+pageID+"/collapse", function( data ) {

      });
    });

    $(".nestable_dragtree button[data-action='expand']").click(function(e){
      var pageID = $(this).parents(".dd-item").attr('data-id');
      $.get( "/admin/pages/"+pageID+"/expand", function( data ) {

      });
    });
  });

  function saveNestableData(list, saveButton){
    updateCurrentState(list);
    var url = list.attr('data-url');
    if (window.JSON) {
      var data = window.JSON.stringify(list.nestable('serialize'));
      $.ajax({
        type: "POST",
        url: url,
        data: "nestable_serialized_data=" + data,
        beforeSend: function(jqXHR, settings){
          showOverlay();
        },
        success: function(html){
          window.setTimeout(function(){
            hideOverlay();
          },500);
          if(!blank(saveButton)){
            disableButton(saveButton);
          }
        },
        error: function(html){
          $("#assetsDialogOverlay").html(html.responseText);
          window.setTimeout(function(){
            hideOverlay();
          },10000);
        }
      });
    } else {
        console.log('JSON browser support required for this demo.');
    }
  }

  function enableButton(saveButton){
    WarnNavigateAway.changeEventHandler();
    saveButton.removeAttr('disabled');
    saveButton.addClass('btn-primary');
  }

  function disableButton(saveButton){
    WarnNavigateAway.removeEventHandler();
    saveButton.attr('disabled', 'disabled');
    saveButton.removeClass('btn-primary');
  }

  function updateCurrentState(list){
    window.nestableSerializedDataOnPageLoad[list.attr('data-id')] = list.nestable('serialize');
  }

  function doesListReallyChanged(list){
    var change = JSON.stringify(window.nestableSerializedDataOnPageLoad[list.attr('data-id')]) != JSON.stringify(list.nestable('serialize'));
    return change;
  }
}

var WarnNavigateAway = {
  init: function(){
    $('input:not(:button,:submit),textarea,select').each(function(){
      $(this).change(WarnNavigateAway.changeEventHandler);
      $(this).keydown(WarnNavigateAway.changeEventHandler);
    });

    $('form').submit(WarnNavigateAway.removeEventHandler);
  },

  changeEventHandler : function(e){
    if(!editingInProgress){
      setNavigationAwayConfirm();
    }
    editingInProgress = true;
    function setNavigationAwayConfirm(){
      window.onbeforeunload = function() {
        AutoSave.save_now();
        return "Any changes to this page will not be saved.";
      };
    }
  },
  removeEventHandler : function(){
    editingInProgress = false;
    window.onbeforeunload = function() { };
  }
};


function initGalleryImageRepeater(){
  var containerselector = ".form_field_wrapper[data-field='gallery_images'] ul:first";
  var rowSelector = "li.row-fluid.gallery_image_repeater_form";
  $(".add_gallery_image").click(function(e){
    HtmlFormRepeater.add(containerselector, rowSelector, this, function(newElement){
      initClickEventsForAssetLinks(newElement);
      newElement.find(".remove").click();
      initHiddenFieldListner(newElement);
    });
    e.preventDefault();
  });

  HtmlFormRepeater.initRemoveButton(containerselector, rowSelector);
  HtmlFormRepeater.initSorter(containerselector, rowSelector);

  initHiddenFieldListner($("body"));
  function initHiddenFieldListner(container){
    container.find(".choose_asset_hidden_field").on('selected', function(event, title, credits){
      var formRow = $(this).parents("li.gallery_image_repeater_form");
      if(!blank(title) && blank(formRow.find(".caption-field").val())){
        formRow.find(".caption-field").val(title);
      }
      if(!blank(credits) && blank(formRow.find(".credits-field").val())){
        formRow.find(".credits-field").val(credits);
      }
    });
  }
}

/* If user modifies something in forms Autosave sends an ajax call to server and save form json dump */
var AutoSave = {
  init : function(class_name){
    $(".retreive_changes").click(AutoSave.retrieve);
    $(".cancel_changes").click(AutoSave.destroy);
    $('input:not(:button,:submit),textarea,select').each(function(){
      $(this).change(AutoSave.changeEventHandler);
      $(this).keydown(AutoSave.changeEventHandler);
    });
  },
  changeEventHandler: function(e){
    changedSinceLastAutoSave = true;
  },
  save_now: function(successCallback){
    var version = getParameterByName(window.location, 'version');

    if(!blank(version) || changedSinceLastAutoSave){
      var form = AutoSave.formObj;
      if(form == undefined){
        form = $("form.auto_save");
      }
      if(form != null && form.length > 0 ){
        $.ajax({
          url: AutoSave.autosave_url+(blank(version) ? '' : '?version='+version),
          data: form.serialize(),
          type: "POST",
          success: function(data) {

          },
          complete: function(){
            if(successCallback != undefined){
              successCallback();
            }
          }
        });
      }
    }else{
      if(successCallback != undefined){
        successCallback();
      }
    }
  },
  save : function(autosave_url, delay , form){
    AutoSave.autosave_url = autosave_url;
    AutoSave.delay = delay;
    AutoSave.formObj = form;
    setTimeout(function(){
      if(changedSinceLastAutoSave){
        if(form == undefined){
          form = $("form.auto_save");
        }
        if(form != null && form.length > 0 ){
          $.ajax({
            url: autosave_url,
            data: form.serialize(),
            type: "POST",
            success: function(data) {
              changedSinceLastAutoSave =  false;
            },
            complete: function(){
              AutoSave.save(autosave_url,delay , form);
            }
          });
        }
      }else{
        AutoSave.save(autosave_url,delay , form);
      }
    },delay * 1000);
  },
  retrieve : function(e){
    var self = $(this);
    $.getJSON(self.attr("href"), function(data) {
      updateForm(data, self.attr("data-param-name"));
    });

    function updateForm(data, prefix){

      function getAssetDetails(val, element){
        $.getJSON("/admin/assets/"+val+".json", function(data){
          data = data["asset"];
          if (element.parents(".asset_selector_wrapper").find("img").length > 0) {
            element.parents(".asset_selector_wrapper").find("img").attr('src', data["small_thumb"]);
          } else {
            element.parents(".asset_selector_wrapper").prepend("<img src='" + data["small_thumb"] + "' />");
          }
          element.parents(".caption").find("h5").html(data["name"]);
        });
      }

      for(index in data){
        var val = data[index];
        var name = prefix + "["+ index +"]";
        if((typeof val) == "object"){
          if(val instanceof Array){
            var element = $("[name='"+name+"']");
            if(element.length == 0){
              element = $("[name='"+name+"[]']");
            }
            if(element.length >= 1 && element.is("select")){
              element.find("option").prop("selected", false);
              for(option in val){
                element.find("option[value='"+val[option]+"']").prop("selected", true);
              }
            }

          }else{
            updateForm(val, name);
          }
        }else{
          var element = $("[name='"+name+"']");
          if(element.length >= 1){
            if(element.hasClass("jwysiwyg")){
              element.redactor('set', val);
            }else if(element.attr("type") == "file"){
              // ignore
            }else if(element.attr("type") == "password"){
              // ignore
            }else if(element.attr("type") == "checkbox"){
              element.attr("checked", "checked");
            }else if(element.attr("type") == "radio"){
              // ignore
            }else if(element.is(".choose_asset_hidden_field")){
              element.val(val);
              if(!blank(val)){
                getAssetDetails(val, element);

              }else{
                //delete
              }

            }else{
              element.val(val);
            }
          }
        }
      }
    }//updateForm

    e.preventDefault();
  },
  destroy: function(e){
    $.getJSON($(this).attr("href"), function(data) {
      $(".restore-auto-save").hide();
    });
    e.preventDefault();
  }
};


function initPublishingButton(){
  $(".publishing_btn").click(function(e){
    var id = $(this).attr('id');
    if(id == "draft_btn" || id == "unpublish_btn"){
      $("._publish_state").val("draft");
    } else if(id == "publish_btn" || id == "update_btn"){
      $("._publish_state").val("published");
    } else if(id == "approval_btn"){
      $("._publish_status").val("submitted_for_approval");
    } else if(id  == "revision_btn"){
      $("._publish_status").val("revision");
    }
  });
}

function initPreview(){
  $(".preview-page").click(function(e){
    var $this = $(this);
    var url = $this.attr('data-url');
    AutoSave.save_now(function(){
      window.open(url);
    });
    e.preventDefault();
  })
}


function shortcodeNameValidation() {
  var regex = /[\!\*'"″′‟‛„‚”“”˝\(\);:.@&=+$,\/?%#\[\]]/gim;
  var field = $("#gluttonberg_embed_shortcode");
  
  field.bind("blur", function() {
    field.val(field.val().toLowerCase().replace(/\s/gim, '-').replace(regex, ''));
  });
  field.bind("keyup", function() {
    field.val(field.val().toLowerCase().replace(/\s/gim, '-').replace(regex, ''));
  });
}
