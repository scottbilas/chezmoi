# if this script gets used, then we're on windows and nushell is using defaults.

const path_self = path self
$env.config.show_banner = false

print ''
print $"(ansi red)** XDG NOT SET UP **(ansi reset)"
print $"incorrect config was used: '($path_self)'"
print ''

let xdg_paths = {
    XDG_DATA_HOME:   ~/.local/share,
    XDG_CONFIG_HOME: ~/.config,
    XDG_CACHE_HOME:  ~/.cache }

let xdg_registry = (
    reg query HKCU\Environment |
    parse --regex '(?<name>\w+)\s+REG_SZ\s+(?<value>.*)$' |
    where name =~ 'XDG' )

$xdg_paths | items { |name, defpath|

    let defpathex = $defpath | path expand
    let current = $env | get -i $name

    if ($current != null) {
        print $"($name) is set to '($current)'"
    } else {
        let pathreg = ($xdg_registry | where name == $name).value
        if ($pathreg == []) {
            print $"(ansi yellow)($name) is not set; fixing to point it at ($defpathex)(ansi reset)"
            setx $name $defpathex
        } else {
            print $"Detected ($name) set in system but not shell. Need to restart the whole process chain!"
        }
    }
} | ignore

print ''
print $"(ansi green)** close and restart all shells **(ansi reset)"
