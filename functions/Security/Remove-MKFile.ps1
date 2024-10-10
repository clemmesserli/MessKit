function Remove-MKFile {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[int]$Passes = 5
	)

	$file = Get-Item $Path
	$size = $file.Length
	$buffer = New-Object byte[] $size

	for ($pass = 1; $pass -le $Passes; $pass++) {
		# Fill buffer with random data
		$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
		$rng.GetBytes($buffer)

		# Overwrite file with random data
		[System.IO.File]::WriteAllBytes($file.FullName, $buffer)

		# Flush to disk and release the file handle
		[System.IO.File]::OpenWrite($file.FullName).Close()

		# Randomize last access and last write times
		$randomDate = Get-MKRandomDate
		Set-ItemProperty -Path $file.FullName -Name LastAccessTime -Value $randomDate
		Set-ItemProperty -Path $file.FullName -Name LastWriteTime -Value $randomDate

		# Refresh the file object to get updated properties
        $file = Get-Item $Path

		# Verify the changes (optional)
		$content = [System.IO.File]::ReadAllBytes($file.FullName)
		$hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new($content)) -Algorithm SHA256
		Write-Verbose "Pass $pass hash: $($hash.Hash) TimeStamp $($file.LastWriteTime)"
	}
	# Delete the file
	Remove-Item $file.FullName -Force
	Write-Verbose "File securely deleted: $($file.FullName)"
}