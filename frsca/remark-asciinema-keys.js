/* key bindings for Asciinema within a remark presentation 
 * License: MIT
 * Copyright: Brandon Mitchell
 */

// wrap in an anonymous function and run that function to avoid
// poluting the global namespace
(function() {
  // handle key press events to detect play/pause keys
  document.body.addEventListener("keydown", remarkAsciinemaKeys);
  // handle messages from cloned windows (presenter mode)
  window.addEventListener("message", remarkAsciinemaMessage, false);
  // monkey patch window.open to detect opened windows and save a reference
  var childWindows = [];
  var origOpen = window.open;
  window.open = function() {
    // clean closed windows
    for (i = 0; i < childWindows.length; i++) {
      if (!childWindows[i] || childWindows[i].closed) {
        childWindows.splice(i, 1)
        i--
      }
    }
    var win = origOpen.apply(this, arguments);
    childWindows.push(win);
    return win;
  };
  
  // handle play/pause keys
  function remarkAsciinemaKeys(e) {
    if (e.which == 87 || e.keyCode == 87) { // key: w
      remarkAsciinemaAction("pause")
    }
    else if (e.which == 69 || e.keyCode == 69) { // key: e
      remarkAsciinemaAction("play")
    }
  }
  
  function remarkAsciinemaAction(action) {
    var localPlayer = remarkAsciinemaGetPlayer()
    if (localPlayer) {
      if (action == "play") {
        localPlayer.play()
      } else if (action == "pause") {
        localPlayer.pause()
      }
    }
  
    // send action to parent window if this is a clone
    if (window.opener) {
      window.opener.postMessage("remarkAsciinema:"+action, "*")
    }
    // also post to cloned windows 
    for (i = 0; i < childWindows.length; i++) {
      if (!childWindows[i].closed) {
        childWindows[i].postMessage("remarkAsciinema:"+action, "*")
      }
    }
  }
  
  function remarkAsciinemaMessage(event) {
    var msgregex = /^remarkAsciinema:(.*)$/.exec(event.data)
    var localPlayer = remarkAsciinemaGetPlayer()
    if (localPlayer && msgregex != null) {
      if (msgregex[1] == "play") {
        localPlayer.play()
      }
      else if (msgregex[1] == "pause") {
        localPlayer.pause()
      }
    }
  
  }
  
  function remarkAsciinemaGetPlayer() {
    return document.querySelectorAll(".remark-visible asciinema-player")[0]
  }
})();
