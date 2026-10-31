-- ┌──────────────────────┐
-- │ Ranger Neovim Config │
-- └──────────────────────┘

vim.pack.add({
    'https://github.com/nvim-mini/mini.nvim',
    'https://github.com/ellisonleao/gruvbox.nvim',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-orgmode/orgmode',
})

vim.o.background = "dark"
vim.cmd("colorscheme gruvbox")

vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4

-- ┌───────────┐
-- │ mini.nvim │
-- └───────────┘

require('mini.git').setup()
require('mini.statusline').setup()
require('mini.icons').setup()
require('mini.pairs').setup()
require('mini.pick').setup()
require('mini.files').setup()
require('mini.cmdline').setup()

-- ┌─────────┐
-- │ Orgmode │
-- └─────────┘

require('orgmode').setup({
    org_agenda_files = '~/org/**/*',
    org_default_notes_file = '~/org/inbox.org',
    org_capture_templates = {
        t = { description = 'Task',    template = '* TODO %?\n  %u', target = '~/org/tasks.org' },
        e = { description = 'Event',   template = '* %?\n  %^t',     target = '~/org/calendar.org' },
        m = { description = 'Meeting', template = '* %?\n  %T',      target = '~/org/meetings.org' },
        j = { description = 'Journal', template = '* %<%H:%M> %?',   target = '~/org/journal.org', datetree = true },
    },
})
