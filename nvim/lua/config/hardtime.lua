local M = {}

local state = {
  installed = false,
  mappings = {},
}

local function normalize_key(key)
  return vim.api.nvim_replace_termcodes(key, true, true, true)
end

local function configured_keys()
  local config = require("hardtime.config").config
  local keys = {}
  local groups = {
    config.resetting_keys,
    config.restricted_keys,
    config.disabled_keys,
  }

  for _, group in ipairs(groups) do
    for key, modes in pairs(group) do
      if type(modes) == "string" then
        keys[modes] = keys[modes] or {}
        keys[modes][normalize_key(key)] = true
      elseif type(modes) == "table" then
        for _, mode in ipairs(modes) do
          keys[mode] = keys[mode] or {}
          keys[mode][normalize_key(key)] = true
        end
      end
    end
  end

  return keys
end

local function snapshot_mappings()
  local mappings = {}

  for mode, keys in pairs(configured_keys()) do
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
      if keys[normalize_key(mapping.lhs)] then
        table.insert(mappings, {
          mapping = mapping,
          mode = mode,
        })
      end
    end
  end

  return mappings
end

local function restore_mapping(mode, mapping)
  local rhs = mapping.callback or mapping.rhs
  vim.keymap.set(mode, mapping.lhs, rhs, {
    desc = mapping.desc,
    expr = mapping.expr == 1,
    nowait = mapping.nowait == 1,
    remap = mapping.noremap == 0,
    replace_keycodes = mapping.replace_keycodes == 1,
    script = mapping.script == 1,
    silent = mapping.silent == 1,
  })
end

local function restore_mappings()
  for _, item in ipairs(state.mappings) do
    restore_mapping(item.mode, item.mapping)
  end
  state.mappings = {}
end

function M.setup(options)
  local hardtime = require("hardtime")

  if not state.installed then
    local enable = hardtime.enable
    local disable = hardtime.disable

    hardtime.enable = function()
      if hardtime.is_plugin_enabled then
        return
      end

      state.mappings = snapshot_mappings()
      enable()
    end

    hardtime.disable = function()
      if not hardtime.is_plugin_enabled then
        return
      end

      disable()
      restore_mappings()
    end

    state.installed = true
  end

  hardtime.setup(options)
end

return M
