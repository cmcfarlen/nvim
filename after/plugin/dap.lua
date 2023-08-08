local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-vscode',
  name = 'lldb'
}

local get_cmake_path = function()
  local f = vim.fn['utils#cmake#getBinaryPath']
  return f()
end

dap.configurations.cpp = {
  {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return get_cmake_path()
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

local dw = require('dap.ui.widgets')

vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end, {})
vim.keymap.set('n', '<F7>', function() dap.step_into() end, {})
vim.keymap.set('n', '<F8>', function() dap.step_over() end, {})
vim.keymap.set('n', '<F9>', function() dap.continue() end, {})
vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end)


vim.keymap.set({'n', 'v'}, '<Leader>dh', function() dw.hover() end)
vim.keymap.set({'n', 'v'}, '<Leader>dp', function() dw.preview() end)
vim.keymap.set('n', '<Leader>df', function()
  dw.centered_float(dw.frames)
end)
vim.keymap.set('n', '<Leader>ds', function()
  dw.centered_float(dw.scopes)
end)

