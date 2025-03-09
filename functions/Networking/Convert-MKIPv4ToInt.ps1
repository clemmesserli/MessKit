Function Convert-MKIPv4ToInt {
  <#
    .SYNOPSIS
        Converts an IPv4 address to a 32-bit integer.

    .DESCRIPTION
        The Convert-MKIPv4ToInt function converts an IPv4 address in dotted decimal notation
        (e.g., 192.168.1.1) to its corresponding 32-bit unsigned integer representation.

        This function is useful for:
        - Network addressing calculations
        - Storing IP addresses efficiently in databases
        - Working with IP address ranges and subnets
        - Interfacing with APIs that require IPs in integer format

    .PARAMETER IPv4Address
        An IPv4 address string in dotted decimal notation (e.g., "192.168.1.1").
        Must be a valid IPv4 address format.

    .EXAMPLE
        PS> Convert-MKIPv4ToInt -IPv4Address "192.168.0.1"
        3232235521

    .EXAMPLE
        PS> Convert-MKIPv4ToInt -IPv4Address "10.0.0.0"
        167772160

    .EXAMPLE
        PS> [IPAddress]"127.0.0.1" | Convert-MKIPv4ToInt
        2130706433

    .EXAMPLE
        PS> @("192.168.1.1", "192.168.1.2", "192.168.1.3") | Convert-MKIPv4ToInt
        3232235777
        3232235778
        3232235779

    .NOTES
        File Name      : Convert-MKIPv4ToInt.ps1
        Author         : MessKit
        Requires       : PowerShell 5.1 or later
        Version        : 1.0

        The function handles endianness conversion internally.

    .LINK
        https://github.com/MyGitHub/MessKit
        https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$IPv4Address
  )

  Process {
    Try {
      $ipAddress = [IPAddress]::Parse($IPv4Address)

      $bytes = $ipAddress.GetAddressBytes()
      [Array]::Reverse($bytes)

      [System.BitConverter]::ToUInt32($bytes, 0)
    } Catch {
      Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
    }
  }
}
