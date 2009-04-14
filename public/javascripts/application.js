$(document).ready(function() {
  $('li.project, .button a, :submit').hover(
    function() { $(this).addClass('highlight'); },
    function() { $(this).removeClass('highlight'); }
  );
});
