return {
  "mfussenegger/nvim-dap",
  dependencies = {
    { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
    "theHamsta/nvim-dap-virtual-text",
    { "mfussenegger/nvim-dap-python", ft = "python" },
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
    { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "DAP UI" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local data = vim.fn.stdpath("data")

    dapui.setup()
    require("nvim-dap-virtual-text").setup()

    -- Python (debugpy from mason)
    local ok_py, dappy = pcall(require, "dap-python")
    if ok_py then
      local mason_py = data .. "/mason/packages/debugpy/venv/bin/python"
      dappy.setup((vim.uv or vim.loop).fs_stat(mason_py) and mason_py or "python3")
    end

    -- JS/TS (js-debug-adapter from mason)
    local js_debug = data .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = { command = "node", args = { js_debug, "${port}" } },
    }
    for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
      dap.configurations[ft] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
      }
    end

    -- C/C++ (codelldb from mason). Rust is handled by rustaceanvim.
    local codelldb = data .. "/mason/packages/codelldb/extension/adapter/codelldb"
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = { command = codelldb, args = { "--port", "${port}" } },
    }
    for _, ft in ipairs({ "c", "cpp" }) do
      dap.configurations[ft] = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
    end

    -- auto open/close the UI around sessions
    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
  end,
}
