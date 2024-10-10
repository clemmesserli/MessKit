function Get-MKStringHash {
  <#
  .SYNOPSIS
  Convert a string into a hash

  .DESCRIPTION
  Convert a string into a hash using a memory stream rather than wasting time saving to file and then using Get-FileHash.
  A hash is a way to uniquely identify text without exposing the actual text.
  Hashes are used to identify strings of text, find duplicate file content, and validate passwords.

  .EXAMPLE
  $fileContent = Get-Content -Raw $filePath
  $hash = Get-MKStringHash $fileContent
  # Store or compare this hash for simple file integrity checking

  .EXAMPLE
  $string1 = Get-MKStringHash 'The Quick Brown Fox.'
  $string2 = Get-MKStringHash 'the quick brown fox.'
  Compare-Object $string1.hash $string2.hash

  .EXAMPLE
  $strings = @("Hello World", "Hello world", "Hello World", "Different text")
  $uniqueStrings = $strings | Get-MKStringHash | Sort-Object Hash -Unique
  This helps identify unique strings regardless of small differences in capitalization.

  .EXAMPLE
  $passwordHash = Get-MKStringHash -String "P@sswordL3ss!"
  Store $passwordHash.Hash in a database instead of the actual password

  .EXAMPLE
  $longText = "This is a very long piece of text..."
  $uniqueId = (Get-MKStringHash $longText).Hash.Substring(0, 10)
  This creates a shorter, unique identifier for a longer piece of text.

  # Without salt (same as before)
  Get-MKStringHash -String "MyPassword123"

  # With salt
  Get-MKStringHash -String "MyPassword123" -UseSalt

  # With salt and custom algorithm
  Get-MKStringHash -String "MyPassword123" -UseSalt -Algorithm SHA512

  # With salt and custom salt length
  Get-MKStringHash -String "MyPassword123" -UseSalt -SaltLength 32 | format-list
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]$String,

    [Parameter()]
    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [string]$Algorithm = 'SHA256',

    [Parameter()]
    [switch]$UseSalt,

    [Parameter()]
    [int]$SaltLength = 16
  )

  process {

    $salt = if ($UseSalt) {
      $saltBytes = New-Object byte[] $SaltLength
      $rng = [Security.Cryptography.RNGCryptoServiceProvider]::new()
      $rng.GetBytes($saltBytes)
      $rng.Dispose()
      [Convert]::ToBase64String($saltBytes)
    } else { "" }

    $saltedString = $String + $salt
    $bytes = [Text.Encoding]::UTF8.GetBytes($saltedString)
    $hashAlgorithm = [Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $hashBytes = $hashAlgorithm.ComputeHash($bytes)

    [PSCustomObject]@{
      Algorithm = $Algorithm
      Salt      = $salt
      Hash      = [BitConverter]::ToString($hashBytes).Replace('-', '')
    }
  }
}
