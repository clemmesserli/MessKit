Function New-GoogleAuthSecret {
	<#
	.Synopsis
		Generate an 80-bit key, BASE32 encoded, secret
		and a URL to Google Charts which will show it as a QR code.
		The QR code can be used with the Google Authenticator app
	.EXAMPLE
		PS C:\> New-GoogleAuthSecret

		Secret           QrCodeUri
		------           ---------
		5WYYADYB5DK2BIOV http://chart.apis.google[..]
	.EXAMPLE
		PS C:\> New-GoogleAuthSecret -UseThisSecretCode "HP44SIFI2GFDZHT6" -Online
		# web browser opens and function will update pre-existing entry (if found)
	.EXAMPLE
		$param = @{
			Name = "charlie.brown@peanuts.com"
			Issuer = "WorkToken"
			Online = $true
		}
		New-GoogleAuthSecret @param | fl *
		# web browser opens, and you can scan your bank code into the app, with new text around it
	#>
	[CmdletBinding()]
	Param (
		# Secret length in bytes, must be a multiple of 5 bits for neat BASE32 encoding
		[ValidateScript( { ($_ * 8) % 5 -eq 0 })]
		[Int]$SecretLength = 15,

		# Use an existing secret code, don't generate a new one, just update it with new text
		[String]$UseThisSecretCode,

		# Launches a web browser to show a QR Code
		[Switch]$Online = $false,

		# Name is text that will appear within ()
		[String]$Name = 'charlie.brown@peanuts.com',

		# Issuer is text that will appear left of the () in Google Authenticator app
		[String]$Issuer = 'WorkToken'
	)

	Begin {
		$Script:Base32Charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
	}

	Process {
		# If there's a secret provided then use it, otherwise we need to generate one
		if ($PSBoundParameters.ContainsKey('UseThisSecretCode')) {
			$Base32Secret = $UseThisSecretCode
		} else {
			# Generate random bytes for the secret
			$byteArrayForSecret = [byte[]]::new($SecretLength)
			[Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($byteArrayForSecret, 0, $SecretLength)

			# BASE32 encode the bytes
			# 5 bits per character doesn't align with 8-bits per byte input,
			# and needs careful code to take some bits from separate bytes.
			# Because we're in a scripting language let's dodge that work.
			# Instead, convert the bytes to a 10100011 style string:
			$byteArrayAsBinaryString = -join $byteArrayForSecret.ForEach{
				[Convert]::ToString($_, 2).PadLeft(8, '0')
			}

			# then use regex to get groups of 5 bits
			# -> convert those to integer
			# -> lookup that as an index into the BASE32 character set
			# -> result string
			$Base32Secret = [regex]::Replace($byteArrayAsBinaryString, '.{5}', {
					param($Match)
					$Script:Base32Charset[[Convert]::ToInt32($Match.Value, 2)]
				})
		}

		# Generate the URI which needs to go to the Google Authenticator App.
		# URI escape each component so the name and issuer can have punctiation characters.
		$otpUri = "otpauth://totp/{0}?secret={1}&issuer={2}" -f @(
			[Uri]::EscapeDataString($Name),
			$Base32Secret
			[Uri]::EscapeDataString($Issuer)
		)

		# Double-encode because we're going to embed this into a Google Charts URI,
		# and these need to still be encoded in the QR code after Charts webserver has decoded once.
		$encodedUri = [Uri]::EscapeDataString($otpUri)

		# Tidy output, with a link to Google Chart API to make a QR code
		$keyDetails = [PSCustomObject]@{
			Secret    = $Base32Secret
			KeyUri    = $otpUri
			QrCodeUri = "https://chart.apis.google.com/chart?cht=qr&chs=200x200&chl=${encodedUri}"
		}

		# Online switch launches a system WebBrowser.
		if ($Online) {
			Start-Process $keyDetails.QrCodeUri
		}

		$keyDetails
	}

	End {}
}