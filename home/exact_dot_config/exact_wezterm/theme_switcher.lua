-- thanks and credit for original version by u/andrewberty: https://www.reddit.com/r/wezterm/comments/1bbq6ro/i_implemented_a_theme_switcher/

local wezterm = require('wezterm')
local act = wezterm.action
local M = {}

-- assume ~/.config/wezterm/wezterm.lua next to this file
local CONFIG_PATH = (os.getenv('HOME') or os.getenv('USERPROFILE') or '.') .. '/.config/wezterm/wezterm.lua'

-- look for "local NAME = 'value'" and replace the value
local function set_var(text, var, value)
  local val = value:gsub('\\', '\\\\'):gsub("'", [[\']])
  local pat = '(%f[%w_])local%s+' .. var .. "%s*=%s*'[^']*'"
  local rep = "local " .. var .. " = '" .. val .. "'"
  local out, n = text:gsub(pat, rep, 1)
  if n == 0 then out = out .. '\n' .. rep .. '\n' end
  return out
end

M.theme_switcher = function(window, pane)
  local choices = {}
  for name in pairs(wezterm.get_builtin_color_schemes()) do
    table.insert(choices, { label = tostring(name) })
  end
  table.sort(choices, function(a, b) return a.label < b.label end)

  window:perform_action(act.InputSelector({
    title = '🎨 Pick a Theme!',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(win, p, _, label)
      if not label or label == '' then return end

      -- instant apply
      local o = win:get_config_overrides() or {}
      o.color_scheme = label
      win:set_config_overrides(o)

      -- pick which var to rewrite
      local appearance = (wezterm.gui and wezterm.gui.get_appearance()) or 'Dark'
      local var = appearance:find('Dark') and 'DARK_THEME' or 'LIGHT_THEME'

      -- read -> patch -> write
      local f = io.open(CONFIG_PATH, 'rb')
      if f then
        local txt = f:read('*a'); f:close()
        local out = set_var(txt, var, label)
        f = io.open(CONFIG_PATH, 'wb')
        if f then
          f:write(out); f:close()
          win:perform_action(act.ReloadConfiguration, p)
          o.color_scheme = nil
          win:set_config_overrides(o)
        end
      end
    end),
  }), pane)
end

return M
