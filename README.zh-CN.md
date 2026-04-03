# Voice2Text

[English](./README.md) | [简体中文](./README.zh-CN.md)

一个使用 Swift 和 Swift Package Manager 构建的 macOS 14+ 菜单栏语音输入应用。

Voice2Text 支持按住热键录音，松开后自动转录，并将识别文本注入当前聚焦的输入框。它面向高频语音输入、中文优先使用场景，以及中英文混合输入场景进行了优化。

## 功能特性

- 仅菜单栏应用（`LSUIElement`），无 Dock 图标
- 按住说话、松开转录的语音输入工作流
  - 内建键盘：`Fn`
  - 外接键盘兜底：`Alt / Option`
- 基于 Apple Speech Framework 的流式语音识别
- 屏幕底部居中的悬浮 HUD，带实时转录预览与波形反馈
- 开箱即用默认简体中文（`zh-CN`）
- 菜单栏语言切换
  - English
  - 简体中文
  - 繁體中文
  - 日本語
  - 한국어
- 基于剪贴板的文本注入，并对 CJK 输入法进行输入源切换处理
- 可选的 OpenAI-compatible API LLM refine
- 基于文件的转录历史持久化（`jsonl`）
- 已生成 macOS 应用图标并支持签名 `.app` 打包

## 运行要求

- macOS 14+
- Xcode Command Line Tools
- 麦克风权限
- 语音识别权限
- 辅助功能权限

## 构建与运行

### 构建 release app bundle

```bash
make build
```

输出产物：

```bash
dist/Voice2Text.app
```

### 运行已有 app bundle

```bash
make run
```

`make run` 会直接打开现有的打包应用，不会每次都重新 build 和重新签名。这可以让 macOS 权限行为在测试时更稳定。

### 显式重新构建

```bash
make rebuild
```

### 安装到 Applications

```bash
make install
open /Applications/Voice2Text.app
```

## 首次启动权限

首次启动时，macOS 可能会请求以下权限：

- 麦克风权限
- 语音识别权限
- 辅助功能权限

### 推荐首次启动流程

1. 安装并打开应用：

```bash
make install
open /Applications/Voice2Text.app
```

2. 授予所有请求的权限。
3. 如果辅助功能需要在系统设置里手动添加，请将 `Voice2Text.app` 加入其中。
4. 等待应用检测权限状态更新。

## 热键

- Mac 内建键盘：按住 `Fn`
- 外接键盘：按住 `Alt / Option`

松开按键后，应用会停止录音并将文本注入当前聚焦输入框。

## LLM Refinement

菜单栏中包含 `LLM Refinement` 子菜单。

可配置项包括：

- API Base URL
- API Key
- Model

LLM 提示词采用非常保守的纠错策略：

- 只修复明显识别错误
- 不改写或润色本来正确的文本
- 正确文本必须原样保留

## 转录历史

Voice2Text 使用 JSON Lines 存储转录历史。

路径：

```bash
~/Library/Application Support/Voice2Text/transcriptions.jsonl
```

每一行包含：

- `id`
- `timestamp`
- `text`

当前保存内容包括：

- 原始转录文本
- 时间戳

## 项目结构

```text
Sources/Voice2TextApp/
├── AppDelegate.swift
├── main.swift
├── Audio/
├── History/
├── Hotkey/
├── HUD/
├── Input/
├── LLM/
├── MenuBar/
├── Settings/
├── Speech/
└── Support/
```

## 说明

- 当前项目使用本地 ad-hoc signing 进行构建签名：

```bash
codesign --deep --force --sign - dist/Voice2Text.app
```

- 为了获得更稳定的权限行为，建议优先从 `/Applications` 中启动已安装版本。

## 许可证

MIT
