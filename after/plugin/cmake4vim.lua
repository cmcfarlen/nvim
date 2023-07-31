
vim.g.cmake_compile_commands = true
vim.g.cmake_compile_commands_link = '.'
vim.g.cmake_usr_args = ''
vim.g.cmake_ctest_args = ''
vim.g.make_arguments = ''
vim.g.cmake_build_type = 'Debug'
vim.g.cmake_reload_after_save = true
vim.g.cmake_build_path_pattern = {'cmake-build-%s-%s', 'g:cmake_build_type, g:cmake_selected_kit'}

vim.g.cmake_kits = {
  llvm16 = {
    environment_variables = {
      CXXFLAGS = "-stdlib=libc++",
      LDFLAGS = "-L/usr/lib/llvm-16/lib -fuse-ld=lld -stdlib=libc++"
    },
    compilers = {
      C = 'clang',
      CXX = 'clang++',
    },
    generator = "Ninja",
  },
}
vim.g.cmake_selected_kit = 'llvm16'


