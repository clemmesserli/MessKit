<#
.SYNOPSIS
Securely deletes a file by overwriting it with random data before deletion.

.DESCRIPTION
The Remove-MKFile function implements secure file deletion by overwriting the target file with
cryptographically random data for a specified number of passes before finally deleting it.
This helps prevent data recovery using forensic tools.

For each pass, the function:
- Overwrites the file with cryptographically secure random data
- Flushes changes to disk
- Randomizes the file's timestamp metadata
- Calculates a verification hash (when verbose output is enabled)

.PARAMETER Path
The path to the file that should be securely deleted.

.PARAMETER Passes
The number of overwrite passes to perform. More passes provide increased security at the cost of time.
Default is 5 passes.

.EXAMPLE
Remove-MKFile -Path "C:\sensitive-data.txt"

Securely deletes the file using the default 5 overwrite passes.

.EXAMPLE
Remove-MKFile -Path "C:\confidential.docx" -Passes 3 -Verbose

Securely deletes the file using 3 overwrite passes and displays detailed progress information.

.EXAMPLE
Get-ChildItem "C:\Secrets\*.txt" | ForEach-Object { Remove-MKFile -Path $_.FullName -Confirm:$false }

Securely deletes all text files in the Secrets folder without prompting for confirmation.

.NOTES
The effectiveness of secure deletion may be limited on SSDs, journaling file systems,
or when snapshots/backups exist.

.LINK
Get-MKRandomDate
#>
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