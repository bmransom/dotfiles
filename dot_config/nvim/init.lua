-- init.lua — entry point
if vim.fn.has("nvim-0.11") == 0 then
  error("This config requires Neovim 0.11+ (you have an older build)")
end

-- Required-ish external tools. Warn (do NOT error) so a missing optional dep
-- can never brick the editor at startup.
for _, dep in ipairs({ "git", "rg", { "fd", "fdfind" } }) do
  local names = type(dep) == "table" and dep or { dep }
  local found = false
  for _, n in ipairs(names) do
    if vim.fn.executable(n) == 1 then
      found = true
      break
    end
  end
  if not found then
    vim.schedule(function()
      vim.notify("Missing recommended tool: " .. table.concat(names, "/"), vim.log.levels.WARN)
    end)
  end
end

require("config")
