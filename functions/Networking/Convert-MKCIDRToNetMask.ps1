Function Convert-MKCIDRToNetMask {
  <#
  .SYNOPSIS
    Converts a CIDR prefix length to an IPv4 subnet mask.

  .DESCRIPTION
    The Convert-MKCIDRToNetMask function converts a CIDR notation prefix length (0-32)
    to its corresponding IPv4 subnet mask in dotted decimal format (e.g., 255.255.255.0).
    This function is useful for networking tasks that require translation between
    CIDR notation and traditional subnet masks.

  .PARAMETER CIDR
    The CIDR prefix length to convert (0-32).
    Default value is 0, which results in a subnet mask of 0.0.0.0.

  .EXAMPLE
    PS> Convert-MKCIDRToNetMask -CIDR 24
    255.255.255.0

  .EXAMPLE
    PS> Convert-MKCIDRToNetMask -CIDR 16
    255.255.0.0

  .EXAMPLE
    PS> 8, 16, 24, 32 | Convert-MKCIDRToNetMask
    255.0.0.0
    255.255.0.0
    255.255.255.0
    255.255.255.255

  .NOTES
    File Name      : Convert-MKCIDRToNetMask.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later

  .LINK
    https://github.com/MyGitHub/MessKit
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateRange(0, 32)]
    [int]$CIDR
  )

  Process {
    try {
      # Create a byte array with the appropriate number of '1' bits
      $maskBytes = [byte[]]::new(4)

      for ($i = 0; $i -lt 4; $i++) {
        # Calculate how many bits in this byte should be 1
        $bitsInByte = [Math]::Min(8, [Math]::Max(0, $CIDR - ($i * 8)))

        # Set the byte value based on the number of bits
        if ($bitsInByte -gt 0) {
          $maskBytes[$i] = [byte]((0xff) -shl (8 - $bitsInByte) -band 0xff)
        } else {
          $maskBytes[$i] = 0
        }
      }

      # Return the resulting subnet mask in dotted decimal notation
      return "$($maskBytes[0]).$($maskBytes[1]).$($maskBytes[2]).$($maskBytes[3])"
    } catch {
      Write-Error "Failed to convert CIDR $CIDR to subnet mask: $_"
    }
  }
}