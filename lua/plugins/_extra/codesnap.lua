return {
	"mistricky/codesnap.nvim",
	build = "make build_generator",
	cmd = { "CodeSnap", "CodeSnapSave", "CodeSnapASCII", "CodeSnapHighLight", "CodeSnapSaveHighLight" },
	opts = {
		save_path = "~/Pictures",
		has_breadcrumbs = true,
		has_line_number = true,
		bg_theme = "sea",
	},
}
