function set_togglable_visibility(dom_id, state) {
  link = $("toggle_link_" + dom_id);
  detail_div = $(dom_id)
  if (state) {
    link.update("-");
    detail_div.show();
  }
  else
  {
    link.update("+");
    detail_div.hide()
  }
}

function toggle_diff(dom_id) {
  e = $(dom_id)
  var show = ! e.visible()
  if (e.readAttribute("loaded")) {
    set_togglable_visibility( dom_id, show );
    return
  }
  e.setAttribute("loaded", "");
  dispatch({controller: 'diff', action: 'diff', revision: e.readAttribute("rev"), git_path: e.readAttribute("git_path"), path: (e.readAttribute("path") || ""), layout: false}).then(function(html) {
    e.update(html)
    set_togglable_visibility( dom_id, show );
  })
}

function toggle_log(dom_id) {
  e = $(dom_id)
  var show = ! e.visible()
  dispatch({controller: 'log', action: 'log', revisions: e.readAttribute("revisions"), git_path: e.readAttribute("git_path"), path: (e.readAttribute("path") || ""), layout: false}).then(function(html) {
    e.update(html)
    set_togglable_visibility( dom_id, show );
  })
}
