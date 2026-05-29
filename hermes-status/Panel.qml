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
  property real contentPreferredWidth: 280 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  readonly property string status: hermesService?.status ?? "unknown"
  readonly property bool cliActive: hermesService?.cliActive ?? false
  readonly property string cliPid: hermesService?.cliPid ?? ""
  readonly property string gatewayPid: hermesService?.gatewayPid ?? ""
  readonly property var platforms: hermesService?.platforms ?? ({})
  readonly property int activeAgents: hermesService?.activeAgents ?? 0
  readonly property bool needsAttention: hermesService?.needsAttention ?? false
  readonly property string fetchState: hermesService?.fetchState ?? "idle"
  readonly property string signalEvent: hermesService?.signalEvent ?? ""
  readonly property string signalTs: hermesService?.signalTs ?? ""

  readonly property string statusText: {
    switch (status) {
      case "offline":    return "Offline";
      case "idle":       return "Online";
      case "busy":       return "Working...";
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

  readonly property string lastEventText: {
    if (!signalEvent) return "";
    var map = {
      "pre_llm_call": "Thinking...",
      "post_llm_call": "Processing response",
      "pre_tool_call": "Running tool",
      "post_tool_call": "Tool finished",
      "pre_approval_request": "Waiting for approval",
      "post_approval_response": "Continuing",
      "on_session_start": "Session started",
      "on_session_end": "Session ended",
      "on_session_finalize": "Session finalized"
    };
    return map[signalEvent] || signalEvent;
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      // ── Status header card ──
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: statusRow.implicitHeight + Style.marginM * 2

        RowLayout {
          id: statusRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NIcon {
            icon: root.statusIcon
            color: root.statusColor
            pointSize: Style.fontSizeXL
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            NText {
              text: "Hermes Agent"
              font.weight: Font.Bold
              pointSize: Style.fontSizeM
              color: Color.mOnSurface
            }

            NText {
              text: root.statusText
              pointSize: Style.fontSizeS
              color: root.statusColor
              font.weight: Font.DemiBold
            }
          }
        }
      }

      // ── Info rows ──
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: infoCol.implicitHeight + Style.marginM * 2

        ColumnLayout {
          id: infoCol
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          // Gateway
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIcon { icon: "server"; pointSize: Style.fontSizeS; color: Color.mOnSurface; opacity: 0.5 }

            NText {
              text: "Gateway"
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              opacity: 0.6
              Layout.preferredWidth: 70
            }

            NText {
              text: gatewayPid ? "PID " + gatewayPid : "Stopped"
              pointSize: Style.fontSizeS
              color: gatewayPid ? Color.mOnSurface : Color.mError
              Layout.fillWidth: true
            }
          }

          // CLI Session
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIcon { icon: "terminal"; pointSize: Style.fontSizeS; color: Color.mOnSurface; opacity: 0.5 }

            NText {
              text: "Session"
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              opacity: 0.6
              Layout.preferredWidth: 70
            }

            NText {
              text: cliActive ? (lastEventText || "Active") : "None"
              pointSize: Style.fontSizeS
              color: cliActive ? Color.mOnSurface : Color.mOnSurface
              opacity: cliActive ? 1.0 : 0.4
              Layout.fillWidth: true
            }
          }

          // Last event timestamp (when busy)
          RowLayout {
            Layout.fillWidth: true
            visible: signalTs !== ""
            spacing: Style.marginS

            NIcon { icon: "clock"; pointSize: Style.fontSizeS; color: Color.mOnSurface; opacity: 0.5 }

            NText {
              text: "Updated"
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              opacity: 0.6
              Layout.preferredWidth: 70
            }

            NText {
              text: {
                if (!signalTs) return "";
                var d = new Date(signalTs);
                return Qt.formatTime(d, "hh:mm:ss");
              }
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              Layout.fillWidth: true
            }
          }
        }
      }

      // ── Platforms ──
      NBox {
        Layout.fillWidth: true
        visible: Object.keys(root.platforms).length > 0
        Layout.preferredHeight: platCol.implicitHeight + Style.marginM * 2

        ColumnLayout {
          id: platCol
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          NText {
            text: "Platforms"
            pointSize: Style.fontSizeS
            font.weight: Font.DemiBold
            color: Color.mOnSurface
            opacity: 0.6
          }

          Repeater {
            model: {
              var items = [];
              for (var key in root.platforms) {
                var p = root.platforms[key];
                items.push({
                  "name": key.charAt(0).toUpperCase() + key.slice(1),
                  "state": p.state || "unknown"
                });
              }
              return items;
            }

            delegate: RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              Rectangle {
                width: 8; height: 8; radius: 4
                color: modelData.state === "connected" ? Color.mPrimary : Color.mError
              }

              NText {
                text: modelData.name
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
                Layout.fillWidth: true
              }

              NText {
                text: modelData.state === "connected" ? "✓" : "✗"
                pointSize: Style.fontSizeS
                color: modelData.state === "connected" ? Color.mPrimary : Color.mError
              }
            }
          }
        }
      }

      // ── Actions ──
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        // Dismiss attention
        NIconButton {
          icon: "bell-off"
          visible: root.needsAttention
          baseSize: Style.baseWidgetSize * 0.8
          onClicked: hermesService?.clearAttention()
          NText {
            anchors.left: parent.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: "Dismiss"
            pointSize: Style.fontSizeXS
            color: Color.mOnSurface
          }
        }

        Item { Layout.fillWidth: true }

        // Refresh
        NIconButton {
          icon: "refresh"
          baseSize: Style.baseWidgetSize * 0.8
          onClicked: hermesService?.refresh()
        }
      }
    }
  }
}
