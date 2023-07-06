# simple script just dumps all devices to a file every second and prints if there is a difference

# i originally wrote this to try to diagnose why i'm getting some usb device resets periodically on my laptop
# but it doesn't query nearly fast enough for that. would have to find another way, possibly by looking at some
# kind of system event notifying of a hardware change.

del *.txt
$i = 0
$last = $null
for (;;) {
    write-host -nonew '.'
    get-pnpdevice | select friendlyname, status | sort-object friendlyname > devices.txt
    $hash = (get-filehash devices.txt).hash
    if ($hash -eq $last) { continue }

    $last = $hash
    "`r$hash $((get-date).tostring('HH:mm:ss')) #$i"
    ren devices.txt "$i.txt"
    ++$i

    sleep -seconds 1
}
