local SkyRocket = hs.loadSpoon("SkyRocket")

sky = SkyRocket:new({
  opacity = 0.5,

  moveModifiers = {'cmd', 'shift'},
  moveMouseButton = 'left',

  resizeModifiers = {'cmd', 'alt'},
  resizeMouseButton = 'left',

  focusWindowOnClick = false,
})
