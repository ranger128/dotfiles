-- ┌──────────────────────┐
-- │ Ranger's nvim Config │
-- └──────────────────────┘

-- ┌─────────┐
-- │ Options │
-- └─────────┘

-- caches lua modules as bytecode so they arent recompiled or reparsed everytime you start neovim. not sure why you wouldnt have this on
vim.loader.enable()

-- sets the leader key to space. this has to happen prior to plugins being loaded, otherwise the plugins will pick up the default leader key which i think is like ctrl or something
vim.g.mapleader = ' '

-- some plugins use localleader instead. supposedly localleader is for plugins to have access to a filetype specific key? im not actually sure what its for but i will set it anyways
vim.g.maplocalleader = ' '

-- make the <tab> key insert 4 spaces instead of a tab character
vim.o.expandtab = true

-- enable line numbers by default
vim.o.number = true

-- when you have a tabbed line, this setting makes it so a wrapped line (too long to fit on the screen so it makes a new line) also displays tabbed in. can make files with long lines a lot more clean
vim.o.breakindent = true

-- toggles whether the mode is shown. i will get a status line plugin so i will need to turn this off later
vim.o.showmode = false

-- sync the clipboard between neovim and the os. macos uses pbcopy, so if i ever use this config on a different os, i will need to change this setting
-- also, this uses the system clipboard for all yanks, including deletes. might not actually want this
-- :help clipboard
vim.o.clipboard = 'unnamedplus'

-- this creates an file in some directory that tracks changes to the file, so you can use :undo even after saving and closing the file and reopening it
vim.o.undofile = true

-- ignore case when searching
-- you can reenable case sensitivity by adding \C to the pattern
vim.o.ignorecase = true

-- ignore case only when the pattern is all lowercase. meaning '/the' will match 'the' and 'The' but 'The' will match only 'The', not 'the'
vim.o.smartcase = true

-- adds a gutter to the left of the line numbers for displaying icons and such
vim.o.signcolumn = 'yes'

-- make whitespace characters visible. this can be sort of annoying while typing, since every space is technically a trailing space until you put characters after it
vim.o.list = true

-- highlight the whole line your cursor is on
vim.o.cursorline = true

-- disable modelines. the modeline sets specific options for the file, and can be used as an attack surface. disable it for security
vim.o.modeline = false

-- ┌────────────────────┐
-- │ Keymaps & Autocmds │
-- └────────────────────┘

-- clear highlighting from searching by pressing escape
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- kickstart has some diagnostic stuff here but i dont really care right now

-- highlight lines when yanking them
vim.api.nvim_create_autocmd('TextYankPost', { callback = function() vim.hl.on_yank() end })

-- ┌─────────┐
-- │ Plugins │
-- └─────────┘

-- setup colorscheme. gruvbox-material
vim.pack.add { 'sainnhe/gruvbox-material' }
vim.cmd.colorscheme 'gruvbox-material'

-- install mini.nvim plugins.
vim.pack.add { 'nvim-mini/mini.nvim' }

-- setup the mini.nvim statusline. the thing at the bottom that shows the mode and such
require('mini.statusline').setup {}

-- make the cursor location section in the statusline LINE:COLUMN. pad the numbers so the section doesnt jitter
MiniStatusline.section_location = function()
  return '%2l:%-2v'
end

-- setup mini.icons. these can be used in other mini plugins
-- i actually want to see how it looks without icons. looks a little more raw
-- require('mini.icons').setup()

-- install guess indent. this should keep my tabs consistent per file? that way if i want to use shorter ones i can
vim.pack.add { 'NMAC427/guess-indent.nvim' }
require('guess-indent').setup {}

-- setup the mini.nvim tabline. this is the bar at the top that shows open buffers
require('mini.tabline').setup {}

-- setup the mini.starter. different start page custom
require('mini.starter').setup {}

-- setup mini.files. this replaces the vim explorer for looking through directories, and lets you modify the filesystem like a buffer
require('mini.files').setup {}

-- setup mini.cmdline. improves :e autocomplete and stuff
require('mini.cmdline').setup {}

-- setup mini.clue. this shows you available commands(?). example, press space, shows commands that could come after space, press one, shows commands that could come after etc. bad explanation
require('mini.clue').setup {
  -- the pause between hitting a clue key and the menu showing up. longer than necessary so you have time to hit remembered motions without the menu churning
  window = { delay = 500 },
  clues = {
    -- anything that is just a group should go here. things that is a mapping (ie. it does something) should be in keymaps
    { mode = 'n', keys = '<Leader>o',  desc = '+org' },
    { mode = 'n', keys = '<Leader>oa', desc = '+Agenda' },
    { mode = 'n', keys = '<Leader>oc', desc = '+Capture' },
  },
  triggers = {
    { mode = { 'n', 'x' }, keys = '<Leader>' },
  }
}

-- install mini.pick. a custom window that allows you to fuzzy search a bunch of different modules types
require('mini.pick').setup {}

-- install mini.jump2d. this is hard to explain but basically you hit enter and it provides jump spots on the page
require('mini.jump2d').setup {}

-- install mini.pairs. this just autocompletes brackets and quotes and such
require('mini.pairs').setup {}

-- ┌──────────┐
-- │ Org mode │
-- └──────────┘

-- install nvim-orgmode
vim.pack.add { 'nvim-orgmode/orgmode' }

-- to be honest, im not totally sure how this works to overwrite the orgmode normal buffer menu for selecting things. i guess overwriting the keymaps for the selections? no
require('orgmode').setup {
  -- disable the org agenda and org capture keymaps, so we can set them via clues and give them a cleaner name
  -- you could technically set the descriptions for the maps via .set_mapping_desc, however there is some timing issue i dont want to figure out
  mappings = {
    global = { org_agenda = false, org_capture = false },
    org = { org_meta_return = { '<Leader>oj', desc = 'Org: new heading/item' } },
    capture = { org_capture_finalize = { '<Leader>os', desc = 'Capture: save' } },
  },
  org_agenda_files = '~/org/**/*',
  -- where captures go by default i guess? idk
  org_default_notes_file = '~/org/inbox.org',
  -- setup custom capture templates.
  org_capture_templates = {
    t = { description = 'Task', template = '* TODO %?\n  %u', target = '~/org/tasks.org' },
    n = { description = 'Note', template = '* %?\n  %U', target = '~/org/notes.org' },
    j = { description = 'Journal', template = '* %<%H:%M> %?', target = '~/org/journal.org', datetree = true },
    e = { description = 'Event', template = '* %?\n  %^T', target = '~/org/events.org' },
  },
}

-- this is some tokenmaxxed command to enable the miniclue menu in the fake buffers for the org agendas
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'org', 'orgagenda' },
  callback = vim.schedule_wrap(function() MiniClue.ensure_buf_triggers() end),
})

-- set the keymaps for the org functions
vim.keymap.set('n', '<Leader>oaa', '<Cmd>Org agenda a<CR>', { desc = 'Agenda (week)' })
vim.keymap.set('n', '<Leader>oat', '<Cmd>Org agenda t<CR>', { desc = 'Todo list' })
vim.keymap.set('n', '<Leader>oam', '<Cmd>Org agenda m<CR>', { desc = 'Tags' })
vim.keymap.set('n', '<Leader>oaM', '<Cmd>Org agenda M<CR>', { desc = 'Tags (todo only)' })
vim.keymap.set('n', '<Leader>oas', '<Cmd>Org agenda s<CR>', { desc = 'Search' })
vim.keymap.set('n', '<Leader>oct', '<Cmd>Org capture t<CR>', { desc = 'Capture: task' })
vim.keymap.set('n', '<Leader>ocn', '<Cmd>Org capture n<CR>', { desc = 'Capture: note' })
vim.keymap.set('n', '<Leader>ocj', '<Cmd>Org capture j<CR>', { desc = 'Capture: journal' })
vim.keymap.set('n', '<Leader>oce', '<Cmd>Org capture e<CR>', { desc = 'Capture: event' })
