return {
	"stevearc/overseer.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	opts = {},
	config = function()
		require("overseer").setup({
			templates = {
				"builtin",
			},
		})
	end,
}
