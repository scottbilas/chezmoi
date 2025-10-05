local SkyRocket = hs.loadSpoon("SkyRocket")

sky = SkyRocket:new({
  opacity = 0.5,

  moveModifiers = {'cmd', 'alt'},
  moveMouseButton = 'left',

  resizeModifiers = {'cmd', 'shift'},
  resizeMouseButton = 'left',

  focusWindowOnClick = false,
})
