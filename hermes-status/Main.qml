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
    property string gatewayState: "unknown"
    property int activeAgents: 0
    property var platforms: ({})
    property string pid: ""
    property string updatedAt: ""
    property string errorMessage: ""
    property string fetchState: "idle"

    // Attention flag
    property bool needsAttention: false

    // Overall status
    readonly property string status: {
      if (fetchState === "error") return "error";
      if (fetchState === "loading") return "loading";
      if (gatewayState !== "running") return "offline";
      if (needsAttention) return "attention";
      if (activeAgents > 0) return "busy";
      if (hasError) return "degraded";
      return "idle";
    }

    property bool hasError: {
      for (var key in platforms) {
        if (platforms[key] && platforms[key].state !== "connected") return true;
      }
      return false;
    }

    function parseState(text) {
      try {
        var data = JSON.parse(text);
        gatewayState = data.gateway_state || "unknown";
        activeAgents = data.active_agents || 0;
        platforms = data.platforms || {};
        pid = data.pid ? data.pid.toString() : "";
        updatedAt = data.updated_at || "";
        fetchState = "success";
        errorMessage = "";
      } catch (e) {
        fetchState = "error";
        errorMessage = "JSON parse error: " + e;
      }
    }

    function clearAttention() {
      needsAttention = false;
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var path = cfg.attentionFile ?? defaults.attentionFile;
      clearAttentionProcess.command = ["sh", "-c", "rm -f " + path];
      clearAttentionProcess.running = true;
    }
  }

  // ── Watch gateway_state.json via FileView ──
  property string stateFilePath: {
    var cfg = pluginApi?.pluginSettings || {};
    var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
    var f = cfg.gatewayStateFile ?? defaults.gatewayStateFile ?? "~/.hermes/gateway_state.json";
    return "file://" + f.replace("~", Qt.resolvedUrl("~").toString().replace("file://", "").replace("/~", ""));
  }

  FileView {
    id: stateFileView
    path: {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var f = cfg.gatewayStateFile ?? defaults.gatewayStateFile ?? "~/.hermes/gateway_state.json";
      return "file://" + f.replace("~", "/home/srk");
    }
    watchChanges: true
    printErrors: false

    onFileChanged: {
      reload();
    }

    onLoaded: {
      var content = text();
      if (content && content.trim() !== "") {
        hermesService.parseState(content);
      } else {
        hermesService.fetchState = "error";
        hermesService.errorMessage = "Empty state file";
      }
    }
  }

  // ── Watch attention flag file ──
  FileView {
    id: attentionFileView
    path: {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var f = cfg.attentionFile ?? defaults.attentionFile ?? "~/.hermes/needs_attention";
      return "file://" + f.replace("~", "/home/srk");
    }
    watchChanges: true
    printErrors: false

    onFileChanged: {
      reload();
    }

    onLoaded: {
      hermesService.needsAttention = true;
    }
  }

  // ── Polling fallback (in case file watching doesn't trigger) ──
  Timer {
    id: pollTimer
    repeat: true
    running: pluginApi !== null
    triggeredOnStart: true
    interval: {
      var cfg = pluginApi?.pluginSettings || {};
      var defaults = pluginApi?.manifest?.metadata?.defaultSettings || {};
      var secs = cfg.pollInterval ?? defaults.pollInterval ?? 10;
      return secs * 1000;
    }
    onTriggered: {
      // Force reload both files
      stateFileView.reload();
      attentionFileView.reload();
    }
  }

  // Clear attention process
  Process {
    id: clearAttentionProcess
    stdout: StdioCollector {}
  }

  IpcHandler {
    target: "plugin:hermes-status"
    function refresh() {
      stateFileView.reload();
      attentionFileView.reload();
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
