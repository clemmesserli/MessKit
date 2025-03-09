Function Convert-MKNetMaskToCIDR {
  <#
  .SYNOPSIS
    Converts an IPv4 subnet mask to CIDR prefix length.

  .DESCRIPTION
    The Convert-MKNetMaskToCIDR function converts a traditional IPv4 subnet mask
    in dotted decimal format (e.g., 255.255.255.0) to its equivalent CIDR prefix length (0-32).
    This function is useful for networking tasks that require translation between
    traditional subnet masks and CIDR notation.

  .PARAMETER SubnetMask
    The IPv4 subnet mask in dotted decimal format to convert to CIDR notation.
    Default value is '255.255.255.0', which results in a CIDR prefix of 24.

  .EXAMPLE
    PS> Convert-MKNetMaskToCIDR -SubnetMask "255.255.255.0"
    24

  .EXAMPLE
    PS> Convert-MKNetMaskToCIDR -SubnetMask "255.255.0.0"
    16

  .EXAMPLE
    PS> "255.0.0.0", "255.255.0.0", "255.255.255.0", "255.255.255.255" | Convert-MKNetMaskToCIDR
    8
    16
    24
    32

  .NOTES
    File Name      : Convert-MKNetMaskToCIDR.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later

  .LINK
    https://github.com/MyGitHub/MessKit
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('Mask', 'NetMask')]
    [String]$SubnetMask
  )

  Process {
    try {
      # Define valid subnet mask byte values and error message
      $byteRegex = '^(0|128|192|224|240|248|252|254|255)$'
      $invalidMaskMsg = "Invalid SubnetMask specified [$SubnetMask]"

      # Convert string to IP address and get bytes
      $netMaskIP = [IPAddress]$SubnetMask
      $addressBytes = $netMaskIP.GetAddressBytes()

      # Initialize string builder for binary representation
      $strBuilder = New-Object -TypeName Text.StringBuilder

      # Validate byte pattern and build binary string
      $lastByte = 255
      foreach ($byte in $addressBytes) {
        # Validate byte matches valid subnet mask values
        if ($byte -notmatch $byteRegex) {
          Write-Error -Message $invalidMaskMsg -Category InvalidArgument -ErrorAction Stop
        }
        # Ensure zeros only come after other zeros (no gaps in the mask)
        elseif ($lastByte -ne 255 -and $byte -gt 0) {
          Write-Error -Message $invalidMaskMsg -Category InvalidArgument -ErrorAction Stop
        }

        # Convert byte to binary and append to string builder
        [void]$strBuilder.Append([Convert]::ToString($byte, 2))
        $lastByte = $byte
      }

      # Count the number of '1' bits in the binary representation
      return ($strBuilder.ToString().TrimEnd('0')).Length
    } catch {
      Write-Error -Message "Failed to convert subnet mask $SubnetMask to CIDR: $_" -Category $_.CategoryInfo.Category
    }
  }
}
