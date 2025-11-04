local wezterm = require 'wezterm'
local theme_switcher = require 'theme_switcher'

local config = wezterm.config_builder()
local act = wezterm.action

config.initial_cols = 200
config.initial_rows = 50

if wezterm.target_triple:find("-windows-") then
  config.default_prog = { 'wsl', 'tmux' } -- does the same as below..wsl runs zsh which runs tmux
else
  config.default_prog = { 'zsh', '-l', '-c', 'exec tmux' }
end

config.skip_close_confirmation_for_processes_named = {}  -- i always want confirmation!

local DARK_THEME  = 'Monokai (terminal.sexy)'
local LIGHT_THEME = 'Alabaster'

function theme(appearance)
  return appearance:find 'Dark' and DARK_THEME or LIGHT_THEME
end

config.color_scheme = theme(wezterm.gui.get_appearance())
config.font = wezterm.font('JetBrainsMono Nerd Font Mono')

-- hook the picker
wezterm.on('pick-theme', theme_switcher.theme_switcher)

-- command palette is ctrl-shift-p
wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Pick Theme',
      icon = 'md_color_lens',
      action = act.EmitEvent('pick-theme'),
    },
  }
end)

return config
