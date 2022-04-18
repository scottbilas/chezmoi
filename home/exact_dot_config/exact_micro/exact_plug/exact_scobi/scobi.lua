VERSION = "1.0.0"

local filepath = import("path/filepath")

function onBufferOpen(b)
    local _, fileName = filepath.Split(b.Path)

    if fileName == "zaliases" then
        b:SetOption("filetype", "zsh")
    end
end
