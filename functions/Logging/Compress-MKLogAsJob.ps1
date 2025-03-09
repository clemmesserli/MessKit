Function Compress-MKLogAsJob {
  <#
    .SYNOPSIS
        Compresses and archives log files in parallel using PowerShell jobs.

    .DESCRIPTION
        The Compress-MKLogAsJob function manages log files using parallel processing:
        - Removes files older than the specified retention period
        - Compresses log files into daily ZIP archives using parallel jobs
        - Maintains a separate retention period for archived files
        - Controls parallel processing through ThrottleLimit parameter

    .PARAMETER FolderPath
        The root folder path containing log files to process.
        The function will recursively process all subfolders.

    .PARAMETER LogRetentionDays
        The number of days to retain log files. Files older than this period will be deleted.
        Default value is 90 days.

    .PARAMETER ArchiveRetentionDays
        The number of days before log files are compressed into ZIP archives.
        Default value is 8 days.

    .PARAMETER ThrottleLimit
        Maximum number of concurrent compression jobs allowed.
        Default value is 12.

    .EXAMPLE
        PS> Compress-MKLogAsJob -FolderPath "C:\Logs" -Verbose
        Processes all logs in C:\Logs with default settings using parallel compression

    .EXAMPLE
        PS> Compress-MKLogAsJob -FolderPath "C:\Logs" -LogRetentionDays 30 -ArchiveRetentionDays 7 -ThrottleLimit 8
        Processes logs with custom retention periods and reduced parallel job limit

    .NOTES
        File Name      : Compress-MKLogAsJob.ps1
        Author         : MessKit
        Requires       : PowerShell 7.0 or later (for parallel processing)
        Performance    : Uses parallel processing for faster compression of large log sets

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
      $compressList = Get-ChildItem $folder -File '*.log*' | Where-Object { $_.LastWriteTimeUtc -lt $compressionDate }

      $zipList = $compressList | Group-Object { $_.LastWriteTimeUtc.ToString('yyyy-MM-dd') } | Sort-Object Name

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