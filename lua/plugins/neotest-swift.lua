-- swift-testing adapter for neotest, using sourcekit-lsp for test discovery.
--
-- It lives on internal GHE, which the Linux host cannot reach, so the whole spec
-- is gated rather than left to fail at clone time. ctest.lua registers it with a
-- pcall, so nothing breaks where it is absent.
--
-- swift-testing (@Test / @Suite) only; the author has explicitly ruled out
-- XCTest support, so XCTest packages will not show tests.
--
-- Needs a `swift build` before sourcekit-lsp reports any tests in a package.
return {
	"neotest-swift",
	url = "git@github.pie.apple.com:jerryjrchen/neotest-swift.git",
	lazy = true,
	enabled = vim.uv.os_uname().sysname == "Darwin",
}
