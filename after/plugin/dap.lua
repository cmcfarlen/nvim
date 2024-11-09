local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-vscode',
  name = 'lldb'
}

--
-- For swift:
-- You gotta run codelldb
-- codelldb --port 4321 --liblldb /home/cmcfarlen/.swiftenv/versions/5.9.1/usr/lib/liblldb.so
--
dap.adapters.codelldb = {
  type = 'server',
  host = '127.0.0.1',
  port = 4321,
  name = 'codelldb'
}

dap.adapters.swiftlldb = {
  type = 'executable',
  command = '/Applications/Xcode.app/Contents/Developer/usr/bin/lldb-dap',
  name = 'swiftlldb'
  
}

local get_cmake_path = function()
  return "/opt/ats-cmake/bin/traffic_server"
end

local find_swift_bindir = function()
  return vim.fn.system { 'swift', 'build', '--show-bin-path' }
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
    args = {"-R", "1"},
  },
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

dap.configurations.swift = {
  {
    name = 'Launch Swift',
    type = 'swiftlldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', find_swift_bindir() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}

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
vim.keymap.set('n', '<Leader>dt', function()
  dw.centered_float(dw.threads)
end)

