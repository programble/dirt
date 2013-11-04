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

  function updateLanguages() {
    // Update sort indicators
    var $tha = $('#languages th a');
    $tha
      .find('i')
      .removeClass('fa-caret-down fa-caret-up');
    $tha
      .filter('#sort-' + sortBy)
      .find('i')
      .addClass(sortOrder == 1 ? 'fa-caret-down' : 'fa-caret-up');

    $.get('/api/stats/languages', function(data) {
      var $tbody = $('#languages tbody').empty();

      // Sort data
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

      // Populate table
      $.each(data, function(i, stats) {
        $tbody.append($('<tr>')
          .toggleClass('active', tokensLanguage == stats.language)
          .append($('<td>').text(i + 1))
          .append($('<td>').text(stats.language))
          .append($('<td>').text(stats.samples))
          .append($('<td>').text(stats.tokens)));
      });

      // Register click handlers for rows
      $('#languages tbody tr').click(function() {
        var $this = $(this);
        $this.siblings().removeClass('active');
        $this.addClass('active');

        tokensLanguage = $this.find('td').eq(1).text();
        tokensPage = 1;
        updateTokens();
        window.location.hash = '#' + tokensLanguage;
      });
    });
  }

  function sortLanguages(by) {
    if (sortBy == by) {
      sortOrder *= -1;
    } else {
      sortBy = by;
      sortOrder = 1;
    }
    updateLanguages();
  }

  var tokensLanguage = window.location.hash.substring(1),
      tokensPage = 1;

  function updateTokens() {
    if (!tokensLanguage) {
      $('#tokens').removeClass('in');
      return;
    }

    // Update header
    $('#tokens').addClass('in');
    $('#tokens h2').attr('id', tokensLanguage);
    $('#tokens-language').text(tokensLanguage);

    $.get('/api/stats/tokens', {language: tokensLanguage, page: tokensPage}, function(tokens) {
      var $tbody = $('#tokens tbody').empty(),
          offset = 20 * (tokensPage - 1) + 1;

      // Populate table
      $.each(tokens, function(i, pair) {
        $tbody.append($('<tr>')
          .append($('<td>').text(i + offset))
          .append($('<td>').append($('<code>').text(pair[0])))
          .append($('<td>').text(pair[1])));
      });

      // Update pager state
      $('#tokens .pager .previous')
        .toggleClass('disabled', tokensPage == 1)
        .find('a').attr('href', '#' + tokensLanguage);
      $('#tokens .pager .next')
        .toggleClass('disabled', tokens.length != 20)
        .find('a').attr('href', '#' + tokensLanguage);
    });
  }

  function update() {
    updateTotals();
    updateLanguages();
    updateTokens();
  }

  $('#refresh').click(update);

  // Column headers
  $('#sort-language').click(function() {
    sortLanguages('language');
    return false;
  });
  $('#sort-samples').click(function() {
    sortLanguages('samples');
    return false;
  });
  $('#sort-tokens').click(function() {
    sortLanguages('tokens');
    return false;
  });

  // Table rows
  $('#languages tbody tr').click(function() {
    var $this = $(this);
    $this.siblings().removeClass('active');
    $this.addClass('active');
  });

  // Tokens pager
  $('#tokens .pager .previous').click(function() {
    if ($(this).hasClass('disabled'))
      return false;
    tokensPage--;
    updateTokens();
  });
  $('#tokens .pager .next').click(function() {
    if ($(this).hasClass('disabled'))
      return false;
    tokensPage++;
    updateTokens();
  });

  update();
});
