Function Convert-MKIntToIPv4 {
  <#
    .SYNOPSIS
        Converts a 32-bit integer to an IPv4 address.

    .DESCRIPTION
        The Convert-MKIntToIPv4 function converts a 32-bit unsigned integer to its
        corresponding IPv4 address in dotted decimal notation (e.g., 192.168.1.1).

        This function is useful for:
        - Network addressing calculations
        - Converting database-stored IP addresses from integer format
        - Working with IP address ranges represented as integers
        - Interfacing with APIs that return IPs as integers

    .PARAMETER Integer
        A 32-bit unsigned integer (uint32) representing an IPv4 address.
        Valid range is from 0 to 4294967295.

    .EXAMPLE
        PS> Convert-MKIntToIPv4 -Integer 3232235777
        192.168.0.1

    .EXAMPLE
        PS> Convert-MKIntToIPv4 -Integer 167772160
        10.0.0.0

    .EXAMPLE
        PS> 2130706433 | Convert-MKIntToIPv4
        127.0.0.1

    .EXAMPLE
        PS> @(3232235777, 3232235778, 3232235779) | Convert-MKIntToIPv4
        192.168.1.1
        192.168.1.2
        192.168.1.3

    .NOTES
        File Name      : Convert-MKIntToIPv4.ps1
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
    [ValidateRange(0, [uint32]::MaxValue)]
    [uint32]$Integer
  )

  Process {
    Try {
      $bytes = [System.BitConverter]::GetBytes($Integer)
      [Array]::Reverse($bytes)
            ([IPAddress]($bytes)).ToString()
    } Catch {
      Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
    }
  }
}