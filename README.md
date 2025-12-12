## ✨ MayonLos Neovim 配置

现代、清爽、实用的 Neovim 配置（lazy.nvim）。内置 LSP/补全/Treesitter/Git/UI 增强，偏向开箱即用。

## 🛠️ 环境要求

- Neovim 0.10+
- Git（用于自动安装 lazy.nvim）
- 推荐：`fd`/`rg`、Nerd Font、`xclip`/`wl-clipboard`

## 🚀 快速上手

1. 启动 Neovim，会自动安装插件管理器与插件。
2. 终端切换 Nerd Font。
3. 按 `<leader>`（空格）后等待 which-key 提示。

## 📂 目录结构（要点）

```
lua/
  config/lazy.lua   # lazy.nvim 配置
  core/             # 基础配置（options/autocmds/keymaps/lspconfig）
  plugins/          # 分组的插件配置
```

## 🎹 常用快捷键（前缀分类）

| 前缀/键位             | 作用                                      |
| --------------------- | ----------------------------------------- |
| `<leader>f f/g/b/r/h` | FzfLua：文件/全局搜索/缓冲区/最近/帮助     |
| `<leader>f .`         | 当前缓冲区行内搜索                         |
| `<leader>e e/f`       | Neo-tree：切换/聚焦                       |
| `<leader>b …`         | Bufferline：切换/固定/排序/关闭/跳转       |
| `<leader>d …`         | DAP 调试：启动/断点/REPL/UI 等            |
| `<leader>l h`         | Clangd：源/头切换                         |
| `<leader>l a/s/t/m`   | Clangd：AST/符号信息/类型层级/内存使用    |
| `<leader>l f`         | 格式化（Conform）                         |
| `<leader>x x`         | 打开诊断列表（Trouble）                   |
| `<leader>t`           | Todo-comments 列表                         |
| `<leader>u`           | UndoTree 切换                              |
| `<leader>a c`         | Codex 浮动终端                             |
| `<C-\\>`              | ToggleTerm 浮动终端                        |
| `zR/zM/zr/zm/zp`      | UFO 折叠：全开/全关/部分开/收起/预览       |
| `<C-/>`, `gc`, `gb`   | Comment.nvim 行/块注释（含插入/可视模式） |

## 🧠 LSP 相关

- `K` 悬浮文档，`gd/gD/gi/gr` 跳转，`<leader>ca` CodeAction，`<leader>cr` Rename
- `<leader>ld` 切换诊断虚拟文本，`<leader>li` 切换 inlay hints
- 状态栏展示 LSP 客户端与 nvim-navic 面包屑

## 🔍 组件概览

- UI：Heirline 状态栏、Navic 面包屑、Noice、Barbecue、Starter
- 编辑：自动配对、缩进指示（ibl）、Comment.nvim、which-key
- 代码：LSP（clangd/pyright/lua_ls/marksman）、格式化（Conform）、调试（nvim-dap + ui）
- Treesitter：高亮、文本对象、上下文、彩虹括号
- 工具：FzfLua、Neo-tree、ToggleTerm、Undotree、Todo-comments

[nerdfont]: https://www.nerdfonts.com/

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
