var path = require('path');
var sockjs = require('sockjs');
var express = require('express');
var nunjucks = require('nunjucks');
var body_parser = require('body-parser');
var child_process = require('child_process');

function streamCmd(cmd, output_fn, callback) {
  console.log("INFO: streaming `" + cmd.join(" ") + "`");

  try {
    var proc = child_process.spawn(cmd[0], cmd.slice(1), {});
  } catch (err) {
    return callback(err);
  }

  proc.stdout.on('data', function(data) {
    output_fn("" + data);
  });

  proc.on('error', function(err) {
    callback(err);
  });

  proc.on('close', function(code) {
    var err;

    if (code) {
      err = new Error('process exited with non 0 exit code: ' + code);
    } else {
      err = null;
    }

    callback(err);
  });
}

function runCmd(cmd, callback) {
  console.log("INFO: running `" + cmd.join(" ") + "`");

  try {
    var proc = child_process.spawn(cmd[0], cmd.slice(1), {});
  } catch (err) {
    return callback(err);
  }

  var output = "";

  proc.stdout.on('data', function(data) {
    output += data;
  });

  proc.on('error', function(err) {
    callback(err);
  });

  proc.on('close', function(code) {
    var data;

    try{
      data = JSON.parse(output);
    } catch (err) {
      return callback(err, {});
    }

    var err = null;

    if (code) {
      if (data && data.error){
        err = new Error(data.error);
      } else {
        err = new Error('process exited with non 0 exit code: ' + code);
      }
    }

    callback(err, data);
  });
}

function parseArgs(subcommand, flags, positional) {
  var cmd = ['conda', subcommand, '--json'];

  function convert(key) {
    key = key.replace(/([A-Z])/g, function(match, letter) {
      return "-" + letter.toLowerCase();
    });

    return "--" + key;
  }

  for (var key in flags) {
    var value = flags[key];

    if      (value === 'true')  value = true;
    else if (value === 'false') value = false;
    else if (value === 'null')  value = null;

    if (value !== false && value !== null) {
      cmd.push(convert(key));

      if (Array.isArray(value)) {
        value.forEach(function(v) { cmd.push("" + v); });
      } else if (value !== true) {
        cmd.push("" + value);
      }
    }
  }

  if (Array.isArray(positional)) {
    positional.forEach(function(v) { cmd.push(v); });
  } else {
    cmd.push(positional);
  }

  return cmd;
}

var app = express();

var templateDir = path.resolve(__dirname, 'templates');
var env = nunjucks.configure(templateDir, {
  autoescape: true,
  express: app,
});

var port = 4889;
console.log('INFO: listening on 0.0.0.0:' + port);
var server = app.listen(port, '0.0.0.0');

var condajs_ws = sockjs.createServer();
condajs_ws.installHandlers(server, {
  prefix: '/condajs_ws',
  log: function(severity, line) { console.log("INFO: " + line) },
});

function static_fn(url) {
  return '/static/' + url;
}

var staticDir = path.resolve(__dirname, 'static');
app.use('/static', express.static(staticDir));

app.use(body_parser.json());

app.get('/', function(req, res) {
  res.render('index.html', {"static": static_fn});
});

function condajs(flags_fn) {
  return function(req, res) {
    var subcommand = req.params.subcommand;
    var flags = flags_fn(req);

    var positional = [];
    if (flags.hasOwnProperty('positional')) {
      positional = flags.positional;
      delete flags.positional;
    }

    var cmd = parseArgs(subcommand, flags, positional);
    runCmd(cmd, function(err, data) {
      if (err) {
        res.status(500);
      } else {
        res.json(data);
      }
    });
  };
}

app.route('/condajs/:subcommand')
   .get(condajs(function(req) { return req.query; }))
   .post(condajs(function(req) { return req.body; }));

condajs_ws.on('connection', function(conn) {
  conn.on('data', function(message) {
    var msg = JSON.parse(message);
    var cmd = parseArgs(msg.subcommand, msg.flags, msg.positional);

    streamCmd(cmd, function(output) {
      output.split("\u0000").forEach(function(line) {
        if (line.trim().length > 0) {
          var data = JSON.parse(line);
          var result;

          if (data.progress !== undefined) {
            result = { 'progress': data };
          } else {
            result = { 'finished': data };
          }

          conn.write(JSON.stringify(result));
        }
      });
    }, function(err) {});
  });
});
