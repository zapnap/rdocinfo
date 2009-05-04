$(document).ready(function() {
  $('li.project, .button a, :submit').hover(
    function() { $(this).addClass('highlight'); },
    function() { $(this).removeClass('highlight'); }
  );
  $('a.email').each(function(){
    e = this.rel.replace('/','@');
    this.href = 'mailto:' + e;
  });
  $('form').submit(function() { 
    $(':button',this).attr('disabled','disabled');
  });
});
