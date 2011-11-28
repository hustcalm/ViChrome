(function() {
  var escape, g, passToTopFrame, sendToBackground, triggerInsideContent, _ref;
  var __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  if ((_ref = this.vichrome) == null) this.vichrome = {};

  g = this.vichrome;

  sendToBackground = function(com, args, times, timesSpecified) {
    return chrome.extension.sendRequest({
      command: com,
      args: args,
      times: times,
      timesSpecified: timesSpecified
    }, function(msg) {
      return g.handler.onCommandResponse(msg);
    });
  };

  triggerInsideContent = function(com, args, times, timesSpecified) {
    return g.model.triggerCommand("req" + com, args, times, timesSpecified);
  };

  passToTopFrame = function(com, args, times, timesSpecified) {
    return chrome.extension.sendRequest({
      command: "TopFrame",
      innerCommand: com,
      args: args,
      times: times,
      timesSpecified: timesSpecified,
      senderFrameID: g.model.frameID
    }, g.handler.onCommandResponse);
  };

  escape = function(com) {
    return triggerInsideContent("Escape");
  };

  g.CommandExecuter = (function() {

    function CommandExecuter() {}

    CommandExecuter.prototype.commandsBeforeReady = ["OpenNewTab", "CloseCurTab", "MoveToNextTab", "MoveToPrevTab", "MoveToFirstTab", "MoveToLastTab", "NMap", "IMap", "Alias", "OpenNewWindow", "OpenOptionPage", "RestoreTab"];

    CommandExecuter.prototype.commandTable = {
      Open: passToTopFrame,
      OpenNewTab: passToTopFrame,
      CloseCurTab: sendToBackground,
      CloseAllTabs: sendToBackground,
      MoveToNextTab: sendToBackground,
      MoveToPrevTab: sendToBackground,
      MoveToFirstTab: sendToBackground,
      MoveToLastTab: sendToBackground,
      NMap: sendToBackground,
      IMap: sendToBackground,
      Alias: sendToBackground,
      OpenNewWindow: sendToBackground,
      ReloadTab: triggerInsideContent,
      ScrollUp: triggerInsideContent,
      ScrollDown: triggerInsideContent,
      ScrollLeft: triggerInsideContent,
      ScrollRight: triggerInsideContent,
      PageHalfUp: triggerInsideContent,
      PageHalfDown: triggerInsideContent,
      PageUp: triggerInsideContent,
      PageDown: triggerInsideContent,
      GoTop: triggerInsideContent,
      GoBottom: triggerInsideContent,
      NextSearch: triggerInsideContent,
      PrevSearch: triggerInsideContent,
      BackHist: triggerInsideContent,
      ForwardHist: triggerInsideContent,
      GoCommandMode: triggerInsideContent,
      GoSearchModeForward: triggerInsideContent,
      GoSearchModeBackward: triggerInsideContent,
      GoLinkTextSearchMode: triggerInsideContent,
      GoFMode: triggerInsideContent,
      GoEmergencyMode: triggerInsideContent,
      FocusOnFirstInput: triggerInsideContent,
      BackToPageMark: triggerInsideContent,
      RestoreTab: sendToBackground,
      FocusNextCandidate: triggerInsideContent,
      FocusPrevCandidate: triggerInsideContent,
      Readability: sendToBackground,
      ShowTabList: triggerInsideContent,
      OpenOptionPage: sendToBackground,
      BarrelRoll: triggerInsideContent,
      Copy: sendToBackground,
      Escape: escape,
      HideJimmy: triggerInsideContent,
      "_ChangeLogLevel": triggerInsideContent
    };

    CommandExecuter.prototype.get = function() {
      var _ref2;
      return (_ref2 = this.command) != null ? _ref2 : "";
    };

    CommandExecuter.prototype.getArgs = function() {
      return this.args;
    };

    CommandExecuter.prototype.setDescription = function(description) {
      this.description = description;
      return this;
    };

    CommandExecuter.prototype.getDescription = function() {
      return this.description;
    };

    CommandExecuter.prototype.reset = function() {
      return this.command = null;
    };

    CommandExecuter.prototype.set = function(command, times) {
      if (this.command != null) {
        this.command += " ";
      } else {
        this.command = "";
      }
      this.command += command.replace(/^[\t ]*/, "").replace(/[\t ]*$/, "");
      this.times = times != null ? times : 1;
      this.timesSpecified = times != null ? true : false;
      return this;
    };

    CommandExecuter.prototype.delimLine = function(line) {
      var c, len, pos, pre, result, start;
      result = [];
      pos = 0;
      pre = 0;
      len = line.length;
      while (pos < len) {
        c = line.charAt(pos);
        switch (c) {
          case " ":
            result.push(line.slice(pre, pos));
            while (line.charAt(pos) === " ") {
              ++pos;
            }
            pre = pos;
            break;
          case "'":
          case "\"":
            start = pos;
            while (line.charAt(++pos) !== c) {
              if (pos >= len) {
                pos = start;
                break;
              }
            }
            ++pos;
            break;
          default:
            ++pos;
        }
      }
      result.push(line.slice(pre, pos));
      return result;
    };

    CommandExecuter.prototype.solveAlias = function(alias) {
      var aliases, command;
      aliases = g.model.getAlias();
      alias = aliases[alias];
      while (alias != null) {
        command = alias;
        alias = aliases[alias];
      }
      return command;
    };

    CommandExecuter.prototype.parse = function() {
      var command, i, _ref2;
      if (!this.command) throw "invalid command";
      this.args = this.delimLine(this.command);
      for (i = _ref2 = this.args.length - 1; _ref2 <= 0 ? i <= 0 : i >= 0; _ref2 <= 0 ? i++ : i--) {
        if (this.args[i].length === 0) this.args.splice(i, 1);
      }
      command = this.solveAlias(this.args[0]);
      if (command != null) {
        this.args = this.delimLine(command).concat(this.args.slice(1));
      }
      if (this.commandTable[this.args[0]]) {
        return this;
      } else {
        throw "invalid command";
      }
    };

    CommandExecuter.prototype.execute = function() {
      var com;
      var _this = this;
      com = this.args[0];
      if (!(g.model.isReady() || __indexOf.call(this.commandsBeforeReady, com) >= 0)) {
        return;
      }
      return setTimeout(function() {
        return _this.commandTable[com](com, _this.args.slice(1), _this.times, _this.timesSpecified);
      }, 0);
    };

    return CommandExecuter;

  })();

  g.CommandManager = (function() {

    CommandManager.prototype.keyQueue = {
      init: function(model, timeout, enableMulti) {
        this.model = model;
        this.timeout = timeout;
        this.enableMulti = enableMulti != null ? enableMulti : true;
        this.a = "";
        this.times = "";
        this.timerId = 0;
        return this.waiting = false;
      },
      stopTimer: function() {
        if (this.waiting) {
          g.logger.d("stop timeout");
          clearTimeout(this.timerId);
          return this.waiting = false;
        }
      },
      startTimer: function(callback, ms) {
        if (this.waiting) return;
        this.waiting = true;
        return this.timerId = setTimeout(callback, ms);
      },
      queue: function(s) {
        if (this.enableMulti && s.length === 1 && s.search(/[0-9]/) >= 0 && this.a.length === 0) {
          this.times += s;
        } else {
          this.a += s;
        }
        return this;
      },
      reset: function() {
        this.a = "";
        this.times = "";
        return this.stopTimer();
      },
      isWaiting: function() {
        return this.waiting;
      },
      getTimes: function() {
        if (this.times.length > 0) {
          return parseInt(this.times, 10);
        } else {
          return null;
        }
      },
      getNextKeySequence: function() {
        var ret;
        var _this = this;
        this.stopTimer();
        if (this.model.isValidKeySeq(this.a)) {
          ret = this.a;
          this.reset();
          return ret;
        } else {
          if (this.model.isValidKeySeqAvailable(this.a)) {
            this.startTimer(function() {
              _this.a = "";
              _this.times = "";
              return _this.waiting = false;
            }, this.timeout);
          } else {
            g.logger.d("invalid key sequence: " + this.a);
            this.reset();
          }
          return null;
        }
      }
    };

    function CommandManager(model, timeout, enableMulti) {
      this.model = model;
      if (enableMulti == null) enableMulti = true;
      this.keyQueue.init(this.model, timeout, enableMulti);
    }

    CommandManager.prototype.getCommandFromKeySeq = function(s, keyMap) {
      var keySeq;
      this.keyQueue.queue(s);
      keySeq = this.keyQueue.getNextKeySequence();
      if (keyMap && keySeq) {
        return keyMap[keySeq];
      } else {
        return null;
      }
    };

    CommandManager.prototype.reset = function() {
      return this.keyQueue.reset();
    };

    CommandManager.prototype.isWaitingNextKey = function() {
      return this.keyQueue.isWaiting();
    };

    CommandManager.prototype.handleKey = function(msg, keyMap) {
      var com, s, times;
      s = g.KeyManager.getKeyCodeStr(msg);
      times = this.keyQueue.getTimes();
      com = this.getCommandFromKeySeq(s, keyMap);
      if (!com) {
        if (this.isWaitingNextKey()) {
          event.stopPropagation();
          event.preventDefault();
        }
        return;
      }
      switch (com) {
        case "<NOP>":
          break;
        case "<DISCARD>":
          event.stopPropagation();
          return event.preventDefault();
        default:
          (new g.CommandExecuter).set(com, times).parse().execute();
          event.stopPropagation();
          return event.preventDefault();
      }
    };

    return CommandManager;

  })();

}).call(this);
