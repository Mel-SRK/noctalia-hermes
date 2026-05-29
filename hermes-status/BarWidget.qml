import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var hermesService: pluginApi?.mainInstance?.hermesService || null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor
  readonly property bool hideWhenRunning: cfg.hideWhenRunning ?? defaults.hideWhenRunning
  readonly property bool showAgentCount: (cfg.showAgentCount ?? defaults.showAgentCount) !== false

  readonly property string gwState: hermesService?.gatewayState ?? "unknown"
  readonly property int activeAgents: hermesService?.activeAgents ?? 0
  readonly property string fetchState: hermesService?.fetchState ?? "idle"
  readonly property bool hasError: hermesService?.hasError ?? false

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"

  readonly property string currentIcon: {
    if (fetchState === "loading") return "loader";
    if (fetchState === "error") return "alert-triangle";
    if (gwState === "stopped") return "circle-x";
    if (gwState === "running" && hasError) return "alert-circle";
    if (gwState === "running") return "circle-check";
    return "help-circle";
  }

  readonly property color iconColor: {
    if (fetchState === "error") return Color.mError;
    if (gwState === "stopped") return Color.mError;
    if (hasError) return Color.mWarning ?? Color.mOnSurface;
    if (gwState === "running") return Color.mPrimary;
    return Color.resolveColorKey(iconColorKey);
  }

  readonly property string displayText: {
    if (showAgentCount && activeAgents > 0) return activeAgents.toString();
    if (showAgentCount && hasError) return "!";
    return "";
  }

  readonly property bool shouldHide: hideWhenRunning && gwState === "running" && !hasError

  implicitWidth: shouldHide ? 0 : pill.width
  implicitHeight: shouldHide ? 0 : pill.height
  visible: !shouldHide

  BarPill {
    id: pill
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    icon: root.currentIcon
    text: root.displayText
    forceOpen: root.displayText !== ""
    autoHide: true
    customTextIconColor: root.iconColor

    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }

    onRightClicked: {
      PanelService.showContextMenu(contextMenu, root, screen);
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("menu.refresh") ?? "Refresh",
        "action": "refresh",
        "icon": "refresh"
      },
      {
        "label": pluginApi?.tr("menu.open-hermes") ?? "Open Hermes",
        "action": "open-terminal",
        "icon": "terminal"
      },
      {
        "label": pluginApi?.tr("menu.settings") ?? "Settings",
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: function(action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "refresh") {
        hermesService?.refresh();
      } else if (action === "open-terminal") {
        // Open a terminal with hermes chat
        var cfg = pluginApi?.pluginSettings || {};
        ProcessManager.startDetached(["sh", "-c", "$TERMINAL -e hermes gateway status &"]);
      } else if (action === "settings") {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }
}
