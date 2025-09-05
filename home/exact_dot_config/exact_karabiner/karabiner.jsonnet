local lib = import 'karabiner.libsonnet';

local terminals = [ "\\.wezterm$", "\\.Terminal$" ];

local ifTerminal = lib.ifApp(terminals);
local noTerminal = lib.noApp(terminals);

local CAPS = 'is_caps_lock_held';
local ifCaps = lib.ifVar(CAPS);
local noCaps = lib.ifNotVar(CAPS);
local CTRL = 'is_left_control_held';
local ifCtrl = lib.ifVar(CTRL);
local noCtrl = lib.ifNotVar(CTRL);

{
  machine_specific: { "krbn-859b4276-5fb1-4196-98d4-675ea5affd43": { enable_multitouch_extension: true } },
  profiles: [
    {
      name: "Default profile",
      selected: true,
      virtual_hid_keyboard: { keyboard_type_v2: 'ansi' },

      complex_modifications: {
        rules: [
          lib.rule('Modifier keys - caps to enable vimish, ctrl to cmd except in terminals, and var setting to avoid ordering issues', [
            {
              "from":            { "key_code": "caps_lock", "modifiers": { "optional": ["any"] }},
              "to":              [ lib.set(CAPS) ],
              "to_after_key_up": [ lib.clear(CAPS) ],
              "type":            "basic"
            },

            # pass through left_control in terminals
            {
              "from":            { "key_code": "left_control", "modifiers": { "optional": ["any"] }},
              "to":              [ lib.set(CTRL), { "key_code": "left_control", "lazy": true }],
              "to_after_key_up": [ lib.clear(CTRL) ],
              "conditions":      [ ifTerminal ],
              "type":            "basic"
            },

            # eat left_control under other circumstances (but track it) because we'll sometimes convert to option or command
            {
              "from":            { "key_code": "left_control", "modifiers": { "optional": ["any"] }},
              "to":              [ lib.set(CTRL) ],
              "to_after_key_up": [ lib.clear(CTRL) ],
              "type":            "basic"
            },

            # direct support for global ctrl ops
            {
              "from":       {  "key_code": "tab", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "tab", "modifiers": ["left_control"] }],
              "conditions": [noTerminal, ifCtrl],
              "type":       "basic"
            },
          ]),

          lib.rule('Vim-ish navigation etc. (Windows style)', [
            {
              "from":       { "key_code": "h", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "left_arrow", "modifiers": ["left_option"] }],
              "conditions": [ifCaps, ifCtrl],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "h", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "left_arrow" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },

            {
              "from":       { "key_code": "j", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "down_arrow", "modifiers": ["left_option"] }],
              "conditions": [ifCaps, ifCtrl],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "j", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "down_arrow" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },

            {
              "from":       { "key_code": "k", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "up_arrow", "modifiers": ["left_option"] }],
              "conditions": [ifCaps, ifCtrl],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "k", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "up_arrow" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },

            {
              "from":       { "key_code": "l", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "right_arrow", "modifiers": ["left_option"] }],
              "conditions": [ifCaps, ifCtrl],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "l", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "right_arrow" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },

            {
              "from":       { "key_code": "i", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "page_up" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "comma", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "page_down" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },


            {
              "from":       { "key_code": "u", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "up_arrow", "modifiers": ["left_command"] }],
              "conditions": [ifCaps, ifCtrl],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "u", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "home" }],
              "conditions": [ifCaps, ifTerminal],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "u", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "left_arrow", "modifiers": ["left_command"] }],
              "conditions": [ifCaps],
              "type":       "basic"
            },

            {
              "from":       { "key_code": "m", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "down_arrow", "modifiers": ["left_command"] }],
              "conditions": [ifCaps, ifCtrl],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "m", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "end" }],
              "conditions": [ifCaps, ifTerminal],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "m", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "right_arrow", "modifiers": ["left_command"] }],
              "conditions": [ifCaps],
              "type":       "basic"
            },

            {
              "from":       { "key_code": "delete_or_backspace", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "delete_forward" }],
              "conditions": [ifCaps],
              "type":       "basic"
            },
            {
              "from":       { "key_code": "open_bracket", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "escape" }],
              "conditions": [ifCaps],
              "type":       "basic"
            }
          ]),

          lib.rule('Emulate Windows taskbar selection', [
            {
              "from": { "key_code": "1", "modifiers": { "mandatory": ["option"] }},
              "to":   [{ "shell_command": "open -a 'Microsoft Edge'" }],
              "type": "basic"
            },
            {
              "from": { "key_code": "1", "modifiers": { "mandatory": ["option", "shift"] }},
              "to":   [{ "shell_command": "open -n -a 'Microsoft Edge'" }],
              "type": "basic"
            },
            {
              "from": { "key_code": "2", "modifiers": { "mandatory": ["option"] }},
              "to":   [{ "shell_command": "open -a wezterm" }],
              "type": "basic"
            },
            {
              "from": { "key_code": "2", "modifiers": { "mandatory": ["option", "shift"] }},
              "to":   [{ "shell_command": "open -n -a wezterm" }],
              "type": "basic"
            }
          ]),

          lib.rule('MS Edge Fixes', [
            {
              # prevent shift-cmd-h nuking browse history for the tab wtf ms why",
              "from":       { "key_code": "h", "modifiers": { "mandatory": ["command", "shift"] }},
              "to":         [],
              "conditions": [{ "type": "frontmost_application_if", "bundle_identifiers": ["^com\\.microsoft\\.edgemac$"] }],
              "type":       "basic"
            },
            {
              # simply cannot lose the alt-d muscle memory (makes a bookmark on mac, don't want it)
              "from":       { "key_code": "d", "modifiers": { "mandatory": ["command"] }},
              "to":         [{ "key_code": "l", "modifiers": ["command"] }],
              "conditions": [{ "type": "frontmost_application_if", "bundle_identifiers": ["^com\\.microsoft\\.edgemac$"] }],
              "type":       "basic"
            }
          ]),
        ]
      },
      
      local map(entries) = std.map(
          function(obj) {
            from: { [std.get(obj, 'from_type', 'key_code')]: obj.from },
            to:   [{ [std.get(obj, 'to_type', 'key_code')]: obj.to }],
          },
          entries),
      
      devices: [{
          identifiers: { is_keyboard: true },
          simple_modifications: map([
            { from: "keyboard_fn", from_type: "apple_vendor_top_case_key_code", to: "left_control" },
            { from: "left_control", to: "keyboard_fn", to_type: "apple_vendor_top_case_key_code" },
          ])
        },
        {
          identifiers: { is_keyboard: true, product_id: 1957, vendor_id: 1118 },
          ignore_vendor_events: true,
          simple_modifications: map([
            { from: 'left_command',  to: 'left_option' },
            { from: 'left_option',   to: 'left_command' },
            { from: 'right_command', to: 'right_option' },
            { from: 'right_option',  to: 'right_command'},
          ])
        },
        { identifiers: { is_keyboard: true, product_id: 50475, vendor_id: 1133 }, ignore: true },
        { identifiers: { is_pointing_device: true, product_id: 50475, vendor_id: 1133 }, ignore: false, ignore_vendor_events: true, mouse_flip_vertical_wheel: true }
      ],
    }
  ]
}
