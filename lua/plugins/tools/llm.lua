return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      local tools = require("llm.tools")
      require("llm").setup({
        url = "https://api.deepseek.com/chat/completions",
        model = "deepseek-chat",
        api_type = "openai",
        max_tokens = 4096,
        temperature = 0.3,
        top_p = 0.7,
        prompt = "You are a helpful Chinese assistant.",
        prefix = {
          user = { text = "  ", hl = "Title" },
          assistant = { text = "  ", hl = "Added" },
        },
        save_session = true,
        max_history = 15,
        max_history_name_length = 20,
        app_handler = {
          Translate = {
            handler = tools.flexi_handler,
            prompt = "Translate the selected text to Chinese, only output the translation.",
          },
          CodeExplain = {
            handler = tools.flexi_handler,
            prompt = "Explain the selected code in Chinese in detail.",
          },
          OptimizeCode = {
            handler = tools.side_by_side_handler,
          },
          AttachToChat = {
            handler = tools.attach_to_chat_handler,
            opts = {
              is_codeblock = true,
              inline_assistant = true,
              language = "Chinese",
            },
          },
          Rephrase = {
            handler = tools.flexi_handler,
            prompt = "Please improve the clarity and fluency of the following text. Return only the polished version.",
          },
          MarkdownTidy = {
            handler = tools.flexi_handler,
            prompt = "Please restructure the following content into clear, organized Markdown format with headings, bullet points, and code blocks if needed.",
          },
          NoteSummary = {
            handler = tools.flexi_handler,
            prompt = [[Please create a clear and concise learning note based on the selected content. 
Use bullet points, section headings, and examples if necessary. Answer in Markdown.]],
          },
          Ask = {
            handler = tools.disposable_ask_handler,
            opts = {
              inline_assistant = true,
              title = " Ask ",
              language = "Chinese",
              url = "https://api.deepseek.com/chat/completions",
              model = "deepseek-chat",
              api_type = "openai",
            },
          },
        },
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>",              desc = "  Open Chat Session" },
      { "<leader>aa", mode = "v", "<cmd>LLMAppHandler AttachToChat<cr>",    desc = "󰑖  Chat with Selection" },
      { "<leader>at", mode = "v", "<cmd>LLMAppHandler Translate<cr>",       desc = "󰊿  Translate Text" },
      { "<leader>ae", mode = "v", "<cmd>LLMAppHandler CodeExplain<cr>",     desc = "  Explain Code" },
      { "<leader>ao", mode = "v", "<cmd>LLMAppHandler OptimizeCode<cr>",    desc = "󰾆  Optimize Code" },
      { "<leader>ar", mode = "v", "<cmd>LLMAppHandler Rephrase<cr>",        desc = "󰈼  Rephrase Text" },
      { "<leader>am", mode = "v", "<cmd>LLMAppHandler MarkdownTidy<cr>",    desc = "  Format as Markdown" },
      { "<leader>an", mode = "v", "<cmd>LLMAppHandler NoteSummary<cr>",     desc = "󰈙  Generate Learning Note" },
      { "<leader>aq", mode = "v", "<cmd>LLMAppHandler Ask<cr>",             desc = "󰍉  Ask AI about Text" },
    },
  },
}

