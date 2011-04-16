$(function() {
  $('button[data-href]').click(function() {
    var method = $(this).data("method");
    if (method === null) {
      method = "POST";
    }
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
    else if ($(this).data("async") == "yes") {
      $.ajax({
        url: url,
        type: "POST",
        data: data,
        success: function() { }
      });
    }
    else {
      console.log(url);
      var form = $('<FORM METHOD="POST" ACTION="' + url + '"></FORM>');
      form.hide().append('<INPUT NAME="_method" value="' + method + '" TYPE="HIDDEN" />').appendTo('body');
      form.submit();
    }
    return false;
  });
  $("button").button();
});
