Function New-MKLog {
  <#
  .SYNOPSIS
    Creates multiple dummy log files with random sizes and dates for testing purposes.

  .DESCRIPTION
    The New-MKLog function generates test log files by:
    - Creating the specified number of randomly sized log files
    - Distributing files across multiple subfolders based on specified filenames
    - Setting realistic file creation and modification dates
    - Varying file sizes to simulate actual log files
    This is useful for testing log management, compression, and archival functions.

  .PARAMETER FolderPath
    The root folder path where log files will be created. Subfolders will be automatically generated.
    Default value is 'C:\logfiles\demo3'.

  .PARAMETER FileName
    An array of names to use for both subfolders and the base filename of generated logs.
    Default values are 'audit', 'server', 'transaction', and 'w3svc'.

  .PARAMETER FileExt
    The file extension to use for the generated log files.
    Default value is 'log'.

  .PARAMETER FileCount
    The number of log files to generate.
    Default value is 100, with a valid range of 1-200.

  .PARAMETER MinDayOffset
    The minimum number of days in the past for randomizing file dates.
    Default value is 1, with a valid range of 1-365.

  .PARAMETER MaxDayOffset
    The maximum number of days in the past for randomizing file dates.
    Default value is 365, with a valid range of 1-365.

  .PARAMETER MinHourOffset
    The minimum number of hours to subtract when randomizing file times.
    Default value is 1, with a valid range of 1-24.

  .PARAMETER MaxHourOffset
    The maximum number of hours to subtract when randomizing file times.
    Default value is 365 (should probably be 24), with a valid range of 1-24.

  .PARAMETER MinMinuteOffset
    The minimum number of minutes to subtract when randomizing file times.
    Default value is 1, with a valid range of 1-60.

  .PARAMETER MaxMinuteOffset
    The maximum number of minutes to subtract when randomizing file times.
    Default value is 60, with a valid range of 1-60.

  .EXAMPLE
    PS> New-MKLog -FolderPath "C:\logfiles\lab04" -FileCount 20
    Creates 20 log files distributed across subfolders in the C:\logfiles\lab04 directory.

  .EXAMPLE
    PS> New-MKLog -FolderPath "C:\logfiles\demo3" -FileCount 150 -FileName "w3svc"
    Creates 150 log files in a subfolder named 'w3svc' all with the base filename of 'w3svc'.

  .EXAMPLE
    PS> New-MKLog -MaxDayOffset 30 -FileExt "txt" -MinHourOffset 5 -MaxHourOffset 20
    Creates 100 .txt files with dates ranging from 1-30 days in the past and times between 5-20 hours offset.

  .NOTES
    File Name      : New-MKLog.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later
    Purpose        : Creates test data for demonstration and validation of log management functions

  .LINK
    https://github.com/MyGitHub/MessKit
  #>
  [CmdletBinding()]
  Param(
    [string]$FolderPath = 'C:\logfiles\demo3',

    [string[]]$FileName = @('audit', 'server', 'transaction', 'w3svc'),

    [string]$FileExt = 'log',

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
      $filePath = Join-Path -Path $FolderPath -ChildPath $subFolder -AdditionalChildPath "$($subFolder).$($fileDate.ToString('yyyyMMdd'))-$($i).$($FileExt)"

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
