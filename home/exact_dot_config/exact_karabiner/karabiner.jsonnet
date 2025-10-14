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
  //'^com\\.microsoft\\.VSCode$',  // not ready for this until i redo the vscode keymap
  '^com\\.jetbrains\\.(rider|pycharm)$',

  // terminals expect win style
  '\\.wezterm$',
  '\\.Terminal$',
] + appWinRemote;

local appWin = appWinRemote + appWinOther;

local ifWinApp = lib.ifApp(appWin);
local ifMacApp = lib.noApp(appWin);

local varHeldCaps = 'scoob:held_caps_lock';
local ifCaps = lib.ifVar(varHeldCaps);
local noCaps = lib.ifNotVar(varHeldCaps);
local varHeldCtrl = 'scoob:held_left_control';
local ifCtrl = lib.ifVar(varHeldCtrl);
local noCtrl = lib.ifNotVar(varHeldCtrl);

local ifKeychron = lib.ifDevice(13364);
local ifVscode = lib.ifApp(['^com\\.microsoft\\.VSCode$']); 
local noVscode = lib.noApp(['^com\\.microsoft\\.VSCode$']); 

local simple_caps(key_code, modifiers, to) = {
  from: if std.length(modifiers) > 0
    then { key_code: key_code, modifiers: { mandatory: modifiers } }
    else { key_code: key_code },
  to: [ to ],
  conditions: [ ifCaps ],
};

# general notes:
#   * left ctrl/cmd is the main remapped set
#   * right cmd is used for altgr dead key intl stuff

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
              to:              [ lib.set(varHeldCaps) ],
              to_after_key_up: [ lib.clear(varHeldCaps) ],
            },

            # pass through left_control
            {
              from:            { key_code: 'left_control', modifiers: { optional: ['any'] }},
              to:              [ lib.set(varHeldCtrl), { key_code: 'left_control', lazy: true }],
              to_after_key_up: [ lib.clear(varHeldCtrl) ],
              conditions:      [ ifWinApp ],
            },

            # eat left_control under other circumstances (but track it) because we'll sometimes convert to option or command
            {
              from:            { key_code: 'left_control', modifiers: { optional: ['any'] }},
              to:              [ lib.set(varHeldCtrl) ],
              to_after_key_up: [ lib.clear(varHeldCtrl) ],
            },

            # directly support other global ctrl-related hotkeys
            {
              from:            {  key_code: 'tab', modifiers: { optional: ['any'] }},
              to:              [{ key_code: 'tab', modifiers: ['left_control'] }],
              conditions:      [ifCtrl],
            },
          ]),

          // ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
          // │Esc│F1 │F2 │F3 │F4 │F5 │F6 │F7 │F8 │F9 │F10│F11│F12│PrScPa │
          // ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
          // │  `  │F1 │F2 │F3 │F4 │F5 │F6 │F7 │F8 │F9 │F10│F11│F12│ Del │
          // ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬────┤
          // │ Tab  │rew│ply│fwd│br+│br-│ y │ ⇐ │ ⇑ │ o │ p │esc│ ] │ \  │
          // ├──────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴────┤
          // │ Caps  │ a │ s │ d │ f │ g │ ← │ ↓ │ ↑ │ → │ ; │ ' │ Enter │
          // ├───────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴───────┤
          // │ Shift  │ z │ x │ c │ v │ b │ n │ ⇒ │ ⇓ │ . │ / │  Shift   │
          // ├─────┬──┴┬──┴───┼───┴───┴───┴───┴───┴───┴───┴──┬┴──┬───┬───┤
          // │Ctrl │Win│ Alt  │           Space              │Alt│Win│Ctl│
          // └─────┴───┴──────┴──────────────────────────────┴───┴───┴───┘

          lib.rule('Misc caps-hotkeys because bad aim on fn keys in the dark', [
            // media
            simple_caps('q', [], { consumer_key_code: 'rewind' }),
            simple_caps('w', [], { consumer_key_code: 'play_or_pause' }),
            simple_caps('e', [], { consumer_key_code: 'fastforward' }),

            // screen brightness
            simple_caps('r', [], { key_code: 'display_brightness_decrement' }),
            simple_caps('t', [], { key_code: 'display_brightness_increment' }),

            // keyboard brightness
            simple_caps('r', ['shift'], { key_code: 'illumination_decrement' }),
            simple_caps('t', ['shift'], { key_code: 'illumination_increment' }),
          ]),

          lib.rule('Vim-ish navigation etc. (Mac-specific forwarding)', [
            // ctrl-arrows (ctrl->option)
            lib.manip('h', 'any', 'left_arrow',  ['left_option'],  [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('j', 'any', 'down_arrow',  ['left_option'],  [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('k', 'any', 'up_arrow',    ['left_option'],  [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('l', 'any', 'right_arrow', ['left_option'],  [ifMacApp, ifCaps, ifCtrl]),

            // home/end
            lib.manip('u', 'any', 'up_arrow',    ['left_command'], [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('u', 'any', 'left_arrow',  ['left_command'], [ifMacApp, ifCaps]),
            lib.manip('m', 'any', 'down_arrow',  ['left_command'], [ifMacApp, ifCaps, ifCtrl]),
            lib.manip('m', 'any', 'right_arrow', ['left_command'], [ifMacApp, ifCaps]),
          ]),

          lib.rule('Vim-ish navigation etc.', [
            // arrows
            lib.manip('h', 'any', 'left_arrow',  ['left_control'], [ifCaps, ifCtrl]),
            lib.manip('h', 'any', 'left_arrow',  null,             [ifCaps]),
            lib.manip('j', 'any', 'down_arrow',  ['left_control'], [ifCaps, ifCtrl]),
            lib.manip('j', 'any', 'down_arrow',  null,             [ifCaps]),
            lib.manip('k', 'any', 'up_arrow',    ['left_control'], [ifCaps, ifCtrl]),
            lib.manip('k', 'any', 'up_arrow',    null,             [ifCaps]),
            lib.manip('l', 'any', 'right_arrow', ['left_control'], [ifCaps, ifCtrl]),
            lib.manip('l', 'any', 'right_arrow', null,             [ifCaps]),

            // pgup/down
            lib.manip('i',     'any', 'page_up',   null, [ifCaps]),
            lib.manip('comma', 'any', 'page_down', null, [ifCaps]),

            // home/end
            lib.manip('u', 'any', 'home', ['left_control'], [ifCaps, ifCtrl]),
            lib.manip('u', 'any', 'home', null,             [ifCaps]),
            lib.manip('m', 'any', 'end',  ['left_control'], [ifCaps, ifCtrl]),
            lib.manip('m', 'any', 'end',  null,             [ifCaps]),

            // other
            lib.manip('escape',              'any', 'grave_accent_and_tilde', null, [ifCaps]), // for my keychron
            lib.manip('delete_or_backspace', 'any', 'delete_forward',         null, [ifCaps]),
            lib.manip('open_bracket',        'any', 'escape',                 null, [ifCaps]),
          ]),

          // my current vscode keymap has some things that shouldn't be cmd-remapped
          lib.rule('Ctrl to cmd - / = (vscode)', std.flattenArrays(std.map(function(k) [
            lib.manip(k, { mandatory: [       ] }, k, ['left_control'         ], [ifCtrl]),
            lib.manip(k, { mandatory: ['shift'] }, k, ['left_control', 'shift'], [ifCtrl]),
          ], ['hyphen', 'equal_sign', 'g']))),

          // must map individual chars because we use ctrl in a complex way in this file
          lib.rule('Ctrl to cmd', std.flattenArrays(std.map(function(k) [
            lib.manip(k, { mandatory: [                       ] }, k, [                'left_command'         ], [ifMacApp, ifCtrl]),
            lib.manip(k, { mandatory: [                'shift'] }, k, [                'left_command', 'shift'], [ifMacApp, ifCtrl]),
            lib.manip(k, { mandatory: ['left_command'         ] }, k, ['left_control', 'left_command'         ], [ifMacApp, ifCtrl]),
            lib.manip(k, { mandatory: ['left_command', 'shift'] }, k, ['left_control', 'left_command', 'shift'], [ifMacApp, ifCtrl]),
          ], lib.A_TO_Z + lib.DIGITS + ['hyphen', 'equal_sign']))),

          lib.rule('Windows-style intl keeb (right-cmd as altgr)', std.flattenArrays([

            lib.altgrAcute(['a', 'e', 'i', 'o', 'u']), // á é í ó ú
            lib.altgrDead('quote', 'scoob:dead_acute_active', keyMap=[ // dead key: '
              { from: 'a', to: 'a', macDead: 'e' },  // á/Á
              { from: 'e', to: 'e', macDead: 'e' },  // é/É
              { from: 'i', to: 'i', macDead: 'e' },  // í/Í
              { from: 'o', to: 'o', macDead: 'e' },  // ó/Ó
              { from: 'u', to: 'u', macDead: 'e' },  // ú/Ú
            ]),

            lib.altgrDead('grave_accent_and_tilde', 'scoob:dead_backtick_active', [ // dead key: `
              { from: 'a', to: 'a', macDead: 'grave_accent_and_tilde' },  // à
              { from: 'e', to: 'e', macDead: 'grave_accent_and_tilde' },  // è
              { from: 'i', to: 'i', macDead: 'grave_accent_and_tilde' },  // ì
              { from: 'o', to: 'o', macDead: 'grave_accent_and_tilde' },  // ò
              { from: 'u', to: 'u', macDead: 'grave_accent_and_tilde' },  // ù
            ]),

            lib.altgrDirect([
              { from: 'l', to: 'o' }, // ø/Ø
              { from: 'c', to: 'c' }, // ç/Ç
            ]),

            lib.altgrDead('grave_accent_and_tilde', 'scoob:dead_tilde_active', shift=true, keyMap=[ // dead key: ~
              { from: 'n', to: 'n', macDead: 'n' },   // ñ/Ñ
              { from: 'a', to: 'a', macDead: 'n' },   // ã/Ã
              { from: 'o', to: 'o', macDead: 'n' },   // õ/Õ
            ]),
          ])),

          lib.rule('Emulate Windows global hotkeys', [
            {
              from:       { key_code: '0', modifiers: { mandatory: ['left_option'] }},
              to:         [{ shell_command: "open -a ChatGPT" }],
            },
            {
              from:       { key_code: '1', modifiers: { mandatory: ['left_option'] }},
              to:         [{ shell_command: "open -a 'Microsoft Edge'" }],
            },
            {
              from:       { key_code: '1', modifiers: { mandatory: ['left_option', 'shift'] }},
              to:         [{ shell_command: "osascript -e 'tell application \"Microsoft Edge\" to make new window'" }],
            },
            {
              from:       { key_code: '2', modifiers: { mandatory: ['left_option'] }},
              to:         [{ shell_command: "open -a wezterm" }],
              conditions: [noWinRemote], // on windows want win-2 to go to windows term
            },
            {
              from:       { key_code: '2', modifiers: { mandatory: ['left_option', 'shift'] }},
              to:         [{ shell_command: "open -n -a wezterm" }],
              conditions: [noWinRemote],
            },

            {
              from:       { key_code: 'escape', modifiers: { mandatory: ['left_control', 'shift'] }},
              to:         [{ shell_command: "open -a 'Activity Monitor'" }],
            },
            {
              from:       { key_code: 'e', modifiers: { mandatory: ['left_option'] }},
              to:         [{ shell_command: "open -a Finder" }],
              conditions: [noWinRemote],
            }
          ]),

          lib.rule('MS Edge Fixes', [
            {
              # prevent shift-cmd-h nuking browse history for the tab wtf ms why',
              from:       { key_code: 'h', modifiers: { mandatory: ['left_command', 'shift'] }},
              to:         [],
              conditions: [{ type: 'frontmost_application_if', bundle_identifiers: ['^com\\.microsoft\\.edgemac$'] }],
            },
            {
              # simply cannot lose the alt-d muscle memory (makes a bookmark on mac, don't want it)
              from:       { key_code: 'd', modifiers: { mandatory: ['left_command'] }},
              to:         [{ key_code: 'l', modifiers: ['left_command'] }],
              conditions: [{ type: 'frontmost_application_if', bundle_identifiers: ['^com\\.microsoft\\.edgemac$'] }],
            }
          ]),

          lib.rule('Keychron K11', [
            {
              from:       { key_code: 'escape', modifiers: { mandatory: ['left_command'] }},
              to:         [{ key_code: 'grave_accent_and_tilde', modifiers: ['left_command'] }],
              conditions: [ ifKeychron ],
            },
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
