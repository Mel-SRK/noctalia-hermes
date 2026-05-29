# noctalia-hermes

noctalia-shell 插件 — 在状态栏显示 [Hermes Agent](https://github.com/nousresearch/hermes-agent) 的运行状态。

## 功能

- 状态栏图标实时显示 gateway 状态（运行中/停止/异常）
- 有活跃会话时显示会话数量
- 平台连接异常时显示警告
- 点击弹出面板，显示详细状态（PID、会话数、各平台连接状态）
- 右键菜单快速刷新

## 状态栏图标含义

| 图标 | 颜色 | 含义 |
|------|------|------|
| ✓ circle-check | 绿色 | Gateway 运行中，一切正常 |
| ✗ circle-x | 红色 | Gateway 已停止 |
| ⚠ alert-circle | 警告色 | Gateway 运行中但有平台连接异常 |
| ⚠ alert-triangle | 红色 | 无法读取状态文件 |
| ⊙ loader | 默认 | 正在加载中 |

## 安装

将 `hermes-status/` 目录放到 noctalia 插件目录：

```bash
# 方式一：直接复制
cp -r hermes-status ~/.config/noctalia/plugins/

# 方式二：符号链接（方便更新）
ln -s ~/Git_Program/noctalia-hermes/hermes-status ~/.config/noctalia/plugins/hermes-status
```

然后重启 noctalia-shell，在 Settings → Plugins 中启用 **Hermes Agent**。

## 配置

在 noctalia 的 Settings → Plugins → Hermes Agent 中可调整：

| 选项 | 默认值 | 说明 |
|------|--------|------|
| Gateway state file | `~/.hermes/gateway_state.json` | 状态文件路径 |
| Poll interval | 10s | 轮询间隔 |
| Hide when running | false | gateway 正常运行时隐藏图标 |
| Show active agent count | true | 显示活跃会话数 |
| Icon color | primary | 图标颜色主题 |

## 数据来源

读取 `~/.hermes/gateway_state.json`，该文件由 hermes-gateway 进程自动维护，包含：

```json
{
  "gateway_state": "running",
  "active_agents": 1,
  "pid": 1043,
  "platforms": {
    "telegram": {
      "state": "connected"
    }
  },
  "updated_at": "2026-05-29T03:53:34Z"
}
```

## 开发

基于 [Mic92/noctalia-plugins](https://github.com/Mic92/noctalia-plugins) 的 alertmanager 插件模板开发。

noctalia-shell 插件结构：
- `manifest.json` — 插件元数据、入口点、默认配置
- `Main.qml` — 后台逻辑（数据轮询）
- `BarWidget.qml` — 状态栏显示组件
- `Panel.qml` — 点击弹出的详情面板
- `Settings.qml` — 设置界面

## License

MIT
