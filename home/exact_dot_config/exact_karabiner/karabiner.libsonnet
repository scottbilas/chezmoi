{
  rule(name, items, conditions=[]) :: {
    description: name,
    manipulators: [
      { type: "basic" } + item + (
        if std.length(conditions) > 0 then
          { conditions: std.get(item, 'conditions', []) + conditions }
        else {}
      )
      for item in items
    ]
  },

  manip(fromKey, fromMods, toKey, toMods, conds=[], opts={}) ::
    {
      from: {
        key_code: fromKey,
        modifiers:
          if fromMods == 'any' then { optional: ['any'] }
          else fromMods,
      },
      to: [ if toKey == null then {} else (
        if toMods == null || toMods == [] then { key_code: toKey }
        else { key_code: toKey, modifiers: toMods }
      ) ],
      conditions: conds,
    } + opts,

  altgrAcute(keys)::
    std.map(function(key) {
      from: { key_code: key, modifiers: { mandatory: ['right_command'] } },
      to: [ 
        { key_code: 'e', modifiers: ['right_option'] },  // acute dead key
        { key_code: key }
      ]
    }, keys) + std.map(function(key) {
      from: { key_code: key, modifiers: { mandatory: ['right_command', 'shift'] } },
      to: [ 
        { key_code: 'e', modifiers: ['right_option'] },  // acute dead key
        { key_code: key, modifiers: ['right_shift'] }
      ]
    }, keys),

  altgrDirect(charMap)::
    std.flattenArrays(std.map(function(mapping)
      if std.objectHas(mapping, 'to_modifiers') then [
        {
          from: { key_code: mapping.from, modifiers: { mandatory: ['right_command'] } },
          to: [{ key_code: mapping.to, modifiers: ['right_option'] + mapping.to_modifiers }]
        }
      ] else [
        {
          from: { key_code: mapping.from, modifiers: { mandatory: ['right_command'] } },
          to: [{ key_code: mapping.to, modifiers: ['right_option'] }]
        },
        {
          from: { key_code: mapping.from, modifiers: { mandatory: ['right_command', 'shift'] } },
          to: [{ key_code: mapping.to, modifiers: ['right_option', 'right_shift'] }]
        }
      ], charMap)
    ),

  altgrDead(winDead, deadVar, keyMap, shift=false)::
    // 1) detect and activate dead key
    [{
      from: { key_code: winDead, modifiers: {
        mandatory: if shift then ['right_command', 'shift'] else ['right_command'] }},
      to: [{ set_variable: { name: deadVar, value: 1 }}]
    }] +
    // 2) valid chars get remapped and clear dead key (support lowercase and uppercase)
    std.flattenArrays(std.map(function(mapping) [{
      from: { key_code: mapping.from },
      to: 
        (if std.objectHas(mapping, 'macDead') then [
          { key_code: mapping.macDead, modifiers: ['right_option'] },
          { key_code: mapping.to }
        ] else [
          { key_code: mapping.to, modifiers: ['right_option'] }
        ]) +
        [ { set_variable: { name: deadVar, value: 0 } } ],
      conditions: [{ type: 'variable_if', name: deadVar, value: 1 }]
    }, {
      from: { key_code: mapping.from, modifiers: { mandatory: ['shift'] } },
      to: 
        (if std.objectHas(mapping, 'macDead') then [
          { key_code: mapping.macDead, modifiers: ['right_option'] },
          { key_code: mapping.to, modifiers: ['right_shift'] }
        ] else [
          { key_code: mapping.to, modifiers: ['right_option', 'right_shift'] }
        ]) +
        [ { set_variable: { name: deadVar, value: 0 } } ],
      conditions: [{ type: 'variable_if', name: deadVar, value: 1 }]
    }], keyMap)) +
    // 3) escape cancels dead key
    [{
      from: { key_code: 'escape' },
      to: [{ set_variable: { name: deadVar, value: 0 } }],
      conditions: [{ type: 'variable_if', name: deadVar, value: 1 }]
    }],
  
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

  ifDevice(vendor_id, product_id=null, is_keyboard=true):: {
    type: 'device_if',
    identifiers: [
      {
        vendor_id: vendor_id,
        is_keyboard: is_keyboard,
      } + (if product_id != null then { product_id: product_id } else {})
    ]
  },

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
