# TERMUX: Ctrl+Alt+

New session         C
Rename session      R
Next, prev session  N/dn, P/up
Select session      1-9
Paste from OS       V
Show menu           M
Select URL          U
Adjust font size    +-
Open, close drawer  rt, lt

# TMUX: prefix+

*Windows*

Create window       C
Select window       0-9
Rename window       ,
List windows        w
Kill window         &
Next, prev window   np
Move windowpos l/r  <>
Renumber all        :movew -r

*Panes*

Select pane         hjkl (; = last)
Select pane by #    q (then 0)
Select last pane    ;
Promote pane->wnd   !
Kill pane           x
Resize by 5         HJKL
Split h, v (/full)  -_ , bar/backslash
Rotate pane l, r    {, }
Next layout         space
Select layout       alt-1-5

*Copypasta*

Extrakto            tab
Copy                [ {begin} space {end} enter
Toggle select       space
Rectangle           v
Select line         V
Top/mid/bottom      H, M, L
Abort               q
Clear select        esc
Paste               ]

*Misc*

Session list        s
Name session        $
Reload tmux.conf    r
Update plugins      I
Save/resurrect      ctrl-s/r

# Micro

*Tabs and Panes*

Split h, v          alt-h, alt-v
Select pane         alt-[]
New tab             ^t
Select tab          alt-,.

*Editing*

Multi-cursor        ^d (^k = skip)
Lines to multi-c    alt-m
Find                ^f (^n = next, ^p = prev)
Toggle recording    ^u
Playback recording  ^j

*Misc*

Open any file       alt-p
Close pane          ^w
Quit                alt-q

*Explorer*

Toggle explorer     ^b
Rename file         f2
Open in pane        enter
New file            alt-n
New dir             alt-N
