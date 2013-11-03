$(function() {
  function updateTotals() {
    $.get('/api/stats', function(stats) {
      $('#total-languages').html(stats.languages);
      $('#total-samples').html(stats.samples);
      $('#total-tokens').html(stats.tokens);
    });
  }

  var sortBy = 'samples',
      sortOrder = 1;

  function updateTable() {
    var $tha = $('th a');
    $tha
      .find('i')
      .removeClass('fa-caret-down fa-caret-up');
    $tha
      .filter('#sort-' + sortBy)
      .find('i')
      .addClass(sortOrder == 1 ? 'fa-caret-down' : 'fa-caret-up');

    $.get('/api/stats/languages', function(data) {
      var $tbody = $('tbody').empty();

      data = $.map(data, function(stats, lang) {
        return {language: lang, samples: stats.samples, tokens: stats.tokens};
      }).sort(function (a, b) {
        if (sortBy == 'language') {
          if (a.language > b.language)
            return 1 * sortOrder;
          else if (a.language < b.language)
            return -1 * sortOrder;
          return 0;
        } else {
          return (b[sortBy] - a[sortBy]) * sortOrder;
        }
      });

      $.each(data, function(i, stats) {
        $tbody.append($('<tr>')
          .append($('<td>').html(stats.language))
          .append($('<td>').html(stats.samples))
          .append($('<td>').html(stats.tokens)));
      });
    });
  }

  function sortTable(by) {
    if (sortBy == by) {
      sortOrder *= -1;
    } else {
      sortBy = by;
      sortOrder = 1;
    }
    updateTable();
  }

  function update() {
    updateTotals();
    updateTable();
  }

  $('#refresh').click(update);

  $('#sort-language').click(function() {
    sortTable('language');
    return false;
  });
  $('#sort-samples').click(function() {
    sortTable('samples');
    return false;
  });
  $('#sort-tokens').click(function() {
    sortTable('tokens');
    return false;
  });

  update();
});
