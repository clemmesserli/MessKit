Function Get-GoogleAuthPin {
	<#
	.SYNOPSIS
		Takes a Google Authenticator secret like 'T5UOE4YLIFYTZQA2' and generates the PIN code for it
	.EXAMPLE
  		PS C:\>Get-GoogleAuthenticatorPin -Secret T5UOE4YLIFYTZQA2
  		372 251
	.NOTES
		Ref: https://github.com/HumanEquivalentUnit/PowerShell-Misc/blob/master/GoogleAuthenticator.psm1#L142
	#>
	[CmdletBinding()]
	Param (
		# BASE32 encoded Secret e.g. T5UOE4YLIFYTZQA2
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[String]$Secret,

		# OTP time window in seconds
		[Int]$TimeWindow = 30
	)

	Begin {}

	Process {
		[Byte[]]$secretAsBytes = ConvertFrom-Base32 "$secret" -OutBytes -Raw

		$epochTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

		# Convert the time to a big-endian byte array
		$timeBytes = [BitConverter]::GetBytes([Int64][Math]::Floor($epochTime / $TimeWindow))
		if ([BitConverter]::IsLittleEndian) {
			[Array]::Reverse($timeBytes)
		}

		# Do the HMAC calculation with the default SHA1
		# Google Authenticator app does support other hash algorithms, this code doesn't
		$hmacGen = [Security.Cryptography.HMACSHA1]::new($secretAsBytes)
		$hash = $hmacGen.ComputeHash($timeBytes)

		# Take half the last byte
		$offset = $hash[$hash.Length - 1] -band 0xF

		# Use it as an index into the hash bytes and take 4 bytes from there (big-endian needed)
		$fourBytes = $hash[$offset..($offset + 3)]
		if ([BitConverter]::IsLittleEndian) {
			[Array]::Reverse($fourBytes)
		}

		# Remove the most significant bit
		$num = [BitConverter]::ToInt32($fourBytes, 0) -band 0x7FFFFFFF

		# remainder of dividing by 1M
		# pad to 6 digits with leading zero(s)
		# and put a space for nice readability
		$PIN = ($num % 1000000).ToString().PadLeft(6, '0').Insert(3, ' ')

		[PSCustomObject]@{
			'PinCode'          = $PIN
			'SecondsRemaining' = ($TimeWindow - ($epochTime % $TimeWindow))
		}
	}

	End {}
}

Function New-OTPSecret {
	$RNG = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
	[Byte[]]$x = 1
	for ($r = ''; $r.length -lt 64) {
		$RNG.GetBytes($x)
		if ([char]$x[0] -clike '[2-7A-Z]') {
			$r += [char]$x[0]
		}
	}
	$r
}