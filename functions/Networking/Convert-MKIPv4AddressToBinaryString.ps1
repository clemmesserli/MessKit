Function Convert-MKIPv4AddressToBinaryString {
	<#
	.LINK
	https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
	#>
	[CmdletBinding()]
	Param (
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