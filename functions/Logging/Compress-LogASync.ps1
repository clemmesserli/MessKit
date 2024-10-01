Function Compress-LogASync {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$FolderPath,

		[Parameter()]
		[int]$LogRetentionDays = 90,

		[Parameter()]
		[int]$ArchiveRetentionDays = 8,

		[Parameter()]
		[int]$PoolSize = 4,

		[Parameter()]
		[int]$ThrottleLimit = 12
	)

	Begin {
		$currentDate = Get-Date
		$retentionDate = $currentDate.AddDays("-$($LogRetentionDays)")
		$compressionDate = $currentDate.AddDays("-$($ArchiveRetentionDays)")
	}

	Process {
		$scriptBlock = {
			Param (
				$folder,
				$retentionDate,
				$compressionDate
			)

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

		$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $PoolSize)
		$RunspacePool.Open()
		$Jobs = @()

		$directoryList = [array](Get-ChildItem $FolderPath -Recurse -Directory).FullName
		$directoryList | ForEach-Object {
			$PowerShell = [powershell]::Create()
			$PowerShell.RunspacePool = $RunspacePool
			$PowerShell.AddScript($ScriptBlock).AddArgument($_).AddArgument($retentionDate).AddArgument($compressionDate)
			$Jobs += $PowerShell.BeginInvoke()
		}
		while ($Jobs.IsCompleted -contains $false) { Start-Sleep -Milliseconds 100 }

		$RunspacePool.Close()
		$RunspacePool.Dispose()
	}

	End {}
}