Function Compress-Log {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$FolderPath,

		[Parameter()]
		[int]$LogRetentionDays = 90,

		[Parameter()]
		[int]$ArchiveRetentionDays = 8
	)

	Begin {}

	Process {
		$directoryList = (Get-ChildItem $FolderPath -Recurse -Directory).FullName

		$currentDate = Get-Date
		$retentionDate = $currentDate.AddDays("-$($LogRetentionDays)")
		$compressionDate = $currentDate.AddDays("-$($ArchiveRetentionDays)")

		$total = $directoryList.Count
		$count = 0
		foreach ($folder in $directoryList) {
			$count++
			Write-Verbose "Cleaning up $folder ($count of $total)"

			# Clean up any files older than retentionDate
			$removeList = Get-ChildItem $folder -File | Where-Object { $_.LastWriteTimeUtc -lt $retentionDate }
			Try {
				$removeList | Remove-Item -Force
				Write-Verbose "Removed $($removeList.fullname)`n"
			} Catch {
				Write-Error "Error occurred deleting $($removeList.fullname)"
			}

			# To reduce additional disk space, compress remaining files older than compressionDate
			$compressList = Get-ChildItem $folder -File "*.log*" | Where-Object { $_.LastWriteTimeUtc -lt $compressionDate }

			$zipList = $compressList | Group-Object { $_.LastWriteTimeUtc.ToString("yyyy-MM-dd") } | Sort-Object Name

			foreach ($fileGroup in $zipList) {

				Compress-Archive -Path $($fileGroup.group.fullname) -DestinationPath "$($folder)\$($fileGroup.name).zip" -CompressionLevel Optimal -Update

				# Verify zip file count matches fileGroup count
				$zipFile = [System.IO.Compression.ZipFile]::OpenRead("$($folder)\$($fileGroup.name).zip")

				if ($fileGroup.Count -eq $zipFile.Entries.Count) {
					Write-Verbose "ZipFile complete...removing $($fileGroup.group.fullname)"
					$fileGroup.group.fullname | Remove-Item -Force
				} else {
					Write-Error "Error occurred archiving $($fileGroup.group.fullname)"
				}
				# Close ZIP file
				$zipFile.Dispose()
			}
		}
	}

	End {}
}