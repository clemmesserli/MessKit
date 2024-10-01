Function Compress-LogAsJob {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$FolderPath,

		[Parameter()]
		[int]$LogRetentionDays = 90,

		[Parameter()]
		[int]$ArchiveRetentionDays = 8,

		[Parameter()]
		[int]$ThrottleLimit = 12
	)

	Begin {}

	Process {
		$directoryList = [array](Get-ChildItem $FolderPath -Recurse -Directory).FullName

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

			$zipList | ForEach-Object -Parallel {
				Compress-Archive -Path $($_.group.fullname) -DestinationPath "$($using:folder)\$($_.name).zip" -CompressionLevel Optimal -Update

				#Verify zip file count matches fileGroup count
				$zipFile = [System.IO.Compression.ZipFile]::OpenRead("$($using:folder)\$($_.name).zip")

				if ($_.Count -eq $zipFile.Entries.Count) {
					Write-Verbose "ZipFile complete...removing $($_.group.fullname)"
					$_.group.fullname | Remove-Item -Force
				} else {
					Write-Error "Error occurred archiving $($_.group.fullname)"
				}
				# Close ZIP file
				$zipFile.Dispose()
			} -ThrottleLimit $ThrottleLimit
		}
	}

	End {}
}