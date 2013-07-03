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
});


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
    $(this).parent("li").addClass('active')
  });
}

function initFormValidation(){
  $("form.validation").validate();
}



// if container element has class "add_to_photoseries" , it returns html of new image
function initClickEventsForAssetLinks(element) {
  element.find(".thumbnails a.choose_button").click(function(e) {
    var p = $(this).parent().parent().parent(".asset_selector_wrapper");
    var link = $(this);
    AssetBrowser.showOverlay()
    $.get(link.attr("href"), null, function(markup) {
      AssetBrowser.load(p, link, markup);
    });
    e.preventDefault();
  });

}


var AssetBrowser = {
  overlay: null,
  dialog: null,
  imageDisplay: null,
  Wysiwyg: null,
  logo_setting: false,
  filter: null,
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
    if(AssetBrowser.actualLink.hasClass("add_image_to_gallery")){
      AssetBrowser.target = null;
    }

    threeSixtyPlayer.init();

    // Grab the various nodes we need
    AssetBrowser.display = AssetBrowser.browser.find("#assetsDisplay");
    AssetBrowser.offsets = AssetBrowser.browser.find("> *:not(#assetsDisplay)");
    AssetBrowser.backControl = AssetBrowser.browser.find("#back a");
    AssetBrowser.backControl.css({
      display: "none"
    });
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
    $("#assetsDialog form#asset_search_form").submit(AssetBrowser.search_submit);
    AssetBrowser.backControl.click(AssetBrowser.back);

    AssetBrowser.browser.find("#ajax_new_asset_form").submit(function(e) {
      if($("#asset_file").val() != null && $("#asset_name").val() != null && $("#asset_file").val() != "" && $("#asset_name").val() != ""){
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
    }catch(e){
      console.log(e);
    }

    try {
      $("#assetsDialog form.validation").validate();
    } catch(e) {
      console.log(e)
    }

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
    })

    $(".modal-body").css({
      "max-height": (($(window).height()*0.9) - 135) + "px",
      "height": (($(window).height()*0.9) - 135) + "px"
    })
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
    window_height = $(window).height() + $(window).scrollTop()
    if (set_height < window_height) set_height = window_height;
    $("#assetsDialogOverlay").height(set_height)

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
    if (json.backURL) {
      AssetBrowser.backURL = json.backURL;
      AssetBrowser.backControl.css({
        display: "block"
      });
    }
    AssetBrowser.updateDisplay(json.markup);
  },
  updateDisplay: function(markup) {
    AssetBrowser.display.html(markup);
    AssetBrowser.display.find("a").click(AssetBrowser.click);

    try {
      $("form.validation").validate();
    } catch(ex) {}
    AssetBrowser.browser.find("#ajax_new_asset_form").submit(function(e) {
      if($("#asset_file").val() != null && $("#asset_name").val() != null && $("#asset_file").val() != "" && $("#asset_name").val() != ""){
        ajaxFileUpload(AssetBrowser.actualLink);
      }
      e.preventDefault();
    })
  },
  search_submit: function(e) {
    $("#progress_ajax_upload").ajaxStart(function() {
      $(this).show();
    }).ajaxComplete(function() {
      $(this).hide();
    });
    var url = $("#assetsDialog form#asset_search_form").attr("action");
    url += ".json?" + $("#assetsDialog form#asset_search_form").serialize()
    $.getJSON(url, null, function(json){
      $("#search_tab_results").html(json.markup);
      $("#search_tab_results").find("a").click(AssetBrowser.click);
    });
    e.preventDefault();
  },
  click: function() {
    var target = $(this);
    if (target.is(".assetLink")) {
      var id = target.attr("href").match(/\d+$/);
      var name = target.attr("data-title");

      // assets only
      if (AssetBrowser.target !== null) {
        AssetBrowser.target.attr("value", id);
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

        autoSaveAsset(AssetBrowser.logo_setting_url, id); //auto save if it is required
      } else {
        if (AssetBrowser.actualLink.hasClass("add_image_to_gallery")) {

          $.ajax({
            url: AssetBrowser.actualLink.attr("data_url"),
            data: 'asset_id=' + id,
            type: "GET",
            success: function(data) {
              $("#images_container").html(data);
              initEditGalleryList();
              dragTreeManager.init();
              AssetBrowser.close();
            },
            error: function(data) {
              AssetBrowser.close();
            }
          });
        }
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
        $.get("/admin/browser-collection/"+collectionID+".json?filter="+AssetBrowser.filter.val(), function(data){
          $(".gb_spinner").remove();
          accordionContentInner.prepend(data['markup']);
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
        url += "?filter=" + AssetBrowser.filter.val();
      }
      $.getJSON(url, null, AssetBrowser.handleJSON);
    }
    return false;
  },
  back: function() {
    if (AssetBrowser.backURL) {
      var category = "";
      var show_content = ""
      // if filter exist then apply it on backurl
      if (AssetBrowser.filter !== null) {
        if (AssetBrowser.filter == undefined || AssetBrowser.filter.length == 0) {
          if (AssetBrowser.Wysiwyg != null) category = "&filter=image";
        } else category = "&filter=" + AssetBrowser.filter.val();
      }
      $.get(AssetBrowser.backURL + category + show_content, null, AssetBrowser.updateDisplay);
      AssetBrowser.backURL = null;
      AssetBrowser.backControl.css({
        display: "none"
      });
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
    if(!blank(Wysiwyg.getSelectionText())){
      title = Wysiwyg.getSelectionText();
    }
    description = "";
    style = "";
    if(file_type == "image"){
      image = "<img src='" + image_url + "' title='" + title + "' alt='" + description + "'" + style + "/>";
    }else{
      image = " <a href='"+image_url+"' >"+title+"</a> ";
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
    new_value = $(this).val()

    $("#progress_" + id).show("fast")

    $.ajax({
      url: url,
      data: 'gluttonberg_setting[value]=' + new_value,
      type: "PUT",
      success: function(data) {
        $("#progress_" + id).hide("fast")
      }
    });

  });
  initHomePageSettingDropdownAjax();
}


function initHomePageSettingDropdownAjax() {
  $(".home_page_setting_dropdown").change(function() {
    url = $(this).attr("rel");
    id = "home_page"
    new_value = $(this).val()

    $("#progress_" + id).show("fast")

    $.ajax({
      url: url,
      data: 'home=' + new_value,
      type: "POST",
      success: function(data) {
        $("#progress_" + id).hide("fast")
      }
    });

  })

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

  $("#progress_ajax_upload").show();

  asset_name = $('input[name$="asset[name]"]').val();
  var formData = {
    "asset[name]": asset_name,
    "asset[asset_collection_ids]": $("#asset_asset_collection_ids").val(),
    "new_collection[new_collection_name]": $('input[name$="new_collection[new_collection_name]"]').val()
  }

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
    fileElementId: 'asset_file',
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


      new_id = data["asset_id"]
      file_path = data["url"]
      jwysiwyg_image = data["jwysiwyg_image"];

      try{
        AssetBrowser.target.attr("value", new_id);
        AssetBrowser.nameDisplay.html(asset_name);
        if (AssetBrowser.link_parent.find("img").length > 0) {
          AssetBrowser.link_parent.find("img").attr('src', file_path)

        } else {
          AssetBrowser.link_parent.prepend("<img src='" + file_path + "' />")
        }
      }catch(e){}
      if(data["category"] == "image")
        insertImageInWysiwyg(jwysiwyg_image,data["category"],data["title"]);
      else
        insertImageInWysiwyg(file_path,data["category"],data["title"]);

      data_id = $(this).attr("data_id");
      url = AssetBrowser.logo_setting_url;
      autoSaveAsset(url, new_id); // only if autosave is required

      if (AssetBrowser.actualLink.hasClass("add_image_to_gallery")) {
        $.ajax({
          url: AssetBrowser.actualLink.attr("data_url"),
          data: 'asset_id=' + new_id,
          type: "GET",
          success: function(data) {
            $("#images_container").html(data);
            initEditGalleryList();
            dragTreeManager.init();
          },
          error: function(data) {
          }
        });
      }

      AssetBrowser.close();
    },
    error: function(data, status, e) {
      console.log(data);
      console.log(e);
    }
  })

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
  })

  function updatePublishedDateField(){
    if($(".publishing_state").val()=="published"){
      $(".published_at").show();
    }else{
      $(".published_at").hide();
    }
  }
  updatePublishedDateField();
}

/* Setup Gallery */

function initEditGalleryList() {
  $(".delete_gallery_item").click(deleteEventHandlerForGalleryList)

}

function deleteEventHandlerForGalleryList() {
  id = $(this).attr("rel")
  $("#progress_" + id).show("fast");
  $.ajax({
    url: $(this).attr("data-url"),
    type: "GET",
    success: function(data) {
      $("#node-" + id).remove();
    }
  });
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
      selected_assets_ids.remove($(this).attr("rel"))
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
      alert("Please select at least one asset.")
    }else{
      var answer = confirm("Are you sure to delete all selected assets?")
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
  $(".collapse").collapse({parent: "#accordion_for_collections"})
  $(".accordion-heading a").click(function(e){
    var target = $(this);
    var accordionContent = $(target.attr('href'));
      var accordionContentInner = accordionContent.find(".accordion-inner");
      var collectionID = accordionContentInner.attr('data-id');

      if(accordionContentInner.attr("content-loaded") == "false"){
        accordionContentInner.prepend("<img src='/assets/gb_spinner.gif' class='gb_spinner'/>");
        $.get("/admin/browser-collection/"+collectionID+".json", function(data){
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
        'table', '|',  'html'
      ],
      plugins: ['asset_library_image', 'gluttonberg_pages']
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

  $('#page_slug_holder .domain').html($.trim(str));

  pt.keyup(function(){
    if (!doNotEdit) {
      slug = pt.attr('value').toLowerCase().replace(/\s/gim, '-').replace(regex, '')
      ps.html(slug);
      hs.attr('value', slug);
    };
  })

  pb.click(function(){
    hs.show();
    ps.hide();
    pb.hide();
    hs.focus();
    doNotEdit = true;
    slugLength = hs.val().length;
    currentSlug = hs.val();
  })

  hs.focusout(function(){
    var len = hs.val().length;
    if (doNotEdit) {
      if (len == 0) {
        hs.hide();
        ps.show();
        pb.show();
        if (!editPage) {
          doNotEdit = false;
          slug = pt.attr('value').toLowerCase().replace(/\s/gim, '_').replace(regex, '')
          ps.html(slug);
          hs.attr('value', slug);
        } else {
          hs.attr('value', currentSlug);
        }
      } else if(slugLength == len) {
        hs.hide();
        ps.show();
        pb.show();
        if (!editPage) {
          doNotEdit = false;
        }
      } else {
        hs.hide();
        ps.show();
        pb.show();
        ps.html(hs.attr('value').toLowerCase().replace(/\s/gim, '_').replace(regex, ''));
        doNotEdit = true;
      };
    };
  })

}


// This method initialize slug related event on a title text box.
function initSlugManagement() {
  try {
    var pt = $('#page_title');
    var ps = $('#page_slug');

    var regex = /[\!\*'"″′‟‛„‚”“”˝\(\);:.@&=+$,\/?%#\[\]]/gim;

    var pt_function = function() {
      if (ps.attr('donotmodify') != 'true') ps.attr('value', pt.attr('value').toLowerCase().replace(/\s/gim, '_').replace(regex, ''));
    };

    pt.bind("keyup", pt_function);
    pt.bind("blur", pt_function);

    ps.bind("blur", function() {
      ps.attr('value', ps.attr('value').toLowerCase().replace(/\s/gim, '_').replace(regex, ''));
      ps.attr('donotmodify', 'true');
    });
  } catch(e) {
    console.log(e)
  }
}

function enable_slug_management_on(src_class){
  $("."+src_class).attr('id','page_title')
}

function initNestable(){
  window.nestableSerializedDataOnPageLoad = [];

  // $('.dd').nestable({ /* config options */
  // }).on('change', function(e) {
  //   /* on change event */
  //   var list   = e.length ? e : $(e.target),
  //   output = list.data('output'),
  //   url = list.attr('data-url');
  // });

  $('.dd').each(function(){
    var $list = $(this);
    var $saveButton = $($list.attr('data-saveButton'));
    $saveButton.attr('disabled', 'disabled');
    $list.nestable({
      /* config options */
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
          },10000)
        }
      });
    } else {
        console.log('JSON browser support required for this demo.');
    }
  }

  function enableButton(saveButton){
    saveButton.removeAttr('disabled');
    saveButton.addClass('btn-primary');
  }

  function disableButton(saveButton){
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


