// TROUBLESHOOTING: If shell_command rules stop working, check the log at
// ~/.local/share/karabiner/log/console_user_server.log for "invalid shared secret" errors.
// Fix by restarting the console user server:
//
//   launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server
//
// If that doesn't work, do a full restart via menu bar, or:
//
//   sudo launchctl bootout system /Library/LaunchDaemons/org.pqrs.karabiner.karabiner_grabber.plist
//   sudo launchctl bootstrap system /Library/LaunchDaemons/org.pqrs.karabiner.karabiner_grabber.plist

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
  '^com\\.microsoft\\.VSCode$',
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

local keychronVendorId = 13364;
local k11MaxBTProductId = 2739;
local k11MaxGProductId = 53296;
local ifK11MaxBT = lib.ifDevice(keychronVendorId, k11MaxBTProductId);
local ifK11MaxG = lib.ifDevice(keychronVendorId, k11MaxGProductId);
local ifK11Max = [ifK11MaxBT, ifK11MaxG];

local ifG602 = lib.ifDevice(1133, 50487);
local ifVscode = lib.ifApp(['^com\\.microsoft\\.VSCode$']); 
local noVscode = lib.noApp(['^com\\.microsoft\\.VSCode$']); 

local simple_caps(key_code, modifiers, to) = {
  from: if std.length(modifiers) > 0
    then { key_code: key_code, modifiers: { mandatory: modifiers } }
    else { key_code: key_code },
  to: [ to ],
  conditions: [ ifCaps ],
};

# use this to keep the ctrl-hotkey without converting to cmd- or eating it
local ctrl_passthrough(key_code) = {
  from: { key_code: key_code, modifiers: { optional: ['any'] }},
  to:   [{ key_code: key_code, modifiers: ['left_control'] }],
  conditions: [ifCtrl],
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

            # don't mess with these ctrl-hotkeys
            ctrl_passthrough('tab'),
            ctrl_passthrough('spacebar'),
            ctrl_passthrough('fn')
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
            lib.manip('escape',              'any', 'grave_accent_and_tilde', null, [ifCaps]), // for my keychron without an esc
            lib.manip('quote',               'any', 'grave_accent_and_tilde', null, [ifCaps]), // sometimes easier
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

          lib.rule('Caps -> function keys', [
            lib.manip('1',          'any', 'f1',  null, [ ifCaps ]),
            lib.manip('2',          'any', 'f2',  null, [ ifCaps ]),
            lib.manip('3',          'any', 'f3',  null, [ ifCaps ]),
            lib.manip('4',          'any', 'f4',  null, [ ifCaps ]),
            lib.manip('5',          'any', 'f5',  null, [ ifCaps ]),
            lib.manip('6',          'any', 'f6',  null, [ ifCaps ]),
            lib.manip('7',          'any', 'f7',  null, [ ifCaps ]),
            lib.manip('8',          'any', 'f8',  null, [ ifCaps ]),
            lib.manip('9',          'any', 'f9',  null, [ ifCaps ]),
            lib.manip('0',          'any', 'f10', null, [ ifCaps ]),
            lib.manip('hyphen',     'any', 'f11', null, [ ifCaps ]),
            lib.manip('equal_sign', 'any', 'f12', null, [ ifCaps ]),
          ]),

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

            lib.altgrDead('6', 'scoob:dead_circumflex_active', shift=true, keyMap=[ // dead key: ^
              { from: 'a', to: 'a', macDead: 'i' },  // â/Â
              { from: 'e', to: 'e', macDead: 'i' },  // ê/Ê
              { from: 'i', to: 'i', macDead: 'i' },  // î/Î
              { from: 'o', to: 'o', macDead: 'i' },  // ô/Ô
              { from: 'u', to: 'u', macDead: 'i' },  // û/Û
            ]),

            lib.altgrDead('quote', 'scoob:dead_umlaut_active', shift=true, keyMap=[ // dead key: "
              { from: 'a', to: 'a', macDead: 'u' },  // ä/Ä
              { from: 'e', to: 'e', macDead: 'u' },  // ë/Ë
              { from: 'i', to: 'i', macDead: 'u' },  // ï/Ï
              { from: 'o', to: 'o', macDead: 'u' },  // ö/Ö
              { from: 'u', to: 'u', macDead: 'u' },  // ü/Ü
            ]),

            lib.altgrDead('semicolon', 'scoob:dead_colon_umlaut_active', shift=true, keyMap=[ // dead key: :
              { from: 'a', to: 'a', macDead: 'u' },  // ä/Ä
              { from: 'e', to: 'e', macDead: 'u' },  // ë/Ë
              { from: 'i', to: 'i', macDead: 'u' },  // ï/Ï
              { from: 'o', to: 'o', macDead: 'u' },  // ö/Ö
              { from: 'u', to: 'u', macDead: 'u' },  // ü/Ü
              { from: 'y', to: 'y', macDead: 'u' },  // ÿ/Ÿ
            ]),

            lib.altgrDead('comma', 'scoob:dead_cedilla_active', [ // dead key: ,
              { from: 'c', to: 'c' }, // ç/Ç
            ]),

            lib.altgrDirect([
              { from: 'l', to: 'o'     }, // ø/Ø
              { from: 'c', to: 'c'     }, // ç/Ç
              { from: 'z', to: 'quote' }, // æ/Æ
              { from: 'w', to: 'a'     }, // å/Å
//              { from: '5', to: '2', to_modifiers: ['right_shift'] }, // €
            ]),

            lib.altgrDead('grave_accent_and_tilde', 'scoob:dead_tilde_active', shift=true, keyMap=[ // dead key: ~
              { from: 'n', to: 'n', macDead: 'n' },   // ñ/Ñ
              { from: 'a', to: 'a', macDead: 'n' },   // ã/Ã
              { from: 'o', to: 'o', macDead: 'n' },   // õ/Õ
            ]),
          ])),

          lib.rule('Emulate Windows global hotkeys', [
            // task bar stuff
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

            // misc windows global hotkeys

            { // taskman
              from:       { key_code: 'escape', modifiers: { mandatory: ['left_control', 'shift'] }},
              to:         [{ shell_command: "open -a 'Activity Monitor'" }],
            },
            { // "explorer"
              from:       { key_code: 'e', modifiers: { mandatory: ['left_option'] }},
              to:         [{ shell_command: "open -a Finder" }],
              conditions: [noWinRemote],
            },
            { // lock
              from:       { key_code: 'l', modifiers: { mandatory: ['left_option'] } },
              to:         [{ key_code: 'q', modifiers: ['left_control', 'left_command'] }],
            },
            { // dark/light (powertoys)
              from:       { key_code: 'd', modifiers: { mandatory: ['left_shift', 'left_option'] }},
              to:         [{ shell_command: "zsh -ic toggle-lightdarkmode" }],
              conditions: [ifCtrl],
            },
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

          // no tilde key on this keyboard..
          ]+std.map(function(cond)
            lib.rule('Keychron K11 Max', [
              {
                from:       { key_code: 'escape', modifiers: { mandatory: ['left_command'] }},
                to:         [{ key_code: 'grave_accent_and_tilde', modifiers: ['left_command'] }],
              },
            ], conditions=[cond]),
            ifK11Max
          )+[

          // g602 still has mappings programmed from something else. just have to work with what i've got - their
          // old LGS software doesn't work on current mac os, and their newer G Hub or Options+ doesn't support this
          // mouse any more.
          lib.rule('Logitech G602', [
            // front pair
            { /*G7*/ from: { key_code: '6'      }, to: [{ key_code: 'right_arrow', modifiers: ['left_command', 'left_option', 'left_shift'] }] },  // virtual desktop to the right
            { /*G4*/ from: { key_code: '7'      }, to: [{ key_code: 'left_arrow', modifiers: ['left_command', 'left_option', 'left_shift'] }] },   // virtual desktop to the left
            // mid pair
            { /*G8*/ from: { key_code: '8'      }, to: [{ key_code: 'tab', modifiers: ['left_option'] }] },                   // expose all apps
            { /*G5*/ from: { key_code: '9'      }, to: [{ key_code: 'tab', modifiers: ['left_option', 'left_shift'] }] },     // expose current app
            // back pair
            { /*G9*/ from: { key_code: '0'      }, to: [{ key_code: 'close_bracket', modifiers: ['left_command'] }] },        // next tab in browser
            { /*G6*/ from: { key_code: 'escape' }, to: [{ key_code: 'open_bracket', modifiers: ['left_command'] }] },         // previous tab in browser
          ], conditions=[ ifG602 ]), 
        ]
      },

      local map(entries) = std.map(
          function(obj) {
            from: { [std.get(obj, 'from_type', 'key_code')]: obj.from },
            to:   [{ [std.get(obj, 'to_type', 'key_code')]: obj.to }],
          },
          entries),
      
      devices: [
        // remap apple fn to left ctrl to match windows typical laptop keyboards
        {
          identifiers: { is_keyboard: true },
          simple_modifications: map([
            { from: 'keyboard_fn', from_type: 'apple_vendor_top_case_key_code', to: 'left_control' },
            { from: 'left_control', to: 'keyboard_fn', to_type: 'apple_vendor_top_case_key_code' },
          ])
        },

        // important: go to karabiner devices view and enable "modify events" for any new device, then
        // copy its device block in here to work with. generally need to match exactly for it to modify
        // events for any given device.

        // keychron k11 max
        ]+std.map(function(identifiers)
          {
            identifiers: identifiers,
            ignore: false,

            // can just leave the switch set to win/android
            simple_modifications: map([
              { from: 'left_command',  to: 'left_option' },
              { from: 'left_option',   to: 'left_command' },
              { from: 'right_command', to: 'right_option' },
              { from: 'right_option',  to: 'right_command'},
            ]),
          },
          [
            // this is the specific way each mode of the keyboard needs to be selected or it won't work. i want to keep
            // the mac/win switch set to win mode always (so as not to care what kind of laptop is connected to the k11),
            // but also be able to go between BT and G modes based on desk setup.
            { is_keyboard: true, vendor_id: keychronVendorId, product_id: k11MaxBTProductId, is_pointing_device: true },
            { is_keyboard: true, vendor_id: keychronVendorId, product_id: k11MaxGProductId }
          ]
        )+[

        // logi mx anywhere 3s
        {
          identifiers: { is_pointing_device: true, vendor_id: 1133, product_id: 45111 },
          ignore: false,

          // sanity
          mouse_flip_vertical_wheel: true,
        },
        // logi g602
        {
          identifiers: { is_pointing_device: true, vendor_id: 1133, product_id: 50487 },
          ignore: false,

          // sanity
          mouse_flip_vertical_wheel: true,
        }
      ],
    }
  ]
}
