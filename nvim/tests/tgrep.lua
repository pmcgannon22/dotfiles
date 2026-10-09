-- Run with: nvim --headless -u NONE -l tests/tgrep.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
require("snacks").setup({ picker = { enabled = true } })

local Async = require("snacks.picker.util.async")
local tgrep = require("search.tgrep")
local root = vim.fs.normalize(vim.fn.tempname()) .. "-tgrep"
local external
local indexes = {}
local notices = {}
vim.notify = function(message, level)
  notices[#notices + 1] = { message = message, level = level }
end

local function index_path(path)
  local key = vim.fn.has("win32") == 1 and path:lower() or path
  return vim.fn.stdpath("cache") .. "/tgrep/" .. vim.fn.sha256(key)
end

local function search(path, pattern, options)
  local items = {}
  local failure
  local opts = vim.tbl_extend("force", { cwd = path, live = true, hidden = true, regex = true }, options or {})
  local finder = tgrep.grep(opts, { filter = { search = pattern } })
  local task = Async.new(function()
    finder(function(item)
      items[#items + 1] = item
    end)
  end)
  task:on("error", function(err)
    failure = err
  end)
  assert(
    vim.wait(30000, function()
      return not task:running()
    end, 10),
    "Search timed out: " .. pattern
  )
  if failure then
    error(failure)
  end
  return items
end

local function status(path)
  local result = vim.system({ "tgrep", "status", path, "--index-path", index_path(path) }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end

local function check()
  assert(vim.fn.executable("tgrep") == 1, "Install tgrep before running this test")
  local opts = { picker = { sources = { files = { ignored = true } } } }
  local spec = dofile("lua/plugins/snacks.lua")[1]
  local environment = vim.env.NVIM_USE_TGREP
  vim.env.NVIM_USE_TGREP = "0"
  spec.opts(nil, opts)
  assert(opts.picker.sources.grep.finder == nil, "Environment opt-out must retain ripgrep")
  vim.env.NVIM_USE_TGREP = nil
  spec.opts(nil, opts)
  for _, source in ipairs({ "grep", "grep_word", "grep_buffers" }) do
    assert(opts.picker.sources[source].finder == tgrep.grep, source .. " did not use tgrep")
  end
  assert(opts.picker.sources.files.ignored, "Existing picker settings were lost")
  vim.env.NVIM_USE_TGREP = environment

  vim.fn.mkdir(root .. "/.git", "p")
  vim.fn.writefile({ "ignored.txt" }, root .. "/.gitignore")
  vim.fn.writefile({ "prefix UploadSessionEntity", "uploadsessionentity", "other" }, root .. "/normal.txt")
  vim.fn.writefile({ "UploadSessionEntity" }, root .. "/.hidden.txt")
  vim.fn.writefile({ "UploadSessionEntity" }, root .. "/ignored.txt")
  vim.fn.writefile({ "UploadSessionEntityExtra" }, root .. "/word.txt")
  vim.fn.writefile({ "match with spaces" }, root .. "/file with spaces.txt")
  indexes[#indexes + 1] = index_path(root)

  assert(#search(root, "Up") == 0, "Short live query ran")
  assert(not vim.uv.fs_stat(index_path(root)), "Short live query started an index")
  assert(#search(root, "") == 0, "Empty query ran")
  assert(#search(root, "UploadSessionEntity -- --no-ignore") == 4, "Inline traversal option failed")
  assert(not vim.uv.fs_stat(index_path(root)), "Direct scan unnecessarily built an index")

  local matches = search(root, "UploadSessionEntity")
  assert(#matches == 3, "Hidden/ignored search coverage changed")
  local found
  for _, item in ipairs(matches) do
    if item.file:match("normal.txt$") then
      found = item
    end
  end
  assert(found and found.pos[1] == 1 and found.pos[2] == 7, "Wrong jump target")
  assert(found.end_pos[2] == 26 and found.positions[1] == 8, "Wrong match highlight")
  local initial_status = status(root)
  local owned_pid = assert(initial_status:match("PID:%s+(%d+)"))
  assert(#search(root, "uploadsessionentity") == 4, "Smart-case failed")
  assert(status(root):match("PID:%s+(%d+)") == owned_pid, "Server was not reused")
  assert(#search(root, "UploadSessionEntity", { hidden = false }) == 2, "Hidden toggle failed")
  assert(#search(root, "UploadSessionEntity", { ignored = true }) == 4, "Ignored toggle failed")
  assert(#search(root, "UploadSessionEntity", { glob = "normal.txt" }) == 1, "Glob filter failed")
  assert(#search(root, "UploadSessionEntity -- -g normal.txt") == 1, "Inline grep arguments failed")
  assert(#search(root, "UploadSessionEntity", { exclude = { "word.txt" } }) == 2, "Exclusion failed")
  assert(#search(root, "UploadSession(Entity|State)") == 3, "Regex failed")
  assert(#search(root, "UploadSession(Entity|State)", { regex = false }) == 0, "Literal mode failed")
  assert(#search(root, "UploadSessionEntity", { live = false, args = { "--word-regexp" } }) == 2, "Word grep failed")
  assert(#search(root, "match with spaces") == 1, "Path or pattern with spaces failed")
  assert(#search(root, "not-present-anywhere") == 0, "No-match query failed")
  assert(#search(root, "prefix", { buffers = true }) == 0, "Empty buffer list searched the whole directory")
  local buffer = vim.fn.bufadd(root .. "/normal.txt")
  vim.bo[buffer].buflisted = true
  assert(#search(root, "UploadSessionEntity", { buffers = true }) == 1, "Buffer search escaped its file list")

  local picker = Snacks.picker.grep({
    cwd = root,
    search = "prefix",
    finder = tgrep.grep,
    hidden = true,
  })
  assert(
    vim.wait(15000, function()
      return not picker:is_active() and picker:count() == 1 and picker:current() ~= nil
    end, 10),
    "Snacks picker did not display the result"
  )
  picker:action("confirm")
  assert(
    vim.wait(1000, function()
      return vim.api.nvim_buf_get_name(0):match("normal.txt$") ~= nil
    end, 10),
    "Picker confirmation did not open the file"
  )
  assert(vim.api.nvim_win_get_cursor(0)[1] == 1, "Picker jumped to the wrong line")

  local ok, err = pcall(search, root, "[[[")
  assert(not ok and err:find("tgrep search failed", 1, true), "Invalid regex error was hidden")
  assert(#search(root, "prefix") == 1, "Search failed after an invalid pattern")

  vim.fn.writefile({ "UpdatedSearchToken" }, root .. "/normal.txt")
  local refreshed = false
  for _ = 1, 20 do
    if #search(root, "UpdatedSearchToken") == 1 then
      refreshed = true
      break
    end
    vim.wait(100)
  end
  assert(refreshed, "Server did not observe a file save")

  local unicode = vim.fn.nr2char(0x1F642)
  vim.fn.writefile({ string.rep(unicode, 200) .. "LongLineToken" }, root .. "/long.txt")
  local long_line = search(root, "LongLineToken", { args = { "--no-index" } })[1]
  assert(long_line.pos[2] == 800, "Long-line jump column was truncated")
  assert(long_line.line:sub(-11) == "[truncated]", "Long-line display was not bounded")
  assert(long_line.line == string.rep(unicode, 125) .. " [truncated]", "Truncation damaged UTF-8")

  local many = {}
  for _ = 1, 10000 do
    many[#many + 1] = "CancellationToken"
  end
  vim.fn.writefile(many, root .. "/many.txt")
  local delivered = 0
  local cancelled
  local finder = tgrep.grep({
    cwd = root,
    live = true,
    args = { "--no-index" },
  }, { filter = { search = "CancellationToken" } })
  cancelled = Async.new(function()
    finder(function()
      delivered = delivered + 1
      cancelled:abort()
    end)
  end)
  assert(
    vim.wait(15000, function()
      return cancelled:aborted()
    end, 10),
    "Search did not cancel"
  )
  vim.wait(100)
  assert(delivered == 1, "Results arrived after cancellation")
  assert(#search(root, "UpdatedSearchToken") == 1, "Cancellation broke the next search")

  local borrowed = root .. "/borrowed"
  vim.fn.mkdir(borrowed, "p")
  vim.fn.writefile({ "BorrowedSearchToken" }, borrowed .. "/sample.txt")
  indexes[#indexes + 1] = index_path(borrowed)
  external = vim.system({
    "tgrep",
    "serve",
    borrowed,
    "--index-path",
    index_path(borrowed),
    "--hidden",
    "--no-max-filesize",
  }, { stdout = false, stderr = false })
  assert(
    vim.wait(15000, function()
      return status(borrowed):match("Indexing:%s+complete") ~= nil
    end, 100),
    "External server did not become ready"
  )
  assert(#search(borrowed, "BorrowedSearchToken") == 1, "Could not borrow an existing server")

  tgrep.stop()
  assert(not status(root):find("Server status", 1, true), "Owned server survived shutdown")
  assert(status(borrowed):find("Server status", 1, true), "Borrowed server was stopped")
  for _, notice in ipairs(notices) do
    assert(not notice.level or notice.level < vim.log.levels.ERROR, notice.message)
  end
  print(
    "PASS: environment switch, picker navigation, filters, errors, freshness, UTF-8, cancellation and server ownership"
  )
end

local ok, err = xpcall(check, debug.traceback)
tgrep.stop()
if external then
  external:kill(15)
  external:wait(1000)
end
for _, index in ipairs(indexes) do
  vim.fn.delete(index, "rf")
end
vim.fn.delete(root, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
