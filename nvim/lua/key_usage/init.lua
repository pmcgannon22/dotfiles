local M = {}

local defaults = {
  batch_size = 100,
  data_dir = vim.fs.joinpath(vim.fn.stdpath("state"), "key-usage"),
  enabled = #vim.api.nvim_list_uis() > 0,
  flush_interval_ms = 5000,
}

local state = {
  enabled = false,
  flush_scheduled = false,
  last_key_time = nil,
  namespace = nil,
  options = nil,
  queue = {},
  session_id = nil,
  setup = false,
  timer = nil,
}

local allowed_actions = {
  disable = true,
  enable = true,
  flush = true,
  path = true,
  status = true,
  toggle = true,
}

local function event_time()
  local timestamp = os.time()
  return {
    date = os.date("%Y-%m-%d", timestamp),
    timestamp = timestamp,
  }
end

local function queue_event(event)
  local time = event_time()
  event.date = time.date
  event.session = state.session_id
  event.timestamp = time.timestamp
  table.insert(state.queue, event)

  if #state.queue >= state.options.batch_size and not state.flush_scheduled then
    state.flush_scheduled = true
    vim.schedule(function()
      state.flush_scheduled = false
      M.flush()
    end)
  end
end

local function write_events(events)
  vim.fn.mkdir(state.options.data_dir, "p")

  local events_by_date = {}
  for _, event in ipairs(events) do
    events_by_date[event.date] = events_by_date[event.date] or {}
    table.insert(events_by_date[event.date], vim.json.encode(event))
  end

  for date, lines in pairs(events_by_date) do
    local path = vim.fs.joinpath(state.options.data_dir, date .. ".jsonl")
    local result = vim.fn.writefile(lines, path, "a")
    if result ~= 0 then
      error("Could not append key usage events to " .. path)
    end
  end
end

function M.flush()
  if #state.queue == 0 then
    return
  end

  local events = state.queue
  state.queue = {}

  local success, message = pcall(write_events, events)
  if success then
    return
  end

  for index = #events, 1, -1 do
    table.insert(state.queue, 1, events[index])
  end

  vim.notify("Key usage logging failed: " .. tostring(message), vim.log.levels.ERROR, { title = "Key usage" })
end

local function is_tracked_mode(mode)
  if mode:sub(1, 2) == "nt" then
    return false
  end

  return mode:match("^n") ~= nil or mode:match("^[vV\22sS\19]") ~= nil
end

local function mapping_modes(mode)
  if mode:sub(1, 2) == "no" then
    return { "o" }
  end

  if mode:match("^n") then
    return { "n" }
  end

  if mode:match("^[vV\22]") then
    return { "x", "v" }
  end

  return { "s", "v" }
end

local function mapping_context(mode, typed)
  for _, candidate_mode in ipairs(mapping_modes(mode)) do
    local mapping = vim.fn.maparg(typed, candidate_mode, false, true)
    if type(mapping) == "table" and mapping.lhs ~= nil and mapping.lhs ~= "" then
      return {
        description = mapping.desc ~= nil and mapping.desc or nil,
        lhs = mapping.lhs,
      }
    end
  end

  return nil
end

local function record_key(key, typed)
  if not state.enabled or typed == "" then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if not is_tracked_mode(mode) or vim.fn.getcmdtype() ~= "" then
    return
  end

  local now = vim.uv.hrtime()
  local elapsed_ms = nil
  if state.last_key_time ~= nil then
    elapsed_ms = math.floor((now - state.last_key_time) / 1000000)
  end
  state.last_key_time = now

  local event = {
    buffer_type = vim.bo.buftype,
    elapsed_ms = elapsed_ms,
    event = "key",
    filetype = vim.bo.filetype,
    keys = vim.fn.keytrans(typed),
    mode = mode,
  }

  local resolved = vim.fn.keytrans(key)
  if resolved ~= event.keys then
    event.resolved = resolved
  end

  local mapping = mapping_context(mode, typed)
  if mapping ~= nil then
    event.mapping = mapping
  end

  queue_event(event)
end

local function start_timer()
  if state.timer ~= nil then
    return
  end

  state.timer = assert(vim.uv.new_timer())
  state.timer:start(
    state.options.flush_interval_ms,
    state.options.flush_interval_ms,
    vim.schedule_wrap(function()
      M.flush()
    end)
  )
  state.timer:unref()
end

local function stop_timer()
  if state.timer == nil then
    return
  end

  state.timer:stop()
  state.timer:close()
  state.timer = nil
end

function M.enable()
  if state.enabled then
    return
  end

  state.namespace = vim.on_key(record_key, state.namespace)
  start_timer()
  state.enabled = true
  queue_event({ event = "enabled" })
end

function M.disable()
  if not state.enabled then
    return
  end

  queue_event({ event = "disabled" })
  vim.on_key(nil, state.namespace)
  state.enabled = false
  state.last_key_time = nil
  stop_timer()
  M.flush()
end

function M.toggle()
  if state.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.is_enabled()
  return state.enabled
end

function M.data_dir()
  return state.options.data_dir
end

local function notify_status()
  local status = state.enabled and "enabled" or "disabled"
  vim.notify("Key usage logging is " .. status, vim.log.levels.INFO, { title = "Key usage" })
end

local function run_command(action)
  action = action == "" and "status" or action
  if not allowed_actions[action] then
    vim.notify("Unknown KeyUsage action: " .. action, vim.log.levels.ERROR, { title = "Key usage" })
    return
  end

  if action == "enable" then
    M.enable()
  elseif action == "disable" then
    M.disable()
  elseif action == "toggle" then
    M.toggle()
  elseif action == "flush" then
    M.flush()
  elseif action == "path" then
    vim.notify(state.options.data_dir, vim.log.levels.INFO, { title = "Key usage" })
    return
  end

  notify_status()
end

function M.setup(options)
  if state.setup then
    return
  end

  state.options = vim.tbl_deep_extend("force", defaults, options or {})
  state.session_id = string.format("%d-%d", os.time(), vim.uv.os_getpid())
  state.setup = true

  vim.api.nvim_create_user_command("KeyUsage", function(command)
    run_command(command.args)
  end, {
    complete = function()
      return vim.tbl_keys(allowed_actions)
    end,
    desc = "Control key usage logging",
    nargs = "?",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("key-usage", { clear = true }),
    callback = function()
      if state.enabled then
        queue_event({ event = "session_end" })
      end
      M.flush()
      stop_timer()
    end,
  })

  if state.options.enabled then
    queue_event({
      event = "session_start",
      nvim_version = vim.version(),
    })
    M.enable()
  end
end

return M
