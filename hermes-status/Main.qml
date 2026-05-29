import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  // Expose service to bar widget
  property alias hermesService: hermesService

  // Path to the status check script
  readonly property string scriptPath: {
    var cfg = pluginApi?.pluginSettings || {};
    var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
    var p = cfg.statusScript ?? defaults.statusScript ?? "~/.config/noctalia/plugins/hermes-status/../hermes-status-check";
    return p.replace("~", "/home/srk");
  }

  QtObject {
    id: hermesService

    property string status: "idle"       // offline|idle|busy|attention|degraded|error|loading
    property string gatewayPid: ""
    property string cliPid: ""
    property bool cliActive: false
    property bool cliBusy: false
    property bool needsAttention: false
    property int activeAgents: 0
    property var platforms: ({})
    property string fetchState: "idle"
    property string errorMessage: ""

    property bool hasError: {
      for (var key in platforms) {
        if (platforms[key] && platforms[key].state !== "connected") return true;
      }
      return false;
    }

    function refresh() {
      fetchState = "loading";
      statusProcess.command = ["sh", "-c", root.scriptPath];
      statusProcess.running = true;
    }

    function clearAttention() {
      needsAttention = false;
      clearAttentionProcess.command = ["sh", "-c", "rm -f /home/srk/.hermes/needs_attention"];
      clearAttentionProcess.running = true;
    }
  }

  // Status check process
  Process {
    id: statusProcess
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        hermesService.fetchState = "error";
        hermesService.status = "error";
        hermesService.errorMessage = "Script failed (exit " + exitCode + ")";
        return;
      }

      var response = stdout.text;
      if (!response || response.trim() === "") {
        hermesService.fetchState = "error";
        hermesService.status = "error";
        hermesService.errorMessage = "Empty response";
        return;
      }

      try {
        var data = JSON.parse(response);
        hermesService.status = data.status || "unknown";
        hermesService.gatewayPid = data.gateway_pid || "";
        hermesService.cliPid = data.cli_pid || "";
        hermesService.cliActive = data.cli_active || false;
        hermesService.cliBusy = data.cli_busy || false;
        hermesService.needsAttention = data.needs_attention || false;
        hermesService.activeAgents = data.active_agents || 0;
        hermesService.platforms = data.platforms || {};
        hermesService.fetchState = "success";
        hermesService.errorMessage = "";
      } catch (e) {
        hermesService.fetchState = "error";
        hermesService.status = "error";
        hermesService.errorMessage = "JSON parse error: " + e;
      }
    }
  }

  // Clear attention process
  Process {
    id: clearAttentionProcess
    stdout: StdioCollector {}
  }

  // Poll timer — runs independently of pluginApi
  Timer {
    id: pollTimer
    repeat: true
    running: true
    triggeredOnStart: true
    interval: {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var secs = cfg.pollInterval ?? defaults.pollInterval ?? 10;
      return secs * 1000;
    }
    onTriggered: hermesService.refresh()
  }

  IpcHandler {
    target: "plugin:hermes-status"
    function refresh() {
      hermesService.refresh();
    }
    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function(screen) {
          pluginApi.togglePanel(screen);
        });
      }
    }
  }
}
