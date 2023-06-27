# like from choco (originally from https://stackoverflow.com/a/22670892/14582)
# TODO: print out what got updated!
# TODO: also have the registry path override the current path (like if anything was reordered there)
function refreshenv {
    foreach ($level in 'Machine', 'User') {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | % {
            if ($_.Name -eq 'path') { 
                $_.Value = (((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select -unique) -join ';'
            }
            $_
        } | Set-Content -Path { "Env:$($_.Name)" }
    }
}
Export-ModuleMember refreshenv

#### WIP BELOW
<#

# this script won't necessarily give the same results as a new session because anything can happen
# in a $profile. we can better-approximate it by sublaunching a pwsh (without inheriting the parent 
# process environment*) and telling it to dump its env vars, which we override our own set with.
#
# * some quick research shows this might be hard. CreateProcess seems to only give either "inherit
#   parent process" or "fully override"...

# these are semicolon-delimited vars that will get merged between system, user, and current env
$merge = 'path', 'pathext', 'psmodulepath'
# just skip these, we never want them to override
$skip = 'username', 'powershell_distribution_channel'

$have = @{}         # current env vars
$proposed = @{}     # proposed env vars

# prefill with existing environment vars
foreach ($var in (Get-ChildItem env:)) {
    $have[$var.Key] = $var.Value

    if ($merge -contains $var.Key) {
        $proposed[$var.Key] = $var.Value
    }
}

# override/extend with env vars from the registry
foreach ($group in 'Machine', 'User') {
    foreach ($var in [Environment]::GetEnvironmentVariables($group).GetEnumerator()) {
        if ($skip -contains $var.Key) { continue }

        # simple override by default
        $updated = $var.Value

        # semicolon-merge?
        if ($merge -contains $var.Key) {
            $existing = $proposed[$var.Key]
            if ($existing) {
                $updated = (($existing + ";$updated") -split ';' | Select-Object -unique | Where-Object { $_ }) -join ';'
            }
        }
        
        $proposed[$var.Key] = $updated
    }
}

foreach ($var in $have.getenumerator()) {
    $pvalue = $proposed[$var.Key]
    $hvalue = $have[$var.Key]

    if ($pvalue -and ($pvalue -ne $hvalue)) {
        write-host "$($var.Key):"
        write-host "  -$($hvalue)"
        write-host "  +$($pvalue)"

    }
}

<#
    # DO WE WANT THIS?
    # HWND_BROADCAST, WM_WININICHANGE, (unused), (name of changed parameter), SMTO_ABORTIFHUNG, timeoutMs, out result
    if (-not ("Win32.NativeMethods" -as [Type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
        "@
    }
    [Win32.Nativemethods]::SendMessageTimeout([IntPtr] 0xffff, 0x1a, [UIntPtr]::Zero, "Environment", 2, 5000, [ref][UIntPtr]::Zero) | Out-Null
#>  



#>
