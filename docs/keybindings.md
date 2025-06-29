---

# ⌨️ Neovim 快捷键总览

本配置采用模块化 `<leader>` 键映射，基于 `which-key.nvim` 管理，支持自动补全提示。以下是主要功能区块的快捷键说明。

---

## 1️⃣ LSP / 代码导航与操作

| 模式 | 快捷键         | 功能描述            |
| -- | ----------- | --------------- |
| n  | `<Space>lf` | 格式化代码           |
| n  | `<Space>ld` | 跳转到定义           |
| n  | `<Space>lR` | 查找引用            |
| n  | `<Space>la` | Code Action     |
| n  | `<Space>lr` | 重命名             |
| n  | `<Space>ls` | 签名帮助            |
| n  | `<Space>li` | 跳转实现            |
| n  | `<Space>lk` | 悬浮文档（Hover）     |
| n  | `K`         | 显示悬浮文档（快捷）      |
| n  | `gra`       | Code Action（快捷） |
| n  | `grn`       | 重命名（快捷）         |
| n  | `gri`       | 实现              |
| n  | `grr`       | 引用              |
| n  | `gO`        | 打开符号大纲          |

---

## 2️⃣ 查找类（Telescope）

| 模式 | 快捷键         | 功能描述            |
| -- | ----------- | --------------- |
| n  | `<Space>ff` | 查找文件            |
| n  | `<Space>fg` | 全文模糊搜索          |
| n  | `<Space>fb` | 查找缓冲区           |
| n  | `<Space>fo` | 最近打开的文件         |
| n  | `<Space>fh` | 查找帮助标签          |
| n  | `<Space>ft` | Telescope 主题选择器 |

---

## 3️⃣ Trouble / 诊断窗口

| 模式 | 快捷键                     | 功能描述          |
| -- | ----------------------- | ------------- |
| n  | `<Space>xx`             | 全局诊断          |
| n  | `<Space>xX`             | 当前缓冲区诊断       |
| n  | `<Space>xl`             | LSP 定义 / 引用   |
| n  | `<Space>xL`             | Location List |
| n  | `<Space>xQ`             | Quickfix List |
| n  | `<Space>xs`             | 当前符号视图        |
| n  | `[d` / `]d`             | 上/下一个诊断位置     |
| n  | `<C-W><C-D>` / `<C-W>d` | 显示光标下诊断浮窗     |

---

## 4️⃣ 终端 / 会话 / 文件管理

| 模式 | 快捷键         | 功能描述                |
| -- | ----------- | ------------------- |
| n  | `<Space>tt` | 打开终端（水平分屏）          |
| n  | `<Space>tv` | 打开终端（垂直分屏）          |
| n  | `<Space>tf` | 打开终端（浮窗）            |
| n  | `<Space>tm` | 打开终端管理器（Toggleterm） |
| n  | `<Space>tg` | 打开 LazyGit          |
| n  | `<Space>fm` | 启动文件管理器（mini.files） |
| n  | `<Space>ss` | 保存当前会话（Session）     |
| n  | `<Space>sl` | 加载会话                |
| n  | `<Space>sd` | 选择会话                |

---

## 5️⃣ DAP 调试（nvim-dap）

| 模式 | 快捷键      | 功能描述      |
| -- | -------- | --------- |
| n  | `<F5>`   | 启动 / 继续调试 |
| n  | `<F9>`   | 切换断点      |
| n  | `<F10>`  | Step Over |
| n  | `<F11>`  | Step Into |
| n  | `<F12>`  | Step Out  |
| n  | `<S-F5>` | 停止调试      |

---

## 6️⃣ AI / LLM 智能助手（llm.nvim）

> 使用前请设置环境变量：
>
> ```bash
> export LLM_KEY=your_api_key
> ```

### 会话操作

| 模式 | 快捷键         | 功能描述                    | 位置      |
| -- | ----------- | ----------------------- | ------- |
| n  | `<Space>ac` | 切换会话（Session Toggle）    | 全局      |
| n  | `<esc>`     | 关闭当前会话                  | 全局 / 输出 |
| n  | `<C-m>`     | 打开模型列表（Session Models）  | 输入 / 输出 |
| n  | `<C-h>`     | 打开历史窗口（Session History） | 输出      |

### 选中文本操作（visual）

| 模式 | 快捷键         | 功能描述         |
| -- | ----------- | ------------ |
| v  | `<Space>aa` | 对话（选中文本）     |
| v  | `<Space>ae` | 解释代码         |
| v  | `<Space>ar` | 润色文本         |
| v  | `<Space>at` | 翻译           |
| v  | `<Space>am` | 转换为 Markdown |
| v  | `<Space>aq` | 提问           |

### 输入浮窗快捷键（Insert 模式）

| 模式 | 快捷键       | 功能描述    |
| -- | --------- | ------- |
| i  | `<C-g>`   | 提交提问    |
| i  | `<C-c>`   | 取消输入    |
| i  | `<C-r>`   | 重发请求    |
| i  | `<C-j>`   | 下一条历史记录 |
| i  | `<C-k>`   | 上一条历史记录 |
| i  | `<C-S-j>` | 切换下一个模型 |
| i  | `<C-S-k>` | 切换上一个模型 |

### 输出浮窗分页

| 模式    | 快捷键     | 功能描述 |
| ----- | ------- | ---- |
| n / i | `<C-f>` | 向下翻页 |
| n / i | `<C-b>` | 向上翻页 |
| n / i | `<C-d>` | 向下半页 |
| n / i | `<C-u>` | 向上半页 |
| n     | `gg`    | 跳转顶部 |
| n     | `G`     | 跳转底部 |

---

## 7️⃣ 常规操作 & 杂项功能

| 模式 | 快捷键           | 功能描述          |
| -- | ------------- | ------------- |
| n  | `<Space>ll`   | 执行 nvim-lint  |
| n  | `<Space>u`    | 打开 UndoTree   |
| n  | `gx`          | 系统方式打开 URI    |
| n  | `gcc`         | 注释当前行         |
| n  | `j` / `k`     | 视觉行移动（支持软换行）  |
| n  | `<M-h/j/k/l>` | 行移动（MiniMove） |
| n  | `[b` / `]b`   | 上/下 buffer    |
| n  | `[t` / `]t`   | 上/下 tab       |
| n  | `<C-L>`       | 清除高亮并刷新       |

---

## 📘 附注说明

* `<Space>` 为主键位（leader），默认设置为 `空格`
* `<M-*>` 表示 Alt 键组合，例如 `<M-j>` 是 Alt + j
* 插件使用 `which-key.nvim` 管理所有快捷键映射，按 `<Space>` 即可查看分组提示
* 所有快捷键都可在 `lua/core/keymaps.lua` 中自定义

---
