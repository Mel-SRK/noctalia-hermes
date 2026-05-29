import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})

  spacing: Style.marginM

  // gatewayStateFile
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXS

    NText {
      text: pluginApi?.tr("settings.stateFile") ?? "Gateway state file"
      font.pixelSize: Style.fontSizeS
      font.weight: Font.DemiBold
      color: Color.mOnSurface
    }

    NTextInput {
      Layout.fillWidth: true
      text: cfg.gatewayStateFile ?? pluginApi?.manifest?.metadata?.defaultSettings?.gatewayStateFile ?? ""
      placeholderText: "~/.hermes/gateway_state.json"
      onEditingFinished: {
        pluginApi.setPluginSetting("gatewayStateFile", text);
      }
    }
  }

  // pollInterval
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXS

    NText {
      text: pluginApi?.tr("settings.pollInterval") ?? "Poll interval (seconds)"
      font.pixelSize: Style.fontSizeS
      font.weight: Font.DemiBold
      color: Color.mOnSurface
    }

    NSpinBox {
      Layout.fillWidth: true
      from: 3
      to: 120
      value: cfg.pollInterval ?? pluginApi?.manifest?.metadata?.defaultSettings?.pollInterval ?? 10
      onValueModified: {
        pluginApi.setPluginSetting("pollInterval", value);
      }
    }
  }

  // hideWhenRunning
  NSettingSwitch {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.hideWhenRunning") ?? "Hide when gateway is running"
    description: pluginApi?.tr("settings.hideWhenRunningDesc") ?? "Only show the widget when gateway is stopped or has errors"
    checked: cfg.hideWhenRunning ?? pluginApi?.manifest?.metadata?.defaultSettings?.hideWhenRunning ?? false
    onToggled: function(checked) {
      pluginApi.setPluginSetting("hideWhenRunning", checked);
    }
  }

  // showAgentCount
  NSettingSwitch {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.showAgentCount") ?? "Show active agent count"
    description: pluginApi?.tr("settings.showAgentCountDesc") ?? "Display the number of active sessions next to the icon"
    checked: cfg.showAgentCount ?? pluginApi?.manifest?.metadata?.defaultSettings?.showAgentCount ?? true
    onToggled: function(checked) {
      pluginApi.setPluginSetting("showAgentCount", checked);
    }
  }

  // iconColor
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXS

    NText {
      text: pluginApi?.tr("settings.iconColor") ?? "Icon color"
      font.pixelSize: Style.fontSizeS
      font.weight: Font.DemiBold
      color: Color.mOnSurface
    }

    NComboBox {
      Layout.fillWidth: true
      model: ["primary", "secondary", "tertiary", "error"]
      currentIndex: {
        var key = cfg.iconColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ?? "primary";
        return model.indexOf(key);
      }
      onCurrentValueChanged: {
        pluginApi.setPluginSetting("iconColor", currentValue);
      }
    }
  }
}
