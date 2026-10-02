return {
  "lseppala/praise.nvim",
  event = "VeryLazy",
  config = function()
    require("praise").setup({
      -- <leader>gP belongs to snacks gh_pr(all)
      keymap = "<leader>ga",
    })
  end,
}
