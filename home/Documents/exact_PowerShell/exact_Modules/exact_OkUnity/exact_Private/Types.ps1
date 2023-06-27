class UnityVersion : System.IComparable {

    # from Runtime/Utilities/UnityVersion.h
    [int]    $Major;
    [int]    $Minor;
    [int]    $Revision;
    [char]   $ReleaseType; # alpha, beta, public, patch, experimental
    [int]    $Incremental;
    [string] $Branch;
    [string] $Hash;

    UnityVersion([string] $version) {

        $rx = '^(?imnx-s)
            (?<Major>\d+)
            (\.(?<Minor>\d+)
             (\.(?<Revision>\d+)
              ((?<ReleaseType>[a-z])
               ((?<Incremental>\d+)
                (-
                 ((?<Branch>\w+)_)?
                 (?<Hash>[a-f0-9]{12})
            )?)?)?)?)?$'

        if ($version -notmatch $rx) {
            throw "Unexpected Unity version format: '$version'"
        }

        $this.Major        = [int]$Matches.Major
        $this.Minor        = [int]$Matches.Minor
        $this.Revision     = [int]$Matches.Revision
        $this.ReleaseType  = [char]$Matches.ReleaseType
        $this.Incremental  = [int]$Matches.Incremental
        $this.Branch       = $Matches.Branch
        $this.Hash         = $Matches.Hash
    }

    # powershell classes apparently don't support default params

    UnityVersion(
        [int]    $major) {
        $this.Major        = $major
    }
    
    UnityVersion(
        [int]    $major,
        [int]    $minor) {
        $this.Major        = $major
        $this.Minor        = $minor
    }
    
    UnityVersion(
        [int]    $major,
        [int]    $minor,
        [int]    $revision) {
        $this.Major        = $major
        $this.Minor        = $minor
        $this.Revision     = $revision
    }
    
    UnityVersion(
        [int]    $major,
        [int]    $minor,
        [int]    $revision,
        [char]   $releaseType) {
        $this.Major        = $major
        $this.Minor        = $minor
        $this.Revision     = $revision
        $this.ReleaseType  = $releaseType
    }
    
    UnityVersion(
        [int]    $major,
        [int]    $minor,
        [int]    $revision,
        [char]   $releaseType,
        [int]    $incremental) {
        $this.Major        = $major
        $this.Minor        = $minor
        $this.Revision     = $revision
        $this.ReleaseType  = $releaseType
        $this.Incremental  = $incremental
    }
    
    UnityVersion(
        [int]    $major,
        [int]    $minor,
        [int]    $revision,
        [char]   $releaseType,
        [int]    $incremental,
        [string] $hash) {
        $this.Major        = $major
        $this.Minor        = $minor
        $this.Revision     = $revision
        $this.ReleaseType  = $releaseType
        $this.Incremental  = $incremental
        $this.Hash         = $hash
    }
    
    UnityVersion(
        [int]    $major,
        [int]    $minor,
        [int]    $revision,
        [char]   $releaseType,
        [int]    $incremental,
        [string] $branch,
        [string] $hash) {
        $this.Major        = $major
        $this.Minor        = $minor
        $this.Revision     = $revision
        $this.ReleaseType  = $releaseType
        $this.Incremental  = $incremental
        $this.Branch       = $branch
        $this.Hash         = $hash
    }
    
    [string] ToString() {
        $str = "$($this.Major).$($this.Minor).$($this.Revision)"
        if ($this.ReleaseType) {
            $str += $this.ReleaseType
            if ($this.Incremental) {
                $str += $this.Incremental
                if ($this.Branch -and $this.Hash) {
                    $str += "-$($this.Branch)_$($this.Hash)"
                }
                elseif ($this.Hash) {
                    $str += "-$($this.Hash)"
                }
            }
        }
        
        return $str
    }

    [bool] Equals($obj) {
        if ($null -eq $obj) { return $false }
        if ($obj -isnot [UnityVersion]) { return $false }

        return [UnityVersion]::Compare($this, $obj) -eq 0
    }

    [int] CompareTo($obj) {
        if ($null -eq $obj) { return 1 }
        if ($obj -isnot [UnityVersion]) { throw "Object is not a UnityVersion" }

        return [UnityVersion]::Compare($this, $obj)
    }

    static [int] Compare([UnityVersion] $a, [UnityVersion] $b) {
        if ($a.Hash -and $a.Hash -eq $b.Hash) { return 0 }

        if ($a.Major       -ne $b.Major)       { return $a.Major       - $b.Major       }
        if ($a.Minor       -ne $b.Minor)       { return $a.Minor       - $b.Minor       }
        if ($a.Revision    -ne $b.Revision)    { return $a.Revision    - $b.Revision    }
        if ($a.ReleaseType -ne $b.ReleaseType) { return $a.ReleaseType - $b.ReleaseType }
        if ($a.Incremental -ne $b.Incremental) { return $a.Incremental - $b.Incremental }

        $c = [string]::Compare($a.Branch, $b.Branch)
        if ($c) { return $c }
        $c = [string]::Compare($a.Hash, $b.Hash)
        if ($c) { return $c }

        return 0
    }
}
