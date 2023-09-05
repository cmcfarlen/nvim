require("cmake-tools").setup({
  cmake_build_directory = "cmake-build-debug-llvm-16",
  cmake_dap_configuration = { -- debug settings for cmake
    name = "cpp",
    type = "lldb",
    request = "launch",
    stopOnEntry = false,
 --   runInTerminal = true,
 --   console = "integratedTerminal",
  },
})
