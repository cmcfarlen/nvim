ntest = require("neotest")
ntest.setup({
  adapters = {
    require("neotest-ctest"),
  },
})


vim.keymap.set("n", "<leader>tt", function() ntest.run.run() end)
