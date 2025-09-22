local lib = import 'karabiner.libsonnet';

local appWinRemote = [
   // apps that think they are windows
  '^com\\.parallels\\.winapp\\.',          // parallels in coherence
  '^com\\.parallels\\.desktop\\.console$', // standalone window
  '^com\\.microsoft\\.rdc\\.',             // official microsoft remote desktop app
];
local ifWinRemote = lib.ifApp(appWinRemote);
local noWinRemote = lib.noApp(appWinRemote);

local appWinOther = [

  // IDEs that have win style mappings
  //'^com\\.microsoft\\.VSCode$',
  '^com\\.jetbrains\\.(rider|pycharm)$',

  // terminals expect win style
  '\\.wezterm$',
  '\\.Terminal$',
] + appWinRemote;

local appWin = appWinRemote + appWinOther;

local ifWinApp = lib.ifApp(appWin);
local ifMacApp = lib.noApp(appWin);

local varCAPS = 'is_caps_lock_held';
local ifCaps = lib.ifVar(varCAPS);
local noCaps = lib.ifNotVar(varCAPS);
local varCTRL = 'is_left_control_held';
local ifCtrl = lib.ifVar(varCTRL);
local noCtrl = lib.ifNotVar(varCTRL);

local simple_caps(key_code, modifiers, to) = {
  from: if std.length(modifiers) > 0
    then { key_code: key_code, modifiers: { mandatory: modifiers } }
    else { key_code: key_code },
  to: [ to ],
  conditions: [ ifCaps ],
};

{
  machine_specific: { 'krbn-859b4276-5fb1-4196-98d4-675ea5affd43': { enable_multitouch_extension: true } },
  profiles: [
    {
      name: 'Default profile',
      selected: true,
      virtual_hid_keyboard: { keyboard_type_v2: 'ansi' },

      complex_modifications: {
        rules: [
          lib.rule('Modifier keys - caps to enable vimish, ctrl to cmd except in passthru, and var setting to avoid ordering issues', [
            {
              from:            { key_code: 'caps_lock', modifiers: { optional: ['any'] }},
              to:              [ lib.set(varCAPS) ],
              to_after_key_up: [ lib.clear(varCAPS) ],
            },

            # pass through left_control
            {
              from:            { key_code: 'left_control', modifiers: { optional: ['any'] }},
              to:              [ lib.set(varCTRL), { key_code: 'left_control', lazy: true }],
              to_after_key_up: [ lib.clear(varCTRL) ],
              conditions:      [ ifWinApp ],
            },

            # eat left_control under other circumstances (but track it) because we'll sometimes convert to option or command
            {
              from:            { key_code: 'left_control', modifiers: { optional: ['any'] }},
              to:              [ lib.set(varCTRL) ],
              to_after_key_up: [ lib.clear(varCTRL) ],
            },

            # directly support other global ctrl-related hotkeys
            {
              from:            {  key_code: 'tab', modifiers: { optional: ['any'] }},
              to:              [{ key_code: 'tab', modifiers: ['left_control'] }],
              conditions:      [ifCtrl],
            },
          ]),

          lib.rule('Misc caps-hotkeys because bad aim on fn keys in the dark', [
            // media
            simple_caps('q', [], { consumer_key_code: 'rewind' }),
            simple_caps('w', [], { consumer_key_code: 'play_or_pause' }),
            simple_caps('e', [], { consumer_key_code: 'fastforward' }),

            // screen brightness
            simple_caps('hyphen',     [], { key_code: 'display_brightness_decrement' }),
            simple_caps('equal_sign', [], { key_code: 'display_brightness_increment' }),

            // keyboard brightness
            simple_caps('hyphen',     ['shift'], { key_code: 'illumination_decrement' }),
            simple_caps('equal_sign', ['shift'], { key_code: 'illumination_increment' }),
          ]),

          lib.rule('Vim-ish navigation etc. (Mac-specific forwarding)', [
            // ctrl-arrows (ctrl->option)
            lib.manip('h',                   ['any'], 'left_arrow',     ['left_option'],   [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('j',                   ['any'], 'down_arrow',     ['left_option'],   [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('k',                   ['any'], 'up_arrow',       ['left_option'],   [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('l',                   ['any'], 'right_arrow',    ['left_option'],   [ifMacApp, ifCaps, ifCtrl]),

            // home/end
            lib.manip('u',                   ['any'], 'up_arrow',       ['left_command'],  [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('u',                   ['any'], 'left_arrow',     ['left_command'],  [ifMacApp, ifCaps]),
            lib.manip('m',                   ['any'], 'down_arrow',     ['left_command'],  [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('m',                   ['any'], 'right_arrow',    ['left_command'],  [ifMacApp, ifCaps]),
          ]),

          lib.rule('Vim-ish navigation etc.', [
            // arrows
            lib.manip('h',                   ['any'], 'left_arrow',     ['left_control'],  [ifCaps, ifCtrl]),
            lib.manip('h',                   ['any'], 'left_arrow',     null,              [ifCaps]),
            lib.manip('j',                   ['any'], 'down_arrow',     ['left_control'],  [ifCaps, ifCtrl]),
            lib.manip('j',                   ['any'], 'down_arrow',     null,              [ifCaps]),
            lib.manip('k',                   ['any'], 'up_arrow',       ['left_control'],  [ifCaps, ifCtrl]),
            lib.manip('k',                   ['any'], 'up_arrow',       null,              [ifCaps]),
            lib.manip('l',                   ['any'], 'right_arrow',    ['left_control'],  [ifCaps, ifCtrl]),
            lib.manip('l',                   ['any'], 'right_arrow',    null,              [ifCaps]),

            // pgup/down
            lib.manip('i',                   ['any'], 'page_up',        null,              [ifCaps]),
            lib.manip('comma',               ['any'], 'page_down',      null,              [ifCaps]),

            // home/end
            lib.manip('u',                   ['any'], 'home',           ['left_control'],  [ifCaps, ifCtrl]),
            lib.manip('u',                   ['any'], 'home',           null,              [ifCaps]),
            lib.manip('m',                   ['any'], 'end',            ['left_control'],  [ifCaps, ifCtrl]),
            lib.manip('m',                   ['any'], 'end',            null,              [ifCaps]),

            // other
            lib.manip('delete_or_backspace', ['any'], 'delete_forward', null,              [ifCaps]),
            lib.manip('open_bracket',        ['any'], 'escape',         null,              [ifCaps]),
          ]),

          lib.rule('Ctrl to cmd', // must map individual chars because we use ctrl in a complex way in this file
            lib.ctrlToCmd(lib.A_TO_Z + lib.DIGITS + ['hyphen', 'equal_sign'], [ifMacApp, ifCtrl]),
          ),

          lib.rule('Emulate Windows global hotkeys', [
            {
              from:       { key_code: '1', modifiers: { mandatory: ['option'] }},
              to:         [{ shell_command: "open -a 'Microsoft Edge'" }],
            },
            {
              from:       { key_code: '1', modifiers: { mandatory: ['option', 'shift'] }},
              to:         [{ shell_command: "osascript -e 'tell application \"Microsoft Edge\" to make new window'" }],
            },
            {
              from:       { key_code: '2', modifiers: { mandatory: ['option'] }},
              to:         [{ shell_command: "open -a wezterm" }],
              conditions: [noWinRemote], // on windows want win-2 to go to windows term
            },
            {
              from:       { key_code: '2', modifiers: { mandatory: ['option', 'shift'] }},
              to:         [{ shell_command: "open -n -a wezterm" }],
              conditions: [noWinRemote],
            },
            {
              from: { key_code: 'e', modifiers: { mandatory: ['option'] }},
              to:   [{ shell_command: "open -a Finder" }],
              conditions: [noWinRemote],
            }
          ]),

          lib.rule('MS Edge Fixes', [
            {
              # prevent shift-cmd-h nuking browse history for the tab wtf ms why',
              from:       { key_code: 'h', modifiers: { mandatory: ['command', 'shift'] }},
              to:         [],
              conditions: [{ type: 'frontmost_application_if', bundle_identifiers: ['^com\\.microsoft\\.edgemac$'] }],
            },
            {
              # simply cannot lose the alt-d muscle memory (makes a bookmark on mac, don't want it)
              from:       { key_code: 'd', modifiers: { mandatory: ['command'] }},
              to:         [{ key_code: 'l', modifiers: ['command'] }],
              conditions: [{ type: 'frontmost_application_if', bundle_identifiers: ['^com\\.microsoft\\.edgemac$'] }],
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
            { from: 'keyboard_fn', from_type: 'apple_vendor_top_case_key_code', to: 'left_control' },
            { from: 'left_control', to: 'keyboard_fn', to_type: 'apple_vendor_top_case_key_code' },
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
