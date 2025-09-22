{
  rule(name, items) :: {
    description: name,
    manipulators: [
      { type: "basic" } + item
      for item in items
    ]
  },

  manip(fromKey, fromMods, toKey, toMods, conds=[], opts={}) ::
    {
      from: {
        key_code: fromKey,
        modifiers: if fromMods == null || fromMods == [] then {} else { optional: fromMods },
      },
      to: [ if toKey == null then {} else (
        if toMods == null || toMods == [] then { key_code: toKey }
        else { key_code: toKey, modifiers: toMods }
      ) ],
      conditions: conds,
    } + opts,

  ctrlToCmd(keys, conds=[]) ::
    std.flattenArrays(std.map(function(k) [
      $.manip(k, ['left_control'         ], k, ['left_command'         ], conds),
      $.manip(k, ['left_control', 'shift'], k, ['left_command', 'shift'], conds),
    ], keys)),

  ifApp(bundles) ::
    { type: 'frontmost_application_if', bundle_identifiers: bundles },
  noApp(bundles) ::
    { type: 'frontmost_application_unless', bundle_identifiers: bundles },

  ifVar(name, val=1) ::
    { type: 'variable_if', name: name, value: val },
  set(name, v=1) ::
    { set_variable: { name: name, value: v } },
  clear(name) ::
    { set_variable: { name: name, value: 0 } },

  // returns ['a', 'b', ..., 'z']
  A_TO_Z :: std.map(
    function(i) std.char(i),
    std.range(std.codepoint('a'), std.codepoint('z'))
  ),

  // returns ['0', '1', ..., '9']
  DIGITS :: std.map(
    function(i) std.toString(i),
    std.range(0, 9)
  ),
}
