{
  rule(name, items) ::
    { description: name, manipulators: items },

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
}
