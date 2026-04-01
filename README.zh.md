# MikiZoo

![MikiZoo](pic.png)

住在你 macOS 屏幕上的迷你 AI 伴侣。它们会走路、漫游、思考、聊天 —— 由你选择的 AI CLI 驱动。

---

## MikiZoo 是什么？

MikiZoo 在你的 Mac 桌面上放置动态角色，点击任意角色可打开终端风格的 AI 聊天窗口。在你工作的同时，角色会主动感知你的状态 —— 切换应用、复制文字、写代码 —— 并在不打扰你的情况下主动提出帮助。

---

## 功能介绍

### 动态角色

- 2 个内置角色（**Miki** 和 **Jazz**），基于透明 HEVC 视频渲染
- 支持无限添加自定义角色，支持 PNG、JPEG 或动图 GIF
- 每个角色拥有独立的强调色、人格设定和配置
- 新增角色自动从精心调配的色板中分配专属颜色

### 移动行为

- **静止模式** —— 角色固定在屏幕指定位置
- **移动模式** —— 拟真物理漫游：平滑转向、每 5–10 秒随机改变速度、自然加减速
- 边界感知：角色始终保持在屏幕中央 60% 区域，到达边缘自动弹回
- 同伴避碰：多角色之间自动保持间距，不会互相重叠
- **拖拽定位** —— 长按任意角色可拖到屏幕任意位置，位置跨重启保存
- 每个角色独立设置速度倍率：0.25× 到 3.0×

### AI 聊天弹窗

- 点击任意角色，打开浮动的终端风格聊天窗口
- 实时流式输出响应内容
- 完整对话历史，区分用户、助手、工具调用、工具结果等角色
- 代码块高亮展示
- 每个角色的对话记录跨重启保留

### 4 种视觉主题

| 主题 | 风格 |
|---|---|
| **Peach（蜜桃）** | 温暖圆润，自动跟随角色颜色调整强调色 |
| **Midnight（午夜）** | 深色背景橙色点缀，SF Mono 等宽字体 |
| **Cloud（云朵）** | 浅蓝灰色，简洁风格，系统字体 |
| **Moss（苔藓）** | 复古绿色，Chicago/Geneva 字体，极小圆角 |

Peach 主题会根据每个角色的强调色自动染色。

### 4 种 AI 接入方式

| 接入方式 | 类型 | 工作原理 |
|---|---|---|
| **Claude** | CLI 子进程 | NDJSON 流式传输，支持 system prompt 注入 |
| **Codex** | CLI 子进程 | `codex exec --json --full-auto`，多轮上下文重建 |
| **Copilot** | CLI 子进程 | GitHub Copilot CLI，`--continue` 多轮对话，JSON 流 |
| **OpenClaw** | HTTP 网关 | SSE 流式传输，可配置地址、Agent ID、Bearer Token |

可随时从菜单栏切换 AI 提供商，所有会话自动重启。

### 智能建议（主动感知 AI）

MikiZoo 会感知你的操作状态，主动提出帮助 —— 在你接受之前，零 API 调用。

**剪贴板分析**（复制后立即触发）：
- 长文或文章 → "帮你总结？"
- 代码片段 → "解释这段代码？"
- 英文内容 → "翻译一下？"

**应用上下文感知**（在某个 App 停留一段时间后触发）：
| 应用类别 | 建议 |
|---|---|
| Xcode / Cursor / VS Code | 遇到报错了？需要帮忙吗？ |
| Mail / Outlook / Spark | 帮你写邮件？ |
| Notion / Obsidian / Bear | 帮你整理思路？ |
| Keynote / PowerPoint / Canva | 要优化内容吗？ |
| Terminal / iTerm / Warp | 需要命令帮助？ |
| Safari / Chrome / Firefox / Arc | 帮你解释这个？ |

- 每类应用可独立开启/关闭
- 上下文触发延迟可配置：15秒 / 30秒 / 1分钟 / 3分钟 / 5分钟
- 建议以气泡形式显示在角色头顶，一键接受或忽略

### 思考气泡

- AI 处理时，角色头顶出现动态气泡，显示随机思考短语
- AI 完成时切换为完成提示语
- 绿色完成气泡 + 音效提示
- 9 种不同的提示音，随机播放不重复，可全局关闭

### 每个角色的个性化设置

- **自定义图片**：用任意 PNG、JPEG 或 GIF 替换默认视频角色
- **镜像翻转**：水平翻转角色朝向
- **人格设定**：为每个角色设置名字和性格描述，自动注入 AI system prompt
- **大小与位置**：可调节大小和纵向偏移，独立保存
- **速度**：每个角色独立的速度倍率

### 菜单栏

- 每个角色独立子菜单：显示/隐藏、移动模式、速度滑块、自定义图片、人格配置
- 全局设置：AI 提供商选择、主题切换、智能建议设置、音效开关
- 添加角色：文件选择器直接添加新角色
- OpenClaw 配置面板：网关地址、实时拉取的 Agent ID、认证 Token

### 多显示器支持

- 可将角色固定到指定显示器
- 自动检测 Dock 位置（支持自动隐藏和放大模式）
- 全屏空间下自动隐藏角色

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

- **纯本地运行。** 应用不收集、不上传任何个人数据、文件路径或使用记录。
- **AI 对话。** 所有聊天由你配置的 CLI 子进程或网关处理，MikiZoo 不拦截、不存储对话内容。发送给 AI 提供商的数据受其各自隐私政策约束。
- **辅助功能权限。** 智能建议使用 macOS 辅助功能 API 读取本地窗口标题和选中文字，这些数据不会离开你的设备。
- **无账号体系。** 无需登录，无用户数据库。
- **自动更新。** MikiZoo 使用 Sparkle 检查更新，仅发送应用版本号和 macOS 版本号。

---

## 开源协议

MIT License，详见 [LICENSE](LICENSE)。

基于 [lil-agents](https://github.com/ryanstephen/lil-agents)（Ryan Stephen，MIT）二次开发。
