import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  // Expose service to bar widget
  property alias hermesService: hermesService

  QtObject {
    id: hermesService

    // Gateway state
    property string gatewayState: "unknown"   // "running", "stopped", "unknown"
    property int activeAgents: 0
    property var platforms: ({})
    property string pid: ""
    property string updatedAt: ""
    property string errorMessage: ""
    property string fetchState: "idle"  // "idle", "loading", "success", "error"

    // Attention flag (set by hook or manually)
    property bool needsAttention: false

    // Computed: overall status
    // "offline"    — gateway stopped
    // "idle"       — running, nothing happening
    // "busy"       — active_agents > 0
    // "attention"  — needs user input (approval/clarify)
    // "degraded"   — running but platform errors
    // "error"      — can't read state
    readonly property string status: {
      if (fetchState === "error") return "error";
      if (fetchState === "loading") return "loading";
      if (gatewayState !== "running") return "offline";
      if (needsAttention) return "attention";
      if (activeAgents > 0) return "busy";
      if (hasError) return "degraded";
      return "idle";
    }

    // Derived
    property int connectedCount: {
      var count = 0;
      for (var key in platforms) {
        if (platforms[key] && platforms[key].state === "connected") count++;
      }
      return count;
    }
    property int platformCount: {
      var count = 0;
      for (var key in platforms) { count++; }
      return count;
    }
    property bool hasError: {
      for (var key in platforms) {
        if (platforms[key] && platforms[key].state !== "connected") return true;
      }
      return false;
    }

    function refresh() {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var filePath = cfg.gatewayStateFile ?? defaults.gatewayStateFile;

      fetchState = "loading";
      fetchProcess.command = ["sh", "-c", "cat " + filePath];
      fetchProcess.running = true;

      // Also check attention flag
      var attentionPath = cfg.attentionFile ?? defaults.attentionFile;
      attentionProcess.command = ["sh", "-c", "test -f " + attentionPath + " && echo 1 || echo 0"];
      attentionProcess.running = true;
    }

    function clearAttention() {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var attentionPath = cfg.attentionFile ?? defaults.attentionFile;
      clearAttentionProcess.command = ["sh", "-c", "rm -f " + attentionPath];
      clearAttentionProcess.running = true;
      needsAttention = false;
    }
  }

  // Read gateway_state.json
  Process {
    id: fetchProcess
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        hermesService.fetchState = "error";
        hermesService.gatewayState = "unknown";
        hermesService.errorMessage = "Cannot read state file (exit " + exitCode + ")";
        return;
      }

      var response = stdout.text;
      if (!response || response.trim() === "") {
        hermesService.fetchState = "error";
        hermesService.errorMessage = "Empty state file";
        return;
      }

      try {
        var data = JSON.parse(response);
        hermesService.gatewayState = data.gateway_state || "unknown";
        hermesService.activeAgents = data.active_agents || 0;
        hermesService.platforms = data.platforms || {};
        hermesService.pid = data.pid ? data.pid.toString() : "";
        hermesService.updatedAt = data.updated_at || "";
        hermesService.fetchState = "success";
        hermesService.errorMessage = "";
      } catch (e) {
        hermesService.fetchState = "error";
        hermesService.errorMessage = "JSON parse error: " + e;
      }
    }
  }

  // Check attention flag file
  Process {
    id: attentionProcess
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      var result = stdout.text ? stdout.text.trim() : "";
      hermesService.needsAttention = (result === "1");
    }
  }

  // Clear attention flag
  Process {
    id: clearAttentionProcess
    stdout: StdioCollector {}
  }

  Timer {
    id: pollTimer
    repeat: true
    running: pluginApi !== null
    triggeredOnStart: true
    interval: {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var secs = cfg.pollInterval ?? defaults.pollInterval;
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
