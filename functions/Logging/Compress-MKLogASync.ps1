Function Compress-MKLogASync {
  <#
    .SYNOPSIS
        Compresses and archives log files asynchronously using PowerShell runspaces.

    .DESCRIPTION
        The Compress-MKLogASync function manages log files using asynchronous processing:
        - Removes files older than the specified retention period
        - Compresses log files into daily ZIP archives using runspaces
        - Maintains a separate retention period for archived files
        - Controls parallel processing through PoolSize and ThrottleLimit parameters
        - Provides better performance than job-based methods for large log sets

    .PARAMETER FolderPath
        The root folder path containing log files to process.
        The function will recursively process all subfolders.

    .PARAMETER LogRetentionDays
        The number of days to retain log files. Files older than this period will be deleted.
        Default value is 90 days.

    .PARAMETER ArchiveRetentionDays
        The number of days before log files are compressed into ZIP archives.
        Default value is 8 days.

    .PARAMETER PoolSize
        Maximum number of concurrent runspaces in the pool.
        Default value is 4.

    .PARAMETER ThrottleLimit
        Maximum number of concurrent compression operations per folder.
        Default value is 12.

    .EXAMPLE
        PS> Compress-MKLogASync -FolderPath "C:\Logs" -Verbose
        Processes all logs in C:\Logs with default settings using asynchronous compression

    .EXAMPLE
        PS> Compress-MKLogASync -FolderPath "C:\Logs" -LogRetentionDays 30 -ArchiveRetentionDays 7 -PoolSize 8 -ThrottleLimit 5
        Processes logs with custom retention periods, increased runspace pool size, and reduced throttle limit

    .NOTES
        File Name      : Compress-MKLogASync.ps1
        Author         : MessKit
        Requires       : PowerShell 7.0 or later (for parallel processing)
        Performance    : Uses runspace pools for most efficient compression of large log sets

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