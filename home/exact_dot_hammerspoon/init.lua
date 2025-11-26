-- easy window resize/move
local SkyRocket = hs.loadSpoon("SkyRocket")
sky = SkyRocket:new({
  opacity = 0.5,

  -- printWindowInfo = true,  -- uncomment to debug window properties

  -- ignore the green zoom frame (during partial screen share)
  disabledApps = {
    { bundleID = 'us.zoom.xos', title = 'Annotation - Zoom', action = 'passthrough' },
  },

  moveModifiers = {'cmd', 'alt'},
  moveMouseButton = 'left',
  resizeModifiers = {'cmd', 'shift'},
  resizeMouseButton = 'left',
  regionRatio = 0.25,
  focusWindowOnClick = true,
})
