Function Get-USB {
    <#
    .Synopsis
        Gets USB devices attached to the system
    .Description
        Uses WMI to get the USB Devices attached to the system
    .EXAMPLE
        Get-USB
    .EXAMPLE
        Get-USB | Group-Object Manufacturer
    .PARAMETER ComputerName
        The name of the computer to get the USB devices from
    #>
    [CmdletBinding()]
    Param (
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        [Alias("RunAs")]
        $Credential,

        [Parameter()]
        [String[]]$computerName = "localhost"
    )

    Begin {}

    Process {
        if ($ComputerName -eq "localhost") {
            Get-CimInstance Win32_USBDevice
        } else {
            $CimSession = New-CimSession -ComputerName $ComputerName -Credential $Credential
            Get-CimInstance Win32_USBControllerDevice -CimSession $CimSession
        }
    }

    End {}
}