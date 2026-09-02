/* Git JS gateway */
/* Tim Harper (tim.harper at leadmediapartners.org) */

/* TextMate.system() is asynchronous, so every helper here returns a promise that
   resolves to the command's standard output. Callers update the page in then(). */

function e_sh(str) { 
  return '"' + (str.toString().gsub('"', '\\"').gsub('\\$', '\\$')) + '"';
}

function exec(command, params) {
  params = params.map(function(a) { return e_sh(a) }).join(" ")
  return TextMate.system(command + " " + params, null)
}

/* A command that printed nothing but complained gets its complaint shown in the
   page, since a silently empty result is what made these failures invisible. */
function output_of(promise) {
  return promise.then(
    function(task) {
      if (task.outputString == "" && task.errorString != "")
        return "<pre class='error'>" + task.errorString.escapeHTML() + "</pre>"
      return task.outputString
    },
    function(err)  { return "ERROR!" + err }
  )
}

function gateway_command(command, params) {
  command = "ruby " + e_sh(TM_BUNDLE_SUPPORT) + "/gateway/" + command
  return output_of(exec(command, params))
}

function dispatch(params) {
  params = $H(params).map(function(pair) { return(pair.key + "=" + pair.value.toString())})
  command = "ruby " + e_sh(TM_BUNDLE_SUPPORT) + "/dispatch.rb";
  return output_of(exec(command, params))
}

function dispatch_streaming(iframe_target, options) {
  new StreamingDispatchExecuter(iframe_target, options);
  return false;
}

StreamingDispatchExecuter = Class.create();
StreamingDispatchExecuter.prototype = {
  initialize: function(iframe_target, options) {
    this.options = options;
    this.on_complete = options["on_complete"]
    params = options['params']
    params['streaming']="true"
    dispatch(params).then(function(output) {
      var parts = output.split(",")
      this.port = parts[0];
      this.pid = parts[1];
      $(iframe_target).src = "http://127.0.0.1:" + this.port + "/"
      this.wait_for_exit()
    }.bind(this))
  },

  wait_for_exit: function() {
    TextMate.system("kill -0 " + this.pid, function(task) {
      if (task.status == 1) {
        if (this.on_complete) this.on_complete();
      } else {
        setTimeout(this.wait_for_exit.bind(this), 500)
      }
    }.bind(this))
  },
}
