-- ┌─────────────────────┐
-- │ Ranger's org plugin │
-- └─────────────────────┘

-- everything org in one file: orgmode and its capture templates, the org keymaps, and the git sync that keeps the org folder on github for my phone
-- lives at ~/.config/nvim/lua/ranger/org.lua and is loaded by require('ranger.org') in init.lua
-- needs mini.clue to be set up first (for the menu group names) and neogit installed (for <Leader>og)

-- the one setting: where the org files live. this folder is also the git repo that gets synced
local dir = vim.fs.normalize('~/org')

-- ┌─────────┐
-- │ Orgmode │
-- └─────────┘

-- install nvim-orgmode
vim.pack.add { 'https://github.com/nvim-orgmode/orgmode' }

-- to be honest, im not totally sure how this works to overwrite the orgmode normal buffer menu for selecting things. i guess overwriting the keymaps for the selections? no
require('orgmode').setup {
  -- disable the org agenda and org capture keymaps, so we can set them via clues and give them a cleaner name
  -- you could technically set the descriptions for the maps via .set_mapping_desc, however there is some timing issue i dont want to figure out
  mappings = {
    global = { org_agenda = false, org_capture = false },
    org = { org_meta_return = { '<Leader>oj', desc = 'org meta return' } },
    capture = { org_capture_finalize = { '<Leader>os', desc = 'org save' } },
  },
  org_agenda_files = dir .. '/**/*',
  -- where captures go by default i guess? idk
  org_default_notes_file = dir .. '/inbox.org',
  -- setup custom capture templates.
  org_capture_templates = {
    t = { description = 'Task', template = '* TODO %^{Task} :task:\n  %U\n  %?', target = dir .. '/inbox.org' },
    n = { description = 'Note', template = '* %? :note:\n  %U', target = dir .. '/inbox.org' },
    j = { description = 'Journal', template = '* %<%H:%M> %?', target = dir .. '/journal.org', datetree = true },
    e = { description = 'Event', template = '* %^{Title} :event:\n  %^T\n  %?', target = dir .. '/inbox.org' },
    m = { description = 'Meeting', template = '* %^{Title} :meeting:\n  %U\n  %?', target = dir .. '/inbox.org' },
  },
}

-- this is some tokenmaxxed command to enable the miniclue menu in the fake buffers for the org agendas
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'org', 'orgagenda' },
  callback = vim.schedule_wrap(function() MiniClue.ensure_buf_triggers() end),
})

-- Experimental LSP support
vim.lsp.enable('org')

-- ┌─────────┐
-- │ Keymaps │
-- └─────────┘

-- group names for the mini.clue menu. mini.clue reads this list every time the menu opens, so adding to it after its setup works
if MiniClue then
  vim.list_extend(MiniClue.config.clues, {
    { mode = 'n', keys = '<Leader>o', desc = '+Org' },
    { mode = 'n', keys = '<Leader>oa', desc = '+Agenda' },
    { mode = 'n', keys = '<Leader>oc', desc = '+Capture' },
  })
end

-- set the keymaps for the org functions
vim.keymap.set('n', '<Leader>oaa', '<Cmd>Org agenda a<CR>', { desc = 'Agenda (week)' })
vim.keymap.set('n', '<Leader>oat', '<Cmd>Org agenda t<CR>', { desc = 'Todo list' })
vim.keymap.set('n', '<Leader>oam', '<Cmd>Org agenda m<CR>', { desc = 'Tags' })
vim.keymap.set('n', '<Leader>oaM', '<Cmd>Org agenda M<CR>', { desc = 'Tags (todo only)' })
vim.keymap.set('n', '<Leader>oas', '<Cmd>Org agenda s<CR>', { desc = 'Search' })
vim.keymap.set('n', '<Leader>oct', '<Cmd>Org capture t<CR>', { desc = 'Task' })
vim.keymap.set('n', '<Leader>ocn', '<Cmd>Org capture n<CR>', { desc = 'Note' })
vim.keymap.set('n', '<Leader>ocj', '<Cmd>Org capture j<CR>', { desc = 'Journal' })
vim.keymap.set('n', '<Leader>oce', '<Cmd>Org capture e<CR>', { desc = 'Event' })
vim.keymap.set('n', '<Leader>ocm', '<Cmd>Org capture m<CR>', { desc = 'Meeting' })

-- open neogit on the org repo from anywhere. this is the one to hit when the sync reports a conflict
vim.keymap.set('n', '<Leader>og', '<Cmd>Neogit cwd=' .. dir .. '<CR>', { desc = 'Org git status' })

-- ┌──────────┐
-- │ Git sync │
-- └──────────┘

-- syncs the org folder to github when nvim starts and whenever a file in it is saved:
--   commit local changes -> merge the remote -> push
-- on a conflict it stops, tells you, and waits. run :OrgConflicts (or <Leader>og) to get to the conflict markers, fix them and save. that save finishes the merge and pushes
-- nothing is ever committed while conflict markers remain
--
-- commands:  :OrgSync       sync now
--            :OrgConflicts  put every conflict in the quickfix list and jump to the first

-- no sync if this machine has no org folder
-- also no sync if nvim was opened by git as its editor (commit message, rebase todo): never run a sync underneath a git command that is still in progress
if vim.fn.isdirectory(dir) == 0 or vim.env.GIT_EXEC_PATH then return end

-- exit codes: 0 = synced, 3 = waiting on conflicts (files on stdout), anything else = error (reason on stderr)
local script = [[
merging() { [ -f "$(git rev-parse --git-path MERGE_HEAD)" ]; }

# unmerged files that still contain conflict markers
conflicted() {
  git diff --name-only --diff-filter=U -z | xargs -0 grep -lE '^(<<<<<<<|>>>>>>>)' 2>/dev/null
}

# conclude a merge, unless markers are still there
finish_merge() {
  files=$(conflicted)
  if [ -n "$files" ]; then echo "$files"; exit 3; fi
  git add -A && git commit -q --no-edit || exit 1
}

cd "$(git rev-parse --show-toplevel)" || exit 1

# mid-rebase or otherwise off a branch: someone is doing git by hand, stay out
if ! git symbolic-ref -q HEAD >/dev/null; then
  echo "HEAD is not on a branch (rebase in progress?), leaving the repo alone" >&2
  exit 1
fi

if merging; then
  finish_merge
else
  git add -A || exit 1
  git diff --cached --quiet || git commit -qm "auto: $(date)" || exit 1
fi

if ! git pull -q --no-rebase --no-edit >/dev/null; then
  merging || exit 1 # not a conflict: offline, no upstream, ...
  finish_merge
fi

git push -q || exit 1
]]

local running, pending = false, false
local last -- last problem reported, so the same one isnt repeated on every save

local function report(msg, level)
  if msg ~= last then vim.notify('[org sync] ' .. msg, level) end
  last = msg
end

local function sync()
  if running then
    pending = true
    return
  end
  running = true
  -- detached, so a sync started by :wq still finishes after nvim exits
  vim.system(
    { 'sh', '-c', script },
    { cwd = dir, text = true, detach = true, env = { GIT_TERMINAL_PROMPT = '0' } },
    vim.schedule_wrap(function(res)
      running = false
      pcall(vim.cmd, 'checktime') -- reload buffers the merge changed on disk
      if res.code == 0 then
        if last then vim.notify('[org sync] back in sync') end
        last = nil
      elseif res.code == 3 then
        local files = vim.trim(res.stdout or ''):gsub('\n', ', ')
        report('merge conflict in ' .. files .. ' - run :OrgConflicts, fix the markers, save', vim.log.levels.WARN)
      else
        report('sync failed: ' .. vim.trim(res.stderr or ''), vim.log.levels.ERROR)
      end
      if pending then
        pending = false
        sync()
      end
    end)
  )
end

local function conflicts()
  local root = vim.fs.root(dir, '.git') or dir
  local out = vim.system({ 'git', 'diff', '--name-only', '--diff-filter=U' }, { cwd = root, text = true }):wait().stdout or ''
  local items = {}
  for file in out:gmatch('[^\n]+') do
    local path = root .. '/' .. file
    local ok, lines = pcall(vim.fn.readfile, path)
    for lnum, line in ipairs(ok and lines or {}) do
      if line:find('^<<<<<<<') then items[#items + 1] = { filename = path, lnum = lnum, text = line } end
    end
  end
  if #items == 0 then return vim.notify('[org sync] no conflicts') end
  vim.fn.setqflist({}, ' ', { title = 'org conflicts', items = items })
  vim.cmd('cfirst')
end

local group = vim.api.nvim_create_augroup('ranger_org_sync', { clear = true })
vim.api.nvim_create_autocmd('VimEnter', { group = group, callback = sync })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  pattern = dir .. '/*',
  callback = function(ev)
    -- saves inside .git/ are a git ui (neogit) writing a commit message or rebase todo: a git command is mid-flight, dont sync under it
    if not ev.match:find('/.git/', 1, true) then sync() end
  end,
})
vim.api.nvim_create_user_command('OrgSync', sync, { desc = 'Sync the org folder with git now' })
vim.api.nvim_create_user_command('OrgConflicts', conflicts, { desc = 'Jump to git conflict markers in the org folder' })
