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

  readonly property string gwState: hermesService?.gatewayState ?? "unknown"
  readonly property int activeAgents: hermesService?.activeAgents ?? 0
  readonly property var platforms: hermesService?.platforms ?? ({})
  readonly property string pid: hermesService?.pid ?? ""
  readonly property string updatedAt: hermesService?.updatedAt ?? ""
  readonly property string fetchState: hermesService?.fetchState ?? "idle"
  readonly property string errorMessage: hermesService?.errorMessage ?? ""

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginM

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: "⚕ Hermes Agent"
        font.family: Style.fontFamily
        font.weight: Font.Bold
        font.pixelSize: Style.fontSizeL
        color: Color.mOnSurface
      }

      Item { Layout.fillWidth: true }

      NText {
        text: gwState === "running" ? "● Online" : gwState === "stopped" ? "● Offline" : "● Unknown"
        font.pixelSize: Style.fontSizeS
        color: gwState === "running" ? Color.mPrimary : Color.mError
      }
    }

    // Separator
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Color.mOutlineVariant ?? Color.mOutline
      opacity: 0.3
    }

    // Error message
    Rectangle {
      Layout.fillWidth: true
      visible: fetchState === "error"
      radius: Style.radiusS
      color: Color.mErrorContainer ?? Qt.rgba(1, 0, 0, 0.1)
      height: visible ? errorRow.height + Style.marginS * 2 : 0

      RowLayout {
        id: errorRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Style.marginS
        anchors.verticalCenter: parent.verticalCenter

        NText {
          text: "⚠ " + root.errorMessage
          font.pixelSize: Style.fontSizeS
          color: Color.mOnErrorContainer ?? Color.mError
          Layout.fillWidth: true
          wrapMode: Text.Wrap
        }
      }
    }

    // Info grid
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      // Model info (read from config if available)
      Repeater {
        model: {
          var rows = [];
          if (root.gwState !== "unknown") {
            rows.push({"label": "Gateway", "value": root.gwState === "running" ? "Running (PID " + root.pid + ")" : "Stopped"});
          }
          if (root.activeAgents > 0) {
            rows.push({"label": "Active Sessions", "value": root.activeAgents.toString()});
          }
          return rows;
        }

        delegate: RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NText {
            text: modelData.label
            font.pixelSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant ?? Color.mOnSurface
            opacity: 0.7
            Layout.preferredWidth: 110
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

    // Platform status
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
            text: modelData.state === "connected" ? "Connected" : modelData.error || modelData.state
            font.pixelSize: Style.fontSizeXS ?? Style.fontSizeS
            color: modelData.state === "connected" ? (Color.mOnSurfaceVariant ?? Color.mOnSurface) : Color.mError
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }
      }
    }

    // Actions
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Item { Layout.fillWidth: true }

      NText {
        text: "↻ Refresh"
        font.pixelSize: Style.fontSizeS
        color: Color.mPrimary
        opacity: refreshMouse.containsMouse ? 1.0 : 0.8

        MouseArea {
          id: refreshMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          onClicked: hermesService?.refresh()
        }
      }
    }

    // Footer timestamp
    NText {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignRight
      text: root.updatedAt ? "Updated: " + Qt.formatDateTime(new Date(root.updatedAt), "hh:mm:ss") : ""
      font.pixelSize: Style.fontSizeXS ?? 10
      color: Color.mOnSurfaceVariant ?? Color.mOnSurface
      opacity: 0.5
    }
  }
}
