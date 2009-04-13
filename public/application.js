$(document).ready(function() {
  $('li.project, .button a').hover(
    function() { $(this).addClass('highlight'); },
    function() { $(this).removeClass('highlight'); }
  );
});
