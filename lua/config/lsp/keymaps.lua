local M = {}

function M.setup_global()
  local opts = { noremap=true, silent=true }
  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '<leader>E', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '<leader>e', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)
end

local function do_quickfix()
  vim.lsp.buf.code_action({
    filter = function(a) return a.isPreferred end,
    apply = true
  })
end

function M.setup(bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  -- disabled: using trouble's
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  -- disabled, using different plugin
  -- vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  vim.keymap.set('n', '<leader>x', '<cmd>TroubleToggle<cr>', bufopts)
  vim.keymap.set('n', 'gr', '<cmd>TroubleToggle lsp_references<cr>', bufopts)

  vim.keymap.set('n', '<leader>f', do_quickfix, opts)
end

return M
