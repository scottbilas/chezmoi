local lib = import 'karabiner.libsonnet';

local passthru = [ "\\.wezterm$", "\\.Terminal$", "^com\\.parallels\\.winapp\\.", "^com\\.microsoft\\.rdc\\." ];

local ifPassthru = lib.ifApp(passthru);
local noPassthru = lib.noApp(passthru);

local varCAPS = 'is_caps_lock_held';
local ifCaps = lib.ifVar(varCAPS);
local noCaps = lib.ifNotVar(varCAPS);
local varCTRL = 'is_left_control_held';
local ifCtrl = lib.ifVar(varCTRL);
local noCtrl = lib.ifNotVar(varCTRL);

{
  machine_specific: { "krbn-859b4276-5fb1-4196-98d4-675ea5affd43": { enable_multitouch_extension: true } },
  profiles: [
    {
      name: "Default profile",
      selected: true,
      virtual_hid_keyboard: { keyboard_type_v2: 'ansi' },

      complex_modifications: {
        rules: [
          lib.rule('Modifier keys - caps to enable vimish, ctrl to cmd except in passthru, and var setting to avoid ordering issues', [
            {
              "from":            { "key_code": "caps_lock", "modifiers": { "optional": ["any"] }},
              "to":              [ lib.set(varCAPS) ],
              "to_after_key_up": [ lib.clear(varCAPS) ],
            },

            # pass through left_control in passthru
            {
              "from":            { "key_code": "left_control", "modifiers": { "optional": ["any"] }},
              "to":              [ lib.set(varCTRL), { "key_code": "left_control", "lazy": true }],
              "to_after_key_up": [ lib.clear(varCTRL) ],
              "conditions":      [ ifPassthru ],
            },

            # eat left_control under other circumstances (but track it) because we'll sometimes convert to option or command
            {
              "from":            { "key_code": "left_control", "modifiers": { "optional": ["any"] }},
              "to":              [ lib.set(varCTRL) ],
              "to_after_key_up": [ lib.clear(varCTRL) ],
            },

            # direct support for global ctrl ops
            {
              "from":       {  "key_code": "tab", "modifiers": { "optional": ["any"] }},
              "to":         [{ "key_code": "tab", "modifiers": ["left_control"] }],
              "conditions": [noPassthru, ifCtrl],
            },
          ]),

          lib.rule('Misc caps-hotkeys', [
            {
              "from":      { "key_code": "q" },
              "to":        [{ "consumer_key_code": "rewind" }],
              "conditions": [ifCaps],
            },
            {
              "from":      { "key_code": "w" },
              "to":        [{ "consumer_key_code": "play_or_pause" }],
              "conditions": [ifCaps],
            },
            {
              "from":      { "key_code": "e" },
              "to":        [{ "consumer_key_code": "fastforward" }],
              "conditions": [ifCaps],
            },
          ]),

          lib.rule('Vim-ish navigation etc. (Windows style)', [
            // arrows
            lib.manip('h',                   ['any'], 'left_arrow',     ['left_option'],  [ifCaps, ifCtrl]),
            lib.manip('h',                   ['any'], 'left_arrow',     null,             [ifCaps]),
            lib.manip('j',                   ['any'], 'down_arrow',     ['left_option'],  [ifCaps, ifCtrl]),
            lib.manip('j',                   ['any'], 'down_arrow',     null,             [ifCaps]),
            lib.manip('k',                   ['any'], 'up_arrow',       ['left_option'],  [ifCaps, ifCtrl]),
            lib.manip('k',                   ['any'], 'up_arrow',       null,             [ifCaps]),
            lib.manip('l',                   ['any'], 'right_arrow',    ['left_option'],  [ifCaps, ifCtrl]),
            lib.manip('l',                   ['any'], 'right_arrow',    null,             [ifCaps]),

            // pgup/down
            lib.manip('i',                   ['any'], 'page_up',        null,             [ifCaps]),
            lib.manip('comma',               ['any'], 'page_down',      null,             [ifCaps]),

            // home/end
            lib.manip('u',                   ['any'], 'up_arrow',       ['left_command'], [ifCaps, ifCtrl]),
            lib.manip('u',                   ['any'], 'home',           null,             [ifCaps, ifPassthru]),
            lib.manip('u',                   ['any'], 'left_arrow',     ['left_command'], [ifCaps]),
            lib.manip('m',                   ['any'], 'down_arrow',     ['left_command'], [ifCaps, ifCtrl]),
            lib.manip('m',                   ['any'], 'end',            null,             [ifCaps, ifPassthru]),
            lib.manip('m',                   ['any'], 'right_arrow',    ['left_command'], [ifCaps]),

            // other
            lib.manip('delete_or_backspace', ['any'], 'delete_forward', null,             [ifCaps]),
            lib.manip('open_bracket',        ['any'], 'escape',         null,             [ifCaps]),
          ]),

          lib.rule('Ctrl to cmd', // must map individual chars because we use ctrl in a complex way in this file
            lib.ctrlToCmd(lib.A_TO_Z, [ifCtrl, noPassthru]),
          ),

          lib.rule('Emulate Windows taskbar selection', [
            {
              "from": { "key_code": "1", "modifiers": { "mandatory": ["option"] }},
              "to":   [{ "shell_command": "open -a 'Microsoft Edge'" }],
            },
            {
              "from": { "key_code": "1", "modifiers": { "mandatory": ["option", "shift"] }},
              "to":   [{ "shell_command": "osascript -e 'tell application \"Microsoft Edge\" to make new window'" }],
            },
            {
              "from": { "key_code": "2", "modifiers": { "mandatory": ["option"] }},
              "to":   [{ "shell_command": "open -a wezterm" }],
            },
            {
              "from": { "key_code": "2", "modifiers": { "mandatory": ["option", "shift"] }},
              "to":   [{ "shell_command": "open -n -a wezterm" }],
            }
          ]),

          lib.rule('MS Edge Fixes', [
            {
              # prevent shift-cmd-h nuking browse history for the tab wtf ms why",
              "from":       { "key_code": "h", "modifiers": { "mandatory": ["command", "shift"] }},
              "to":         [],
              "conditions": [{ "type": "frontmost_application_if", "bundle_identifiers": ["^com\\.microsoft\\.edgemac$"] }],
            },
            {
              # simply cannot lose the alt-d muscle memory (makes a bookmark on mac, don't want it)
              "from":       { "key_code": "d", "modifiers": { "mandatory": ["command"] }},
              "to":         [{ "key_code": "l", "modifiers": ["command"] }],
              "conditions": [{ "type": "frontmost_application_if", "bundle_identifiers": ["^com\\.microsoft\\.edgemac$"] }],
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
