$(function() {
  function detect() {
    if (!$('textarea').val()) {
      $('div.lang').removeClass('in');
      return;
    }

    var $spinner = $('#spinner').addClass('fa-spin in');
    $.post('/api/classify/scores', {sample: $('textarea').val()}, function(data) {
      $('div.lang').each(function(i, row) {
        $(row).addClass('in');
        $(row).find('div').first().html(data[i][0]);
        $(row).find('.progress-bar').width(data[i][1] * 100 + '%');
      });
      $spinner.removeClass('fa-spin in');
    });
  }

  var timeout;
  $('textarea').keyup(function() {
    if (timeout)
      clearTimeout(timeout);
    timeout = setTimeout(detect, 500);
  }).change(detect);
});
