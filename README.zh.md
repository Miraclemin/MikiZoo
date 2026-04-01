# MikiZoo

[English](README.md)

![MikiZoo](pic.png)

住在你 macOS 桌面上的迷你 AI 伴侣。它会走路、漫游、思考、聊天 —— 由你选择的 AI 驱动。

---

## MikiZoo 是什么？

MikiZoo 在你的 Mac 桌面上放置一个动态角色 **Miki**，点击即可打开终端风格的 AI 聊天窗口。在你工作的同时，Miki 会主动感知你的状态 —— 切换应用、复制文字、写代码 —— 并在不打扰你的情况下主动提出帮助。

你也可以上传自己的 PNG 或 GIF 图片，创建专属的自定义 AI 角色。

---

## 核心功能

### 角色系统

- 内置角色 **Miki**，基于透明 HEVC 视频渲染，自然流畅
- 支持无限添加自定义角色：上传任意 PNG、JPEG 或动图 GIF 即可创建新 Agent
  - 例：上传一张猫咪 GIF，就能拥有一个会动的猫咪 AI 助手
- 每个角色拥有独立的强调色、人格设定和对话记录
- 新增角色自动分配专属颜色，互相区分

### 移动与漫游

- **静止模式** —— Miki 固定在屏幕一角，安静陪伴
- **移动模式** —— 开启后 Miki 在屏幕上自由漫游，拟真物理运动：
  - 平滑转向，每 5–10 秒随机改变方向和速度
  - 自然加减速，不会突然瞬移
  - 始终保持在屏幕中央 60% 区域，到达边缘自动弹回
  - 多角色同屏时自动保持间距，不重叠
- **拖拽定位** —— 长按角色 1 秒进入拖拽模式，拖到任意位置后自动保存，重启后不丢失
- 每个角色独立调节速度：0.25×（慢悠悠）到 3.0×（飞速跑动）

### AI 聊天

- 点击任意角色，弹出终端风格聊天窗口
- 实时流式输出，打字机效果显示响应内容
- 完整对话历史，清晰标注用户、助手、工具调用、工具结果
- 代码块高亮显示
- 每个角色对话独立，跨重启保留

### 4 种 AI 接入方式

| 接入方式 | 说明 |
|---|---|
| **Claude** | Claude Code CLI，NDJSON 流式，支持自定义 system prompt |
| **Codex** | OpenAI Codex CLI，全自动执行模式，多轮上下文重建 |
| **Copilot** | GitHub Copilot CLI，`--continue` 多轮对话 |
| **OpenClaw** | 本地 HTTP 网关，SSE 流式，可配置地址 / Agent ID / Token |

菜单栏一键切换 AI 提供商，所有会话自动重启。

### 智能主动建议

Miki 会悄悄感知你的操作，在合适的时机主动提问 —— 在你接受之前，**零 API 调用**，不消耗任何额度。

**复制了什么就问什么：**
- 复制了一段长文 → Miki 冒泡："帮你总结？"
- 复制了代码 → "解释这段代码？"
- 复制了英文 → "翻译一下？"

**切换到什么 App 就帮什么忙：**
| 打开的应用 | Miki 会问 |
|---|---|
| Xcode / Cursor / VS Code | "遇到报错了？需要帮忙吗？" |
| Mail / Outlook / Spark | "帮你写邮件？" |
| Notion / Obsidian / Bear | "帮你整理思路？" |
| Keynote / PowerPoint / Canva | "要优化内容吗？" |
| Terminal / iTerm / Warp | "需要命令帮助？" |
| Safari / Chrome / Firefox / Arc | "帮你解释这个？" |

- 每类应用可独立开启/关闭
- 触发延迟可设置：15秒 / 30秒 / 1分钟 / 3分钟 / 5分钟（避免频繁打扰）
- 气泡显示在角色头顶，一键接受或忽略，不接受就自动消失

### 思考气泡与音效反馈

- AI 处理中：角色头顶出现思考气泡，随机显示思考短语，每隔几秒更换
- AI 完成时：切换为完成提示语 + 绿色气泡
- 完成音效：9 种不同提示音随机播放，不重复，可全局关闭
- 整个过程无需盯着屏幕，听到声音就知道好了

### 角色个性化

- **自定义图片**：上传 PNG、JPEG 或 GIF 替换默认角色 —— 可以是你的头像、宠物、任意图案
- **镜像翻转**：角色默认朝右，勾选后朝左
- **人格设定**：给角色起名字、写性格描述，自动注入 AI system prompt
  - 例：名字填"小助手"，性格填"直接坦率，有点毒舌但很关心我"，之后 AI 回复就会带这个风格
- **大小与位置**：可调整角色大小和纵向位置，独立保存
- **速度**：每个角色单独设置速度

### 多显示器支持

- 可将角色固定到指定显示器
- 自动检测 Dock 位置（支持自动隐藏和放大模式）
- 进入全屏应用时角色自动隐藏，退出后恢复

---

## 系统要求

- macOS Sonoma（14.0+）
- 至少安装以下其中一种 CLI：
  - [Claude Code](https://claude.ai/download) — `curl -fsSL https://claude.ai/install.sh | sh`
  - [OpenAI Codex](https://github.com/openai/codex) — `npm install -g @openai/codex`
  - [GitHub Copilot CLI](https://github.com/github/copilot-cli) — `brew install copilot-cli`
  - 或本地运行的 OpenClaw 兼容 HTTP 网关

---

## 构建运行

用 Xcode 打开 `Miki.xcodeproj`，点击 Run 即可。

---

## 隐私说明

MikiZoo 完全在你的 Mac 本地运行。

- **纯本地运行。** 不收集、不上传任何个人数据、文件路径或使用记录。
- **AI 对话。** 所有聊天由你配置的 CLI 子进程或网关处理，MikiZoo 不拦截、不存储内容。发送给 AI 提供商的数据受其各自隐私政策约束。
- **辅助功能权限。** 智能建议使用 macOS 辅助功能 API 读取本地窗口标题和选中文字，数据不会离开你的设备。
- **无账号体系。** 无需登录，无用户数据库。
- **自动更新。** 使用 Sparkle 检查更新，仅发送应用版本号和 macOS 版本号。

---

## 开源协议

MIT License，详见 [LICENSE](LICENSE)。

基于 [lil-agents](https://github.com/ryanstephen/lil-agents)（Ryan Stephen，MIT）二次开发。
