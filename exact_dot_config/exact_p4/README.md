# Perforce Config

## Global Setup

Tell P4 to use global environment file:

`p4 set P4ENVIRO="$(resolve-path ~/.config/p4/enviro)"`

## Per-p4root Setup

```powershell
# change to p4 client root
cd $p4root

# connection config
'P4CLIENT=$p4client', 'P4PORT=$p4port' > .p4config

# use global p4ignore
ni .p4ignore -target (rvpa ~/.config/p4/ignore) -it symbolic

# force connection to get P4_ var (see below)
p4 login
```

After the `p4 login`, open `~\.config\p4\enviro` and at the bottom there will be a new entry, like `P4_<hostname>:1667_CHARSET=none`. Move this line to `$p4root\.p4config`.

Then do `chezmoi apply ~/.config/p4/enviro` and overwrite.
