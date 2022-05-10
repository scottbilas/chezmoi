VERSION = "1.0.0"

local filepath = import("path/filepath")

function onBufferOpen(b)
    local _, fileName = filepath.Split(b.Path)
    local ext = fileName:match "[^.]+$"

    if fileName == "zaliases" then
        b:SetOption("filetype", "zsh")
        b:SetOption("tabsize", "2")
    elseif ext == "csproj" then
        b:SetOption("filetype", "xml")
        b:SetOption("tabsize", "2")
    end
end
