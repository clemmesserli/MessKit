Function Convert-MKNetMaskToCIDR {
	<#
	.LINK
	https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
	#>
	[CmdletBinding()]
	Param (
		[String]$SubnetMask = '255.255.255.0'
	)

	Begin {}

	Process {
		$byteRegex = '^(0|128|192|224|240|248|252|254|255)$'
		$invalidMaskMsg = "Invalid SubnetMask specified [$SubnetMask]"
		Try {
			$netMaskIP = [IPAddress]$SubnetMask
			$addressBytes = $netMaskIP.GetAddressBytes()

			$strBuilder = New-Object -TypeName Text.StringBuilder

			$lastByte = 255
			foreach ($byte in $addressBytes) {

				# Validate byte matches net mask value
				if ($byte -notmatch $byteRegex) {
					Write-Error -Message $invalidMaskMsg -Category InvalidArgument -ErrorAction Stop
				} elseif ($lastByte -ne 255 -and $byte -gt 0) {
					Write-Error -Message $invalidMaskMsg -Category InvalidArgument -ErrorAction Stop
				}

				[void]$strBuilder.Append([Convert]::ToString($byte, 2))
				$lastByte = $byte
			}
		($strBuilder.ToString().TrimEnd('0')).Length
		} Catch {
			Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
		}
	}

	End {}
}
