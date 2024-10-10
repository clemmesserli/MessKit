Function Convert-MKCIDRToNetMask {
	<#
	.LINK
	https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
	#>
	[CmdletBinding()]
	Param (
		[ValidateRange(0, 32)]
		[int16]$PrefixLength = 0
	)

	Begin {}

	Process {
		$bitString = ('1' * $PrefixLength).PadRight(32, '0')

		$strBuilder = New-Object -TypeName Text.StringBuilder

		for ($i = 0; $i -lt 32; $i += 8) {
			$8bitString = $bitString.Substring($i, 8)
			[void]$strBuilder.Append("$([Convert]::ToInt32($8bitString,2)).")
		}

		$strBuilder.ToString().TrimEnd('.')
	}

	End {}
}