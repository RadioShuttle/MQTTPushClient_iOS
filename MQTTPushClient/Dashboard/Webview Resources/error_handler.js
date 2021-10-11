window.addEventListener('error', function (e) {
  var message = {
    message: e.message,
    url: e.filename,
    line: e.lineno,
    column: e.colno,
    error: JSON.stringify(e.error)
  }
  window.webkit.messageHandlers.error.postMessage(message);
});
