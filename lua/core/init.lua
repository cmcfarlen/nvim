

-- quick-scope only reads the value of this at load time, so needs to go up front here
vim.g.qs_highlight_on_keys = {'f', 't', 'F', 'T'}

require("core.plugins")
require("core.remap")
require("core.set")
