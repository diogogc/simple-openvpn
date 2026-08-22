import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property string scriptPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.diogogc.simple-openvpn/scripts/openvpn-ctl"

  property bool connected: false
  property string iface: ""
  property string ip: ""
  property string config: ""
  property string configName: ""
  property string configDir: ""
  property var configs: []
  property var authConfigs: []
  property bool hasAuth: false
  property string username: ""
  property string bytesText: ""
  property string statusSummary: ""
  property string logTail: ""
  property string lastError: ""

  property bool busy: controlProc.running || statusProc.running || pickerProc.running
  property int _optimisticState: -1 // -1 = follow real, 1 = connecting, 0 = disconnecting
  readonly property bool active: _optimisticState === -1 ? connected : (_optimisticState === 1)

  function hasSavedAuthFor(path) {
    if (!authConfigs || authConfigs.length === 0) return false
    return authConfigs.indexOf(path) !== -1
  }

  function refresh() {
    if (statusProc.running) return
    statusProc.command = [scriptPath, "status"]
    statusProc.running = true
  }

  function toggle() {
    _optimisticState = connected ? 0 : 1
    runControl(connected ? "disconnect" : "connect")
  }

  function connectVpn() {
    _optimisticState = 1
    runControl("connect")
  }

  function disconnectVpn() {
    _optimisticState = 0
    runControl("disconnect")
  }

  function setConfig(path) {
    runControl("set_config", [path])
  }

  function pickConfigFile() {
    if (pickerProc.running) return
    pickerProc.command = [scriptPath, "pick_file"]
    pickerProc.running = true
  }

  function addProfile() {
    if (pickerProc.running) return
    pickerProc.command = [scriptPath, "add_profile"]
    pickerProc.running = true
  }

  function openFolder() {
    runControl("open_folder")
  }

  function setCredentials(user, pass) {
    runControl("set_credentials", [user, pass, root.config])
  }

  function clearCredentials() {
    runControl("clear_credentials", [root.config])
  }

  function runControl(action, extraArgs) {
    if (controlProc.running) return
    var cmd = [scriptPath, action]
    if (extraArgs && extraArgs.length > 0) {
      for (var i = 0; i < extraArgs.length; i++) {
        cmd.push(extraArgs[i])
      }
    }
    controlProc.command = cmd
    controlProc.running = true
  }

  function parseStatus(raw) {
    try {
      var data = JSON.parse(raw)
      root.connected = data.connected === true
      root.iface = String(data.iface || "")
      root.ip = String(data.ip || "")
      root.config = String(data.config || "")
      root.configName = String(data.config_name || "")
      root.configDir = String(data.config_dir || "")
      root.configs = data.configs || []
      root.authConfigs = data.auth_configs || []
      root.hasAuth = data.has_auth === true
      root.username = String(data.username || "")
      root.bytesText = String(data.bytes_text || "")
      root.statusSummary = String(data.status_summary || "")
      root.logTail = String(data.log_tail || "")

      if (root._optimisticState !== -1 && root.connected === (root._optimisticState === 1)) {
        root._optimisticState = -1
      }
      root.lastError = ""
    } catch (e) {
      console.warn("SimpleOpenVPN parseStatus error: " + e)
    }
  }

  Timer {
    id: pollTimer
    interval: 2500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  property string _statusBuf: ""

  Process {
    id: statusProc
    command: [root.scriptPath, "status"]
    stdout: SplitParser {
      onRead: function(line) {
        root._statusBuf += line + "\n"
      }
    }
    onRunningChanged: {
      if (running) {
        root._statusBuf = ""
      } else {
        if (root._statusBuf.trim().length > 0) {
          root.parseStatus(root._statusBuf.trim())
        }
      }
    }
  }

  Process {
    id: controlProc
    onRunningChanged: {
      if (!running) {
        Qt.callLater(function() { root.refresh() })
      }
    }
  }

  Process {
    id: pickerProc
    onRunningChanged: {
      if (!running) {
        Qt.callLater(function() { root.refresh() })
      }
    }
  }

  Component.onCompleted: {
    refresh()
  }
}
