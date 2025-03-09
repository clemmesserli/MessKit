Function Compress-MKLog {
  <#
  .SYNOPSIS
    Compresses and archives log files while managing retention periods.

  .DESCRIPTION
    The Compress-MKLog function manages log files by:
    - Removing files older than the specified retention period
    - Compressing log files into daily ZIP archives
    - Maintaining a separate retention period for archived files

  .PARAMETER FolderPath
    The root folder path containing log files to process. The function will recursively process all subfolders.

  .PARAMETER LogRetentionDays
    The number of days to retain log files. Files older than this period will be deleted.
    Default value is 90 days.

  .PARAMETER ArchiveRetentionDays
    The number of days before log files are compressed into ZIP archives.
    Default value is 8 days.

  .EXAMPLE
    PS> Compress-MKLog -FolderPath "C:\Logs" -Verbose
    Processes all logs in C:\Logs with default retention periods (90 days for logs, 8 days for compression)

  .EXAMPLE
    PS> Compress-MKLog -FolderPath "C:\Logs" -LogRetentionDays 30 -ArchiveRetentionDays 7
    Processes logs with 30-day retention and 7-day compression threshold

  .NOTES
    File Name      : Compress-MKLog.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later

  .LINK
    https://github.com/MyGitHub/MessKit
  #>
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
      $compressList = Get-ChildItem $folder -File '*.log*' | Where-Object { $_.LastWriteTimeUtc -lt $compressionDate }

      $zipList = $compressList | Group-Object { $_.LastWriteTimeUtc.ToString('yyyy-MM-dd') } | Sort-Object Name

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