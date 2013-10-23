$(function() {
  function detect() {
    if (!$('textarea').val()) {
      $('div.lang').removeClass('in');
      return;
    }

    $.post('/api/scores', {sample: $('textarea').val()}, function(data) {
      $('div.lang').each(function(i, row) {
        $(row).addClass('in');
        $(row).find('div').first().html(data[i][0]);
        $(row).find('.progress-bar').width(data[i][1] * 100 + '%');
      });
    });
  }

  var timeout;
  $('textarea').keyup(function() {
    if (timeout)
      clearTimeout(timeout);
    timeout = setTimeout(detect, 500);
  }).change(detect);
});
