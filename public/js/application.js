$(function() {
  $('button[data-href]').click(function() {
    var method = $(this).data("method");
    var data = {}
    if (method) {
      data = { "_method": method }
    }
    var url = $(this).data("href");
    var message = $(this).data("confirm");
    if (message != null) {
      if (!confirm(message)) {
        return false;
      }
    }

    if (method == "GET") {
      window.location = url;
    }
    else if ($(this).data("sync") == "yes") {
      var form = $('<FORM METHOD="POST" ACTION="' + url + '"></FORM>');
      form.hide().append('<INPUT NAME="_method" value="' + method + '" TYPE="HIDDEN" />').appendTo('body');
      form.submit();
    }
    else {
      $.ajax({
        url: url,
        type: "POST",
        data: data,
        success: function() { }
      });
    }
    return false;
  });
  $("button").button();
});
