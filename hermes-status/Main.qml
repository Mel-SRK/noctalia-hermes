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

    // Parsed state
    property string gatewayState: "unknown"   // "running", "stopped", "unknown"
    property int activeAgents: 0
    property var platforms: ({})
    property string pid: ""
    property string updatedAt: ""
    property string errorMessage: ""
    property string fetchState: "idle"  // "idle", "loading", "success", "error"

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
      // Expand ~ to home
      var home = StandardPaths.writableLocation(StandardPaths.HomeLocation);
      filePath = filePath.replace("~", home);

      fetchState = "loading";
      fetchProcess.command = ["cat", filePath];
      fetchProcess.running = true;
    }
  }

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
        Logger.e("HermesStatus", "Failed to parse state:", e);
      }
    }
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
