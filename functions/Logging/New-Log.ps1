Function New-Log {
	<#
	.SYNOPSIS
		Create multiple dummy files with a random sizes and dates
	.EXAMPLE
		New-Log -FolderPath "C:\logfiles\lab04" -FileCount 20
	.EXAMPLE
		New-Log -FolderPath "C:\logfiles\demo3" -FileCount 150 -filename "w3svc"
	#>
	[CmdletBinding()]
	Param(
		[string]$FolderPath = "C:\logfiles\demo3",

		[string[]]$FileName = @("audit", "server", "transaction", "w3svc"),

		[string]$FileExt = "log",

		[ValidateRange(1, 200)]
		[int]$FileCount = 100,

		[ValidateRange(1, 365)]
		[int]$MinDayOffset = 1,

		[ValidateRange(1, 365)]
		[int]$MaxDayOffset = 365,

		[ValidateRange(1, 24)]
		[int]$MinHourOffset = 1,

		[ValidateRange(1, 24)]
		[int]$MaxHourOffset = 365,

		[ValidateRange(1, 60)]
		[int]$MinMinuteOffset = 1,

		[ValidateRange(1, 60)]
		[int]$MaxMinuteOffset = 60
	)

	Begin {
		New-Item $FolderPath -Type Directory -ErrorAction Ignore
		Set-Location $FolderPath
		$FileName | ForEach-Object { New-Item $_ -Type Directory -ErrorAction Ignore }
	}

	Process {
		For ($i = 1; $i -le $FileCount; $i++) {
			$dayOffset = (Get-Random -Minimum $MinDayOffset -Maximum $MaxDayOffset)
			$hourOffset = (Get-Random -Minimum $MinHourOffset -Maximum $MaxHourOffset)
			$minuteOffset = (Get-Random -Minimum $MinMinuteOffset -Maximum $MaxMinuteOffset)

			$fileDate = (Get-Date).AddDays(-$dayOffset).AddHours(-$hourOffset).AddMinutes(-$minuteOffset)
			$subFolder = "$(Get-Random $FileName)"
			$filePath = Join-Path -Path $FolderPath -ChildPath $subFolder -AdditionalChildPath "$($subFolder).$($fileDate.ToString("yyyyMMdd"))-$($i).$($FileExt)"

			$fileSize = Get-Random -Minimum 10KB -Maximum 200MB

			fsutil file createnew $filePath $fileSize

			# $byteArrary = New-Object -TypeName Byte[] -ArgumentList "$($fileSize)Mb"
			# $byteArrary = New-Object -TypeName Byte[] -ArgumentList 5Mb
			# $obj = New-Object -TypeName System.Random
			# $obj.NextBytes($byteArrary)
			# Set-Content -Path $filePath -Value $byteArrary -Encoding utf8

			# Finally, we are going to update file metadata to make things look more realistic
			$(Get-Item $filePath).CreationTime = $fileDate
			$(Get-Item $filePath).LastAccessTime = $fileDate
			$(Get-Item $filePath).LastWriteTime = $fileDate
		}
	}
}
