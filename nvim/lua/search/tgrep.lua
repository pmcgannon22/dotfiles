local M = {}
local uv = vim.uv
local servers = {}
local stopping = false

-- Run inside a Snacks finder so changing the query cancels its client process.
local function run(args, cwd, on_line)
  local task = assert(require("snacks.picker.util.async").running())
  local queue = require("snacks.picker.util.queue").new()
  local result
  local read_error
  local process
  for _, event in ipairs({ "done", "abort" }) do
    task:on(event, function()
      if process and not result then
        process:kill(9)
      end
    end)
  end
  task:schedule(function()
    if task:aborted() then
      return
    end
    process = vim.system(vim.list_extend({ "tgrep" }, args), {
      cwd = cwd,
      text = true,
      stdout = on_line and function(err, data)
        read_error = err or read_error
        if data then
          queue:push(data)
        end
        task:resume()
      end or nil,
    }, function(completed)
      result = completed
      task:resume()
    end)
  end)

  local pending = ""
  while not result or not queue:empty() do
    if queue:empty() then
      task:suspend()
    else
      pending = pending .. queue:pop()
      while true do
        local newline = pending:find("\n", 1, true)
        if not newline then
          break
        end
        on_line(pending:sub(1, newline - 1))
        pending = pending:sub(newline + 1)
      end
    end
  end
  assert(not read_error, read_error)
  if on_line and pending ~= "" then
    on_line(pending)
  end
  return result
end

local function ready(server)
  local task = assert(require("snacks.picker.util.async").running())
  while true do
    if server.error then
      error(server.error)
    end
    local status = run({ "status", server.cwd, "--index-path", server.index }, server.cwd)
    assert(status.code == 0, status.stderr)
    if status.stdout:find("Server status", 1, true) then
      if status.stdout:match("Indexing:%s+complete") and status.stdout:match("Hidden coverage:%s+complete") then
        return
      end
    elseif not server.process then
      task:schedule(function()
        if server.process or task:aborted() then
          return
        end
        vim.fn.mkdir(server.index, "p")
        local log = assert(io.open(server.index .. "/server.log", "a"))
        server.process = vim.system({
          "tgrep",
          "serve",
          server.cwd,
          "--index-path",
          server.index,
          "--hidden",
          "--no-max-filesize",
          "--exclude",
          ".bare",
        }, {
          text = true,
          stdout = false,
          stderr = function(err, data)
            if data then
              log:write(data)
              log:flush()
            end
            if err then
              server.error = "tgrep server log read failed: " .. err
            end
          end,
        }, function(result)
          log:close()
          server.process = nil
          if not stopping then
            server.error = ("tgrep server exited (%d). See %s/server.log"):format(result.code, server.index)
            vim.schedule(function()
              vim.notify(server.error, vim.log.levels.ERROR)
            end)
          end
        end)
        vim.notify("Preparing tgrep index: " .. server.cwd)
      end)
    end
    task:sleep(1000)
  end
end

function M.stop()
  stopping = true
  for _, server in pairs(servers) do
    if server.process then
      server.process:kill(15)
    end
  end
  for _, server in pairs(servers) do
    if server.process then
      server.process:wait(1000)
    end
  end
  servers = {}
  stopping = false
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("tgrep-servers", { clear = true }),
  callback = M.stop,
})

---@param opts snacks.picker.grep.Config
---@param ctx snacks.picker.finder.ctx
---@return snacks.picker.finder.async
function M.grep(opts, ctx)
  local pattern, extra = Snacks.picker.util.parse(ctx.filter.search)
  if pattern == "" or (opts.live and vim.fn.strchars(pattern) < 3) then
    return function() end
  end
  if vim.fn.executable("tgrep") == 0 then
    vim.notify(
      "tgrep is not installed. Install tgrep or set NVIM_USE_TGREP=0 before starting Neovim.",
      vim.log.levels.ERROR
    )
    return function() end
  end

  local cwd = vim.fs.normalize(assert(uv.fs_realpath(opts.cwd or uv.cwd())))
  local args = {
    "--json",
    "--line-buffered",
    "--color=never",
    "--smart-case",
    "--no-max-filesize",
    "--glob=!.git",
    "--glob=!.bare",
  }
  if opts.hidden then
    args[#args + 1] = "--hidden"
  end
  if opts.ignored then
    args[#args + 1] = "--no-ignore"
  end
  if opts.follow then
    args[#args + 1] = "--follow"
  end
  if opts.regex == false then
    args[#args + 1] = "--fixed-strings"
  end
  for _, exclude in ipairs(opts.exclude or {}) do
    vim.list_extend(args, { "--glob", "!" .. exclude })
  end
  for _, option in ipairs({ { opts.ft, "--type" }, { opts.glob, "--glob" } }) do
    local values = type(option[1]) == "table" and option[1] or { option[1] }
    for _, value in ipairs(values) do
      vim.list_extend(args, { option[2], value })
    end
  end
  vim.list_extend(args, opts.args or {})
  vim.list_extend(args, extra)

  local paths = vim.deepcopy(opts.dirs or {})
  if opts.buffers then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.bo[buf].buflisted and uv.fs_stat(name) then
        paths[#paths + 1] = name
      end
    end
    if #paths == 0 then
      return function() end
    end
  end
  if opts.rtp then
    vim.list_extend(paths, Snacks.picker.util.rtp())
  end

  local scan = #paths > 0 or opts.ignored or opts.follow
  local scan_flags = {
    ["--no-index"] = true,
    ["--no-ignore"] = true,
    ["--follow"] = true,
    ["-L"] = true,
    ["--ignore-file"] = true,
    ["--one-file-system"] = true,
    ["-u"] = true,
    ["-uu"] = true,
    ["-uuu"] = true,
  }
  for _, arg in ipairs(args) do
    scan = scan or scan_flags[arg:match("^[^=]+")]
  end
  local server
  if scan then
    if not vim.tbl_contains(args, "--no-index") then
      args[#args + 1] = "--no-index"
    end
  else
    local key = vim.fn.has("win32") == 1 and cwd:lower() or cwd
    local home = vim.fs.normalize(uv.os_homedir())
    home = vim.fn.has("win32") == 1 and home:lower() or home
    if key == home or vim.fs.dirname(cwd) == cwd then
      vim.notify(
        "Refusing to index a home directory or filesystem root. Select a project directory.",
        vim.log.levels.ERROR
      )
      return function() end
    end
    servers[key] = servers[key]
      or {
        cwd = cwd,
        index = vim.fn.stdpath("cache") .. "/tgrep/" .. vim.fn.sha256(key),
      }
    server = servers[key]
    vim.list_extend(args, { "--index-path", server.index })
  end
  vim.list_extend(args, { "--", pattern })
  vim.list_extend(args, #paths > 0 and paths or { "." })

  return function(cb)
    if server then
      ready(server)
    end
    local result = run(args, cwd, function(line)
      local event = vim.json.decode(line)
      if event.type ~= "match" then
        return
      end
      local data = event.data
      local text = data.lines.text:gsub("\r?\n$", "")
      local first = data.submatches[1] or { start = 0, ["end"] = 0 }
      local length = #text > 500 and 500 + vim.str_utf_start(text, 501) or #text
      local display = #text > length and text:sub(1, length) .. " [truncated]" or text
      local item = {
        cwd = cwd,
        file = data.path.text,
        pos = { data.line_number, first.start },
        end_pos = { data.line_number, first["end"] },
        line = display,
        text = data.path.text .. ":" .. data.line_number .. ":" .. (first.start + 1) .. ":" .. display,
        positions = {},
      }
      for _, match in ipairs(data.submatches) do
        for column = match.start + 1, math.min(match["end"], length) do
          item.positions[#item.positions + 1] = column
        end
      end
      cb(item)
    end)
    if result.code > 1 then
      error("tgrep search failed: " .. result.stderr)
    elseif result.stderr ~= "" then
      vim.schedule(function()
        vim.notify(result.stderr, vim.log.levels.WARN)
      end)
    end
  end
end

return M
