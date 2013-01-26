/* ===========================================================
 * bootstrap-datepicker.js v1.3.0
 * http://twitter.github.com/bootstrap/javascript.html#datepicker
 * ===========================================================
 * Copyright 2011 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributed by Scott Torborg - github.com/storborg
 * Loosely based on jquery.date_input.js by Jon Leighton, heavily updated and
 * rewritten to match bootstrap javascript approach and add UI features.
 * =========================================================== */


!function ( $ ) {

  var selector = '[data-datepicker]',
      all = [];

  function clearDatePickers(except) {
    var ii;
    for(ii = 0; ii < all.length; ii++) {
      if(all[ii] != except) {
        all[ii].hide();
      }
    }
  }

  function DatePicker( element, options ) {
    this.$el = $(element);
    this.proxy('show').proxy('ahead').proxy('hide').proxy('keyHandler').proxy('selectDate');

    var options = $.extend({}, $.fn.bsdatepicker.defaults, options );

    if((!!options.parse) || (!!options.format) || !this.detectNative()) {
      $.extend(this, options);
      this.$el.data('bsdatepicker', this);
      all.push(this);
      this.init();
    }
  }

  DatePicker.prototype = {

      detectNative: function(el) {
        // Attempt to activate the native datepicker, if there is a known good
        // one. If successful, return true. Note that input type="date"
        // requires that the string be RFC3339, so if the format/parse methods
        // have been overridden, this won't be used.
        if(navigator.userAgent.match(/(iPad|iPhone); CPU(\ iPhone)? OS 5_\d/i)) {
          // jQuery will only change the input type of a detached element.
          var $marker = $('<span>').insertBefore(this.$el);
          this.$el.detach().attr('type', 'date').insertAfter($marker);
          $marker.remove();
          return true;
        }
        return false;
      }

    , init: function() {
        var $months = this.nav('months', 1);
        var $years = this.nav('years', 12);

        var $nav = $('<div>').addClass('nav').append($months, $years);

        this.$month = $('.name', $months);
        this.$year = $('.name', $years);

        $calendar = $("<div>").addClass('calendar');

        // Populate day of week headers, realigned by startOfWeek.
        for (var i = 0; i < this.shortDayNames.length; i++) {
          $calendar.append('<div class="dow">' + this.shortDayNames[(i + this.startOfWeek) % 7] + '</div>');
        };

        this.$days = $('<div>').addClass('days');
        $calendar.append(this.$days);

        this.$picker = $('<div>')
          .click(function(e) { e.stopPropagation() })
          // Use this to prevent accidental text selection.
          .mousedown(function(e) { e.preventDefault() })
          .addClass('datepicker')
          .append($nav, $calendar)
          .insertAfter(this.$el);

        this.$el
          .focus(this.show)
          .click(this.show)
          .change($.proxy(function() { this.selectDate(); }, this));

        this.selectDate();
        this.hide();
      }

    , nav: function( c, months ) {
        var $subnav = $('<div>' +
                          '<span class="prev button">&larr;</span>' +
                          '<span class="name"></span>' +
                          '<span class="next button">&rarr;</span>' +
                        '</div>').addClass(c)
        $('.prev', $subnav).click($.proxy(function() { this.ahead(-months, 0) }, this));
        $('.next', $subnav).click($.proxy(function() { this.ahead(months, 0) }, this));
        return $subnav;

    }

    , updateName: function($area, s) {
        // Update either the month or year field, with a background flash
        // animation.
        var cur = $area.find('.fg').text(),
            $fg = $('<div>').addClass('fg').append(s);
        $area.empty();
        if(cur != s) {
          var $bg = $('<div>').addClass('bg');
          $area.append($bg, $fg);
          $bg.fadeOut('slow', function() {
            $(this).remove();
          });
        } else {
          $area.append($fg);
        }
    }

    , selectMonth: function(date) {
        var newMonth = new Date(date.getFullYear(), date.getMonth(), 1);

        if (!this.curMonth || !(this.curMonth.getFullYear() == newMonth.getFullYear() &&
                                this.curMonth.getMonth() == newMonth.getMonth())) {

          this.curMonth = newMonth;

          var rangeStart = this.rangeStart(date), rangeEnd = this.rangeEnd(date);
          var num_days = this.daysBetween(rangeStart, rangeEnd);
          this.$days.empty();

          for (var ii = 0; ii <= num_days; ii++) {
            var thisDay = new Date(rangeStart.getFullYear(), rangeStart.getMonth(), rangeStart.getDate() + ii, 12, 00);
            var $day = $('<div>').attr('date', this.format(thisDay));
            $day.text(thisDay.getDate());

            if (thisDay.getMonth() != date.getMonth()) {
              $day.addClass('overlap');
            };

            this.$days.append($day);
          };

          this.updateName(this.$month, this.monthNames[date.getMonth()]);
          this.updateName(this.$year, this.curMonth.getFullYear());

          $('div', this.$days).click($.proxy(function(e) {
            var $targ = $(e.target);

            // The date= attribute is used here to provide relatively fast
            // selectors for setting certain date cells.
            this.update($targ.attr("date"));

            // Don't consider this selection final if we're just going to an
            // adjacent month.
            if(!$targ.hasClass('overlap')) {
              this.hide();
            }

          }, this));

          $("[date='" + this.format(new Date()) + "']", this.$days).addClass('today');

        };

        $('.selected', this.$days).removeClass('selected');
        $('[date="' + this.selectedDateStr + '"]', this.$days).addClass('selected');
      }

    , selectDate: function(date) {
        if (typeof(date) == "undefined") {
          date = this.parse(this.$el.val());
        };
        if (!date) date = new Date();

          this.selectedDate = date;
          this.selectedDateStr = this.format(this.selectedDate);
          this.selectMonth(this.selectedDate);
      }

    , update: function(s) {
        this.$el.val(s).change();
      }

    , show: function(e) {
        e && e.stopPropagation();

        // Hide all other datepickers.
        clearDatePickers(this);

        this.$picker.show();

        $('html').on('keydown', this.keyHandler);
      }

    , hide: function() {
        this.$picker.hide();
        $('html').off('keydown', this.keyHandler);
      }

    , keyHandler: function(e) {
        // Keyboard navigation shortcuts.
        switch (e.keyCode)
        {
          case 9:
          case 27:
            // Tab or escape hides the datepicker. In this case, just return
            // instead of breaking, so that the e doesn't get stopped.
            this.hide(); return;
          case 13:
            // Enter selects the currently highlighted date.
            this.update(this.selectedDateStr); this.hide(); break;
          case 38:
            // Arrow up goes to prev week.
            this.ahead(0, -7); break;
          case 40:
            // Arrow down goes to next week.
            this.ahead(0, 7); break;
          case 37:
            // Arrow left goes to prev day.
            this.ahead(0, -1); break;
          case 39:
            // Arrow right goes to next day.
            this.ahead(0, 1); break;
          default:
            return;
        }
        e.preventDefault();
      }

    , parse: function(s) {
        // Parse a partial RFC 3339 string into a Date.
        var m;
        if ((m = s.match(/^(\d{4,4})-(\d{2,2})-(\d{2,2})$/))) {
          return new Date(m[1], m[2] - 1, m[3]);
        } else {
          return null;
        }
      }

    , format: function(date) {
        // Format a Date into a string as specified by RFC 3339.
        var month = (date.getMonth() + 1).toString(),
            dom = date.getDate().toString();
        if (month.length === 1) {
          month = '0' + month;
        }
        if (dom.length === 1) {
          dom = '0' + dom;
        }
        return date.getFullYear() + '-' + month + "-" + dom;
      }

    , ahead: function(months, days) {
        // Move ahead ``months`` months and ``days`` days, both integers, can be
        // negative.
        this.selectDate(new Date(this.selectedDate.getFullYear(),
                                 this.selectedDate.getMonth() + months,
                                 this.selectedDate.getDate() + days));
      }

    , proxy: function(meth) {
        // Bind a method so that it always gets the datepicker instance for
        // ``this``. Return ``this`` so chaining calls works.
        this[meth] = $.proxy(this[meth], this);
        return this;
      }

    , daysBetween: function(start, end) {
        // Return number of days between ``start`` Date object and ``end``.
        var start = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
        var end = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
        return (end - start) / 86400000;
      }

    , findClosest: function(dow, date, direction) {
        // From a starting date, find the first day ahead of behind it that is
        // a given day of the week.
        var difference = direction * (Math.abs(date.getDay() - dow - (direction * 7)) % 7);
        return new Date(date.getFullYear(), date.getMonth(), date.getDate() + difference);
      }

    , rangeStart: function(date) {
        // Get the first day to show in the current calendar view.
        return this.findClosest(this.startOfWeek,
                                new Date(date.getFullYear(), date.getMonth()),
                                -1);
      }

    , rangeEnd: function(date) {
        // Get the last day to show in the current calendar view.
        return this.findClosest((this.startOfWeek - 1) % 7,
                                new Date(date.getFullYear(), date.getMonth() + 1, 0),
                                1);
      }
  };

  /* DATEPICKER PLUGIN DEFINITION
   * ============================ */

  $.fn.bsdatepicker = function( options ) {
    return this.each(function() { new DatePicker(this, options); });
  };

  $(function() {
    $(selector).bsdatepicker();
    $('html').click(clearDatePickers);
  });

  $.fn.bsdatepicker.DatePicker = DatePicker;

  $.fn.bsdatepicker.defaults = {
    monthNames: ["January", "February", "March", "April", "May", "June",
                 "July", "August", "September", "October", "November", "December"]
  , shortDayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  , startOfWeek: 1
  };
}( window.jQuery || window.ender );

/* Update datepicker plugin so that DD/MM/YYYY format is used. */
$.extend($.fn.bsdatepicker.defaults, {
  parse: function (string) {
    return parseStringIntoDate(string);
  },
  format: function (date) {
    var
      month = (date.getMonth() + 1).toString(),
      dom = date.getDate().toString();
    if (month.length === 1) {
      month = "0" + month;
    }
    if (dom.length === 1) {
      dom = "0" + dom;
    }
    return dom + "/" + month + "/" + date.getFullYear();
  }
});

function parseStringIntoDate(string){
  var matches;
  if ((matches = string.match(/^(\d{2,2})\/(\d{2,2})\/(\d{4,4})$/))) {
    return new Date(matches[3], matches[2]- 1, matches[1] );
  } else {
    return null;
  }
}

function dbDateFormat(date){
  var
    month = (date.getMonth() + 1).toString(),
    dom = date.getDate().toString();
  if (month.length === 1) {
    month = "0" + month;
  }
  if (dom.length === 1) {
    dom = "0" + dom;
  }
  return date.getFullYear() + "-"+ month + "-" + dom ;
}

function combine_datetime(target_field_class){
  var src_date_field = $("#"+target_field_class + "_date");
  var src_time_field = $("#"+target_field_class + "_time");
  var date = parseStringIntoDate(src_date_field.val());
  var time = src_time_field.val();

  if(time == "" || time.split(":").length !=2 ){
    time = "00:00"
  }else{
    var hours = parseInt(time.split(":")[0] , 10);
    var secondpart = time.split(":")[1];
    var minutes = 0;
    var am_pm = "AM";

    if(secondpart.search(" ") > 0){
      minutes = parseInt(secondpart.split(" ")[0],10);
      am_pm = secondpart.split(" ")[1];
    }else{
      minutes = parseInt(secondpart.substring(0,2),10);
      am_pm = secondpart.substring(2);
    }

    if((am_pm.toLowerCase() == "am" || am_pm.toLowerCase() == "") && hours == 12){
      hours = 0
    }

    if(am_pm.toLowerCase() == "pm" && hours != 12){
      hours += 12;
    }else{

    }

    if(hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59){
      time = hours + ":"+ minutes;
    }else{
      time = "00:00";
    }
  }



  var new_val = "";
  if(date != null){
    new_val = dbDateFormat(date) + " " + time;

  }
  $("."+target_field_class).val(new_val);
}

function checkDateFormat(datefield,error_label){
  date = $(datefield).val();
  error_label = $(error_label)
  // regular expression to match required date format
      re = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/;

      if(date != '') {
        if(regs = date.match(re)) {
          // day value between 1 and 31
          if(regs[1] < 1 || regs[1] > 31) {
            show_validation_error(error_label ,"Invalid value for day: " + regs[1]);
            datefield.focus();
            return false;
          }
          // month value between 1 and 12
          if(regs[2] < 1 || regs[2] > 12) {
            show_validation_error(error_label ,"Invalid value for month: " + regs[2]);
            datefield.focus();
            return false;
          }
          // year value between 1902 and 2012
          if(regs[3] < 1902 || regs[3] > (new Date()).getFullYear()+2) {
            show_validation_error(error_label ,"Invalid value for year: " + regs[3] + " - must be between 1902 and " + (new Date()).getFullYear()+2);
            datefield.focus();
            return false;
          }
        } else {
          show_validation_error(error_label ,"Invalid date format: " + form.startdate.value);
          datefield.focus();
          return false;
        }
      }
}

function checkTimeFormat(timeField,error_label)
{
    time = $(timeField).val();
    error_label = $(error_label)
    // regular expression to match required time format
    re = /^(\d{1,2}):(\d{2})(\s){0,1}([a|p]m)?$/i;

    if(time.value != '') {
      if(regs = time.match(re)) {
        if(regs[3]) {
          // 12-hour value between 1 and 12
          if(regs[1] < 1 || regs[1] > 12) {
            show_validation_error(error_label ,"Invalid value for hours: " + regs[1]);
            timeField.focus();
            return false;
          }
        } else {
          // 12-hour value between 1 and 12
          if(regs[1] < 1 || regs[1] > 12) {
            show_validation_error(error_label ,"Invalid value for hours: " + regs[1]);
            timeField.focus();
            return false;
          }
        }
        // minute value between 0 and 59
        if(regs[2] > 59) {
          show_validation_error(error_label ,"Invalid value for minutes: " + regs[2]);
          timeField.focus();
          return false;
        }
      } else {
        show_validation_error(error_label ,"Invalid time format: " + timeField.value);
        timeField.focus();
        return false;
      }
    }

    return true;
}

function show_validation_error(error_label , message){
  error_label.html(message);
}
