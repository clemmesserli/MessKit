Function Convert-Cipher {
	<#
	.SYNOPSIS
		Returns SSL Cipher name equivalent between IANA and OpenSSL
	.DESCRIPTION
		Returns SSL Cipher name equivalent between IANA and OpenSSL using openssl.exe
	.EXAMPLE
		convert-cipher -cipher 'AES256-SHA256'
		Returns the IANA equivalent string
	.EXAMPLE
		convert-cipher -cipher 'TLS_RSA_WITH_AES_256_CBC_SHA256'
		Returns the OpenSSL equivalent string
	.EXAMPLE
		convert-cipher -cipher 'TLS_RSA_WITH_AES_256_CBC_SHA256' -exePath 'C:\Program Files\Git\mingw64\bin\openssl.exe'
	.NOTES
		Requires a minimum of OpenSSL version 1.1.1 when defining the path to your openssl.exe file.
		If you have the latest version of GIT, it should have a recent version of openssl.exe.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]$cipher,

		[Parameter()]
		[string]$exePath = (Get-MyParam).'Convert-Cipher'.exePath
	)

	Begin {}

	Process {
		Try {
			#OpenSSL to IANA
			(& "$exePath" ciphers -stdname | Select-String "\s$cipher\s").tostring().split(" ")[0]
		} Catch {
			#IANA to OpenSSL
			(& "$exePath" ciphers -stdname | Select-String "^$cipher\s").tostring().split(" ")[2]
		}
	}

	End {}
}