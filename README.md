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
  xclip curl make gcc

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

```bash
fd --version
rg --version
node --version
python3 --version
gcc --version
```

---

## 💻 Windows WSL 环境支持（Windows Subsystem for Linux）

本配置兼容 WSL，推荐使用 **WSL2 + Ubuntu** 子系统。

### 🧩 安装依赖（以 Ubuntu 为例）

```bash
sudo apt update && sudo apt install -y \
  fdfind ripgrep unzip build-essential git \
  luarocks python3 python3-pip nodejs npm \
  curl xclip gcc make

mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd
```

---

### 🎨 字体设置（在 Windows 端完成）

由于 WSL 不负责终端字体渲染，请在 **Windows Terminal / Alacritty** 中配置 Nerd Font：

1. 下载字体：[JetBrainsMono Nerd Font][nerdfont]
2. 右键字体文件 → 安装
3. 打开终端设置 → 字体 → 设置为：

```
JetBrainsMono Nerd Font
```

---

### 📋 剪贴板支持（通过 win32yank 实现）

```bash
mkdir -p ~/bin
curl -Lo ~/bin/win32yank.exe https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.exe
chmod +x ~/bin/win32yank.exe

# 添加到 PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

在 `init.lua` 中添加配置：

```lua
vim.g.clipboard = {
  name = 'win32yank-wsl',
  copy = {
    ['+'] = 'win32yank.exe -i --crlf',
    ['*'] = 'win32yank.exe -i --crlf',
  },
  paste = {
    ['+'] = 'win32yank.exe -o --lf',
    ['*'] = 'win32yank.exe -o --lf',
  },
  cache_enabled = 0,
}
```

---

[nerdfont]: https://www.nerdfonts.com/font-downloads

---
