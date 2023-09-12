Function Suspend-ScreenLock {
    <#
	.SYNOPSIS
		Suspend user screen lock due to inactivity by simulating keyboard keypress.
	.DESCRIPTION
		Suspend user screen lock due to inactivity by simulating keyboard keypress (Default = 90 minutes).
        Typical use might be running this in a 2nd terminal window while you passively tail log files in primary window.
	.EXAMPLE
		Suspend-Screenlock -minutes 180 -verbose
	#>
    [CmdletBinding()]
    Param (
        [Int]$minutes = 90
    )

    Begin {}

    Process {
        $myShell = New-Object -ComObject WScript.Shell

        for ($i = 0; $i -lt $minutes; $i++) {
            Start-Sleep -Seconds 60
            $myShell.sendkeys("{F15}")
            Write-Verbose "Total Time: $i (minutes)"
        }
    }

    End {}
}