Function Convert-MKIPv4AddressToBinaryString {
  <#
    .SYNOPSIS
        Converts an IPv4 address to its binary string representation.

    .DESCRIPTION
        The Convert-MKIPv4AddressToBinaryString function converts an IPv4 address in dotted decimal
        notation (e.g., 192.168.1.1) to a 32-character binary string of 0s and 1s.

        This function is useful for:
        - Subnet mask calculations
        - Network addressing visualization
        - Understanding binary network address representation
        - Educational purposes when learning about network addressing

    .PARAMETER IPAddress
        An IPv4 address as a string or IPAddress object to convert to binary representation.
        Default value is '0.0.0.0' if not specified.

    .EXAMPLE
        PS> Convert-MKIPv4AddressToBinaryString -IPAddress "104.18.40.47"
        11000000101010000000000100000001

    .EXAMPLE
        PS> Convert-MKIPv4AddressToBinaryString -IPAddress "255.255.255.0"
        11111111111111111111111100000000

    .EXAMPLE
        PS> Convert-MKIPv4AddressToBinaryString -IPAddress ([IPAddress]"127.0.0.1")
        01111111000000000000000000000001

    .EXAMPLE
        PS> Convert-MKIPv4AddressToBinaryString
        00000000000000000000000000000000

    .NOTES
        File Name      : Convert-MKIPv4AddressToBinaryString.ps1
        Author         : MessKit
        Requires       : PowerShell 5.1 or later
        Version        : 1.0

    .LINK
        https://github.com/MyGitHub/MessKit
        https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
    #>
  [CmdletBinding()]
  Param (
    [Parameter(ValueFromPipeline = $true)]
    [IPAddress]$IPAddress = '0.0.0.0'
  )

  Begin {}

  Process {
    $addressBytes = $IPAddress.GetAddressBytes()

    $strBuilder = New-Object -TypeName Text.StringBuilder
    foreach ($byte in $addressBytes) {
      $8bitString = [Convert]::ToString($byte, 2).PadRight(8, '0')
      [void]$strBuilder.Append($8bitString)
    }
    Write-Output $strBuilder.ToString()
  }

  End {}
}