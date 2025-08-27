local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

config.initial_cols = 200
config.initial_rows = 50
config.default_prog = { 'zsh', '-l', '-c', 'exec tmux' }

-- i always want confirmation!
config.skip_close_confirmation_for_processes_named = {}

function theme(appearance)
--  if appearance:find 'Dark' then
    return 'Monokai (terminal.sexy)'
--  else
--    return 'Monokai (light) (terminal.sexy)'
--  end
end

config.color_scheme = theme(wezterm.gui.get_appearance())
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")

return config
