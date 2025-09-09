## 🛠️ Prerequisites / 环境依赖说明

为了让本配置正常运行，请先确保以下通用依赖已正确安装：

### 📦 通用依赖项

| 功能           | 说明与建议                                          |
| -------------- | --------------------------------------------------- |
| 文件搜索工具   | `fd`（Ubuntu 中为 `fdfind`）+ `ripgrep` (`rg`)      |
| 解压缩工具     | `unzip`                                             |
| 编译环境       | `make`, `gcc`, `base-devel`（或 `build-essential`） |
| Git 支持       | `git`                                               |
| Nerd Font 字体 | 推荐安装 [JetBrainsMono Nerd Font][nerdfont]        |
| 剪贴板工具     | `xclip`（X11）或 `wl-clipboard`（Wayland）          |
| Python 环境    | `python3` + `pip`                                   |
| Node.js 环境   | `nodejs` + `npm`                                    |
| Lua 环境       | `lua`, `luajit`, `luarocks`                         |
| 下载工具       | `curl`（部分插件如 `llm.nvim` 使用）                |

---

### 🖥️ 按操作系统安装（命令参考）

#### ✅ Arch / Manjaro

```bash
sudo pacman -S --needed fd ripgrep unzip base-devel git \
  luarocks python python-pip nodejs npm \
  xclip curl make gcc oniguruma

# Nerd Font（如使用 JetBrainsMono）
yay -S ttf-jetbrains-mono-nerd
```

#### ✅ Ubuntu / Debian

```bash
sudo apt update && sudo apt install -y \
  fd-find ripgrep unzip build-essential git \
  luarocks python3 python3-pip nodejs npm \
  xclip curl make gcc

# 创建 fd 软链接（Ubuntu 使用 fdfind）
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
```

> 💡 若使用 Telescope 等插件，`fd` 与 `rg` 是必须的。

#### ✅ macOS (Homebrew)

```bash
brew install fd ripgrep unzip git luarocks python node \
  xclip curl gcc make

brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

---

### ✅ 验证依赖是否可用（可选）

## ✨ MayonLos Neovim 配置（基于 lazy.nvim）

> 现代、清爽、实用的 Neovim 配置。内置 LSP、补全、Treesitter、Git、UI 增强，以及便捷的代码运行与 CMake 工作流命令。

---

## ✅ 要求与环境

- Neovim 0.10+（本配置使用了 0.10 的 LSP 与 API）
- Git（用于自动安装插件管理器 lazy.nvim）
- 推荐：ripgrep（rg）、fd、Nerd Font 字体、xclip/wl-clipboard（Linux 剪贴板）

快速安装依赖（示例）

- Arch/Manjaro
  - pacman: fd ripgrep unzip base-devel git python nodejs npm xclip curl make gcc
- Ubuntu/Debian
  - apt: fdfind ripgrep unzip build-essential git python3 python3-pip nodejs npm xclip curl make gcc
  - fd 软链：ln -s $(which fdfind) ~/.local/bin/fd
- macOS
  - brew: fd ripgrep git python node curl gcc make；并安装 Nerd Font

WSL 剪贴板：可使用 win32yank（参考旧 README 片段）。

---

## � 开始使用

1. 首次启动 Neovim 会自动安装 lazy.nvim 与插件
2. 推荐安装 Nerd Font，终端切换到对应字体
3. 使用 which-key 查看可用前缀与分组

目录结构（关键部分）

```
lua/
  config/lazy.lua          # lazy.nvim 安装与插件注册
  core/                    # 基础配置
    options.lua            # 通用选项
    autocmds.lua           # 自动命令（高亮 yank、恢复光标、自动建目录等）
    lspconfig.lua          # LSP/诊断/按键
    command/               # 自定义命令合集
      runners.lua          # 代码运行器（多语言）
      cmake.lua            # CMake 集成（配置/构建/运行/清理）
      url.lua              # URL 打开/复制/搜索
  plugins/                 # 插件配置（UI/编辑/工具/树/Markdown/Git）
```

init.lua 入口：

```lua
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
require 'core'
require 'config.lazy'
```

lazy.nvim 插件分类：UI、Editor、Tools、Coding、Treesitter、Git、Markdown。

---

## 🧩 主要功能概览

- UI：状态栏/面包屑/滚动条/Noice 消息、启动页、主题
- 编辑增强：自动配对、缩进指引、注释、which-key 分组提示
- 代码智能：内置 LSP（clangd、pyright、lua_ls、marksman），诊断/悬浮/重命名/格式化
- 补全：与 blink/cmp 集成（按配置自动启用）
- Treesitter：语法高亮、文本对象、上下文、注释、彩虹括号
- Git：gitsigns
- Markdown：render-markdown
- 调试：DAP
- 工具：fzf、neo-tree、undotree、which-key、LeetCode、CodeCompanion（含扩展）
- 自定义命令：代码运行器、CMake 工作流、URL 工具

---

## 🧠 LSP 与按键

通用 LSP 按键（Normal 模式，见 `core/lspconfig.lua`）：

- K：Hover 文档
- gd/gD/gi/gr：定义/声明/实现/引用
- <leader>ca：Code Action
- <leader>cr：Rename
- <leader>cf：Format（异步，1.5s 超时）
- <leader>ld：切换当前缓冲区诊断开关
- <leader>li：切换 Inlay Hints（支持的语言）

诊断 UI 已优化：虚拟文本、浮窗、Signs、排序、插入模式不更新等。

---

## 🧪 代码运行器（`core/command/runners.lua`）

命令：

- :RunCode — 运行当前文件（自动保存、为 C/C++/Rust 提供编译+运行；其余直接运行）
- :RunCodeToggle — 在 Debug/Release 间切换（影响编译 flags）
- :RunCodeLanguages — 查看支持的语言列表

特性：

- 浮动终端（圆角边框，Esc/q 关闭；执行完成后保持终端模式）
- 布局可选：center/bottom/right；可清屏再执行；可设置超时
- C/C++/Rust：分阶段 compile/run/clean；自动提示与清理
- 语言支持：c/cpp/rs/go/py/js/ts/lua/java/sh

---

## 🧱 CMake 集成（`core/command/cmake.lua`）

命令：

- :CMakeGen — 生成基础 CMakeLists.txt（自动收集源码/包含目录）
- :CMakeConfigure — 仅配置（自动选择或自定义 Generator）
- :CMakeBuild[ target] — 构建（并行度自动检测，支持目标）
- :CMakeRun [args] — 运行可执行文件（自动判断路径/多配置目录）
- :CMakeQuick [args] — 一键配置+构建+运行
- :CMakeClean — 清理构建目录

默认行为：

- 自动检测生成器（优先 Ninja；否则 Unix Makefiles），并对带空格的名称进行正确引用
- 并行度按 CPU 核数自动检测
- 终端窗口与运行器一致的 UX（圆角、按键、自动插入）

自定义示例：

```lua
require('core.command.cmake').setup({
  build_dir = 'build',
  build_type = 'Debug', -- 或 'Release' 等
  generator = 'Ninja',  -- 或 'Unix Makefiles'
})
```

常见问题：

- Could not create named generator Unix：请确保生成器名称完整并已正确安装（如 Ninja/Make）；必要时在 setup 中显式设置 `generator = "Unix Makefiles"`。

---

## 🔗 URL 工具（`core/command/url.lua`）

命令：

- :OpenURL [text] — 打开光标处或指定文本中的 URL
- :CopyURL [text] — 复制 URL 到系统剪贴板（若失败则复制到匿名寄存器）
- :SearchWeb [query] — 使用搜索引擎搜索（默认 Google，可在 setup 自定义）

---

## ⚙️ 其它细节

- 自动命令：
  - yank 高亮（支持宏/静默场景）
  - 打开文件恢复上次光标位置（排除 gitcommit/gitrebase）
  - 关闭注释延续（保留 markdown/gitcommit）
  - 保存自动建父目录（失败提示，可开启 verbose）
  - 终端缓冲优化：自动进入插入、隐藏行号与标记列

- 选项（节选）：
  - 相对行号、光标行、滚动边距、拆分方向、鼠标可用
  - 缩进：tabstop/shiftwidth=4，expandtab
  - 搜索：smartcase、增量高亮
  - Undo：独立目录与持久化
  - 折叠：Tree-sitter 表达式折叠，默认展开

---

## 🧷 故障排查

- Telescope 找不到文件：安装 `fd` 与 `ripgrep`（Ubuntu 将 `fdfind` 链接为 `fd`）
- 终端无法复制：Linux 安装 `xclip`/`wl-clipboard`；WSL 配置 `win32yank`
- CMake 生成器报错：确认 Ninja 或 Make 已安装；或 `setup{ generator = 'Unix Makefiles' }`
- LSP 不工作：确保 clangd/pyright/lua-language-server/marksman 安装并在 PATH 中

---

## 📦 附：快速依赖检查

```bash
fd --version
rg --version
node --version
python3 --version
gcc --version
cmake --version
```

---
