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

  // attentionFile
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXS

    NText {
      text: pluginApi?.tr("settings.attentionFile") ?? "Attention flag file"
      font.pixelSize: Style.fontSizeS
      font.weight: Font.DemiBold
      color: Color.mOnSurface
    }

    NTextInput {
      Layout.fillWidth: true
      text: cfg.attentionFile ?? pluginApi?.manifest?.metadata?.defaultSettings?.attentionFile ?? ""
      placeholderText: "~/.hermes/needs_attention"
      onEditingFinished: {
        pluginApi.setPluginSetting("attentionFile", text);
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

  // hideWhenIdle
  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.hideWhenIdle") ?? "Hide when idle"
    description: pluginApi?.tr("settings.hideWhenIdleDesc") ?? "Only show when gateway is offline, busy, or needs attention"
    checked: cfg.hideWhenIdle ?? pluginApi?.manifest?.metadata?.defaultSettings?.hideWhenIdle ?? false
    onToggled: checked => {
      pluginApi.setPluginSetting("hideWhenIdle", checked);
    }
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hideWhenIdle ?? false
  }

  // showAgentCount
  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.showAgentCount") ?? "Show active session count"
    description: pluginApi?.tr("settings.showAgentCountDesc") ?? "Display the number of active sessions when busy"
    checked: cfg.showAgentCount ?? pluginApi?.manifest?.metadata?.defaultSettings?.showAgentCount ?? true
    onToggled: checked => {
      pluginApi.setPluginSetting("showAgentCount", checked);
    }
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showAgentCount ?? true
  }
}
