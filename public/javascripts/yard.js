function linkSummariesOverride() {
  $('.summary_signature a').click(function() {
    self.location.href = $(this).attr('href');
    return false;
  });
}

$(document).ready(function() {
  $(linkSummariesOverride);
});
