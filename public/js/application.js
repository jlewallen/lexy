$(function() {
  $('a.ajax').click(function() {
    $.ajax({
      url: $(this).attr("href"),
      type: "POST",
      success: function() {
      }
    });
    return false;
  });
});
