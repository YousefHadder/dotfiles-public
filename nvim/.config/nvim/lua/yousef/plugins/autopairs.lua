return {
  "windwp/nvim-autopairs",
  -- TEMP(#376 manual testing): disabled — it also maps <BS> (map_bs) and, loading at
  -- InsertEnter, would override mini.pairs' <BS> and muddy the fallback tests.
  -- Remove `enabled = false` after testing.
  enabled = false,
  event = { "InsertEnter" },
  config = function()
    require("nvim-autopairs").setup({
      check_ts = true,
    })
  end,
}
