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
  property real contentWidth: 320

  readonly property string status: hermesService?.status ?? "unknown"
  readonly property bool cliActive: hermesService?.cliActive ?? false
  readonly property bool cliBusy: hermesService?.cliBusy ?? false
  readonly property string cliPid: hermesService?.cliPid ?? ""
  readonly property string gatewayPid: hermesService?.gatewayPid ?? ""
  readonly property var platforms: hermesService?.platforms ?? ({})
  readonly property int activeAgents: hermesService?.activeAgents ?? 0
  readonly property bool needsAttention: hermesService?.needsAttention ?? false
  readonly property string fetchState: hermesService?.fetchState ?? "idle"
  readonly property string errorMessage: hermesService?.errorMessage ?? ""

  readonly property string statusLabel: {
    switch (status) {
      case "offline":    return "● Offline";
      case "idle":       return "● Online";
      case "busy":       return "● Busy";
      case "attention":  return "● Needs You";
      case "degraded":   return "● Degraded";
      case "error":      return "● Error";
      default:           return "● Unknown";
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

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginM

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: "⚕ Hermes Agent"
        font.weight: Font.Bold
        font.pixelSize: Style.fontSizeL
        color: Color.mOnSurface
      }

      Item { Layout.fillWidth: true }

      NText {
        text: root.statusLabel
        font.pixelSize: Style.fontSizeS
        color: root.statusColor
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Color.mOutline
      opacity: 0.3
    }

    // Error banner
    Rectangle {
      Layout.fillWidth: true
      visible: fetchState === "error"
      radius: Style.radiusS
      height: visible ? errRow.height + Style.marginS * 2 : 0

      RowLayout {
        id: errRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Style.marginS
        anchors.verticalCenter: parent.verticalCenter

        NText {
          text: "⚠ " + root.errorMessage
          font.pixelSize: Style.fontSizeS
          color: Color.mError
          Layout.fillWidth: true
          wrapMode: Text.Wrap
        }
      }
    }

    // Info rows
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      Repeater {
        model: {
          var rows = [];
          rows.push({ "label": "Gateway", "value": gatewayPid ? "Running (PID " + gatewayPid + ")" : "Stopped" });
          rows.push({ "label": "CLI Session", "value": cliActive ? (cliBusy ? "Processing..." : "Active (PID " + cliPid + ")") : "None" });
          if (activeAgents > 0) {
            rows.push({ "label": "Sessions", "value": activeAgents + " active" });
          }
          if (needsAttention) {
            rows.push({ "label": "Status", "value": "Waiting for your input" });
          }
          return rows;
        }

        delegate: RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NText {
            text: modelData.label
            font.pixelSize: Style.fontSizeS
            color: Color.mOnSurface
            opacity: 0.6
            Layout.preferredWidth: 90
          }

          NText {
            text: modelData.value
            font.pixelSize: Style.fontSizeS
            color: Color.mOnSurface
            Layout.fillWidth: true
          }
        }
      }
    }

    // Platforms
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS
      visible: Object.keys(root.platforms).length > 0

      NText {
        text: "Platforms"
        font.pixelSize: Style.fontSizeS
        font.weight: Font.DemiBold
        color: Color.mOnSurface
      }

      Repeater {
        model: {
          var items = [];
          for (var key in root.platforms) {
            var p = root.platforms[key];
            items.push({
              "name": key.charAt(0).toUpperCase() + key.slice(1),
              "state": p.state || "unknown",
              "error": p.error_message || ""
            });
          }
          return items;
        }

        delegate: RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Rectangle {
            width: 8
            height: 8
            radius: 4
            color: modelData.state === "connected" ? Color.mPrimary : Color.mError
          }

          NText {
            text: modelData.name
            font.pixelSize: Style.fontSizeS
            color: Color.mOnSurface
            Layout.preferredWidth: 80
          }

          NText {
            text: modelData.state === "connected" ? "Connected" : (modelData.error || modelData.state)
            font.pixelSize: Style.fontSizeS
            color: modelData.state === "connected" ? Color.mOnSurface : Color.mError
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }
      }
    }

    // Actions
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      Item { Layout.fillWidth: true }

      NText {
        text: "🔕 Dismiss"
        font.pixelSize: Style.fontSizeS
        color: root.needsAttention ? Color.mOnSurface : "transparent"
        visible: root.needsAttention

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: hermesService?.clearAttention()
        }
      }

      NText {
        text: "↻ Refresh"
        font.pixelSize: Style.fontSizeS
        color: Color.mPrimary

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: hermesService?.refresh()
        }
      }
    }
  }
}
