import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var hermesService: pluginApi?.mainInstance?.hermesService || null

  property ShellScreen screen
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 240 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  readonly property string status: hermesService?.status ?? "unknown"
  readonly property bool cliActive: hermesService?.cliActive ?? false
  readonly property string gatewayPid: hermesService?.gatewayPid ?? ""
  readonly property string signalEvent: hermesService?.signalEvent ?? ""
  readonly property var platforms: hermesService?.platforms ?? ({})

  readonly property string statusText: {
    switch (status) {
      case "offline":    return "Offline";
      case "idle":       return "Online";
      case "busy":       return "Working";
      case "attention":  return "Needs You";
      case "degraded":   return "Degraded";
      case "error":      return "Error";
      default:           return "Unknown";
    }
  }

  readonly property string statusIcon: {
    switch (status) {
      case "offline":    return "power";
      case "idle":       return "circle-check";
      case "busy":       return "loader";
      case "attention":  return "bell-ringing";
      case "degraded":   return "alert-circle";
      case "error":      return "alert-triangle";
      default:           return "help-circle";
    }
  }

  readonly property color statusColor: {
    switch (status) {
      case "offline":    return Color.mError;
      case "idle":       return Color.mPrimary;
      case "busy":       return Color.mPrimary;
      case "attention":  return "#f59e0b";
      case "degraded":   return "#f97316";
      case "error":      return Color.mError;
      default:           return Color.mOnSurface;
    }
  }

  readonly property string eventText: {
    var map = {
      "pre_llm_call": "Thinking",
      "post_llm_call": "Processing",
      "pre_tool_call": "Tool call",
      "post_tool_call": "Tool done",
      "pre_approval_request": "Awaiting approval",
      "on_session_start": "Started",
      "on_session_end": "Ended"
    };
    return map[signalEvent] || "";
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    NBox {
      anchors.fill: parent
      anchors.margins: Style.marginS

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: 4

        // Row 1: icon + name + status
        RowLayout {
          spacing: Style.marginS

          NIcon {
            icon: root.statusIcon
            color: root.statusColor
            pointSize: Style.fontSizeM
          }

          NText {
            text: "Hermes"
            font.weight: Font.Bold
            pointSize: Style.fontSizeS
            color: Color.mOnSurface
          }

          NText {
            text: root.statusText
            pointSize: Style.fontSizeS
            color: root.statusColor
          }

          Item { Layout.fillWidth: true }

          NText {
            text: root.eventText
            pointSize: Style.fontSizeS
            color: Color.mOnSurface
            opacity: 0.5
            visible: text !== ""
          }
        }

        // Separator
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 1
          color: Color.mOutline
          opacity: 0.2
        }

        // Row 2: Gateway
        RowLayout {
          spacing: Style.marginS

          NText {
            text: "Gateway"
            pointSize: Style.fontSizeS
            color: Color.mOnSurface
            opacity: 0.5
            Layout.preferredWidth: 60
          }

          NText {
            text: gatewayPid ? "PID " + gatewayPid : "Stopped"
            pointSize: Style.fontSizeS
            color: gatewayPid ? Color.mOnSurface : Color.mError
          }
        }

        // Row 3: Session
        RowLayout {
          spacing: Style.marginS

          NText {
            text: "Session"
            pointSize: Style.fontSizeS
            color: Color.mOnSurface
            opacity: 0.5
            Layout.preferredWidth: 60
          }

          NText {
            text: cliActive ? "Active" : "None"
            pointSize: Style.fontSizeS
            opacity: cliActive ? 1.0 : 0.4
          }
        }

        // Row 4+: Platforms
        Repeater {
          model: {
            var items = [];
            for (var key in root.platforms) {
              items.push({
                "name": key.charAt(0).toUpperCase() + key.slice(1),
                "ok": root.platforms[key]?.state === "connected"
              });
            }
            return items;
          }

          delegate: RowLayout {
            spacing: Style.marginS

            NText {
              text: modelData.name
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              opacity: 0.5
              Layout.preferredWidth: 60
            }

            NText {
              text: modelData.ok ? "Online" : "Offline"
              pointSize: Style.fontSizeS
              color: modelData.ok ? Color.mPrimary : Color.mError
            }
          }
        }
      }
    }
  }
}
