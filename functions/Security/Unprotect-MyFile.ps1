function Unprotect-MyFile {
  <#
  .SYNOPSIS
  Decrypts a file that was encrypted using the Protect-MyFile function.

  .DESCRIPTION
  The Unprotect-MyFile function decrypts files that were previously encrypted using the Protect-MyFile function.
  It supports both AES and RSA encryption methods, with options for different modes of operation and padding schemes.

  .PARAMETER Certificate
  Specifies the X509Certificate2 object containing the private key used for decryption.

  .PARAMETER EncryptionMethod
  Specifies the encryption method used. Valid values are "AES" (default) and "RSA".

  .PARAMETER FilePath
  Specifies the file to be decrypted. This parameter accepts pipeline input.

  .PARAMETER Base64
  Switch to enable additional base64 decoding prior to decrypting the file.

  .PARAMETER DeleteOriginal
  Switch to delete the original file after successful decryption.

  .EXAMPLE
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  UnProtect-MyFile -Certificate $cert -FilePath "C:\Certs\SecretFile.enc"
  Description: Decrypts the file "SecretFile.enc" using default values (AES256 + GCM)

  .EXAMPLE
  Unprotect-MyFile -Certificate $cert -FilePath "C:\Certs\SecretFile2.enc"
  Description: Decrypts the file "SecretFile.enc" using custom values (AES128 + CBC) which are stored as part of the encryption process.

  .EXAMPLE
  Unprotect-MyFile -Certificate $cert -FilePath "C:\Certs\SecretFile.enc" -Base64 -DeleteOriginal
  Description: This example decrypts a Base64 encoded file and deletes the original encrypted file after successful decryption.

  .EXAMPLE
  Get-ChildItem "C:\Certs\*.enc" | Unprotect-MyFile -Certificate $cert -Base64 -EncryptionMethod RSA
  Description: This example decrypts all .enc files in the specified directory using RSA decryption.

  .EXAMPLE
  Get-ChildItem "C:\Certs\*.enc" | UnProtect-MyFile -Base64 -Certificate $cert -DeleteOriginal
  Description: Decodes and Decrypts all files ending "*.enc" within specified directory before deleting the original input file.

  .EXAMPLE
  UnProtect-MyFile -FilePath "C:\Certs\MoreSecrets.enc" -Certificate $cert -FileExtension "csv"
  Description: Decrypts and sets file extension to .csv instead of .txt (default)

  .INPUTS
  System.IO.FileInfo
  You can pipe a FileInfo object to Unprotect-MyFile.

  .OUTPUTS
  System.IO.FileInfo
  Returns a FileInfo object representing the decrypted file.

  .NOTES
  The function requires appropriate permissions to read the encrypted file and write the decrypted file.
  Ensure that the correct certificate with the private key is used for decryption.
  #>
  [CmdletBinding(SupportsShouldProcess = $true)]
  [OutputType([System.IO.FileInfo])]
  Param (
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter()]
    [ValidateSet("AES", "RSA")]
    [string]$EncryptionMethod = "AES",

    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [System.IO.FileInfo]$FilePath,

    [Parameter()]
    [ValidateSet("csv", "txt", "ps1")]
    [string]$FileExtension = "txt",

    [switch]$Base64,

    [switch]$DeleteOriginal
  )

  Process {
    if (-not $PSCmdlet.ShouldProcess($FilePath.FullName, "Decrypt file")) {
      return
    }

    $fileStreamReader = $memoryStream = $null

    try {
      if ($FilePath.Extension -ne ".enc") {
        throw "The file to decrypt must have a .enc extension."
      }

      if (-not $Certificate.HasPrivateKey) {
        throw "The supplied certificate does not contain a private key."
      }

      $fileStreamReader = [System.IO.File]::Open($FilePath.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

      if ($Base64) {
        $base64Content = [System.IO.File]::ReadAllText($FilePath.FullName)
        $encryptedBytes = [Convert]::FromBase64String($base64Content)
        $memoryStream = [System.IO.MemoryStream]::new($encryptedBytes)
        $memoryStream.Position = 0  # Reset the stream position
      } else {
        $memoryStream = $fileStreamReader
      }

      $decryptedFilePath = $FilePath.FullName -replace "\.enc$", ".$FileExtension"
      $fileStreamWriter = [System.IO.File]::Create($decryptedFilePath)

      $rsaProvider = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)

      if ($EncryptionMethod -eq "RSA") {
        Write-Verbose "RSA w/ OAEP"
        Write-Verbose "Decryption key size: $($rsaProvider.KeySize) bits"

        $paddingModes = @(
          [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256,
          [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA1,
          [System.Security.Cryptography.RSAEncryptionPadding]::Pkcs1
        )

        while ($memoryStream.Position -lt $memoryStream.Length) {
          $buffer = New-Object byte[] 4
          $bytesRead = $memoryStream.Read($buffer, 0, 4)
          Write-Verbose "Bytes read for length: $bytesRead"

          [int]$encryptedDataLength = [System.BitConverter]::ToInt32($buffer, 0)
          Write-Verbose "Encrypted data length: $encryptedDataLength"

          $encryptedData = New-Object byte[] $encryptedDataLength
          $bytesRead = $memoryStream.Read($encryptedData, 0, $encryptedDataLength)
          Write-Verbose "Bytes read for encrypted data: $bytesRead"

          $decryptedData = $null
          $decryptionSuccessful = $false

          foreach ($padding in $paddingModes) {
            try {
              if ($encryptedDataLength -eq 512 -and $rsaProvider.KeySize -eq 2048) {
                # Split the 512-byte block into two 256-byte blocks
                $firstHalf = $encryptedData[0..255]
                $secondHalf = $encryptedData[256..511]

                $decryptedFirstHalf = $rsaProvider.Decrypt($firstHalf, $padding)
                $decryptedSecondHalf = $rsaProvider.Decrypt($secondHalf, $padding)

                $decryptedData = $decryptedFirstHalf + $decryptedSecondHalf
              } else {
                $decryptedData = $rsaProvider.Decrypt($encryptedData, $padding)
              }

              $decryptionSuccessful = $true
              Write-Verbose "Decryption successful using padding: $($padding.ToString())"
              break
            } catch {
              Write-Verbose "Decryption failed with padding $($padding.ToString()): $_"
            }
          }

          if (-not $decryptionSuccessful) {
            Write-Error "Failed to decrypt block with any padding mode"
            return
          }

          $null = $fileStreamWriter.Write($decryptedData, 0, $decryptedData.Length)
          Write-Verbose "Successfully wrote decrypted data of length: $($decryptedData.Length)"
        }
      } elseif ($EncryptionMethod -eq "AES") {
        $lenKey = New-Object byte[] 4
        [void]$memoryStream.Read($lenKey, 0, 4)
        [int]$keyLength = [System.BitConverter]::ToInt32($lenKey, 0)

        $keyEncrypted = New-Object byte[] $keyLength
        [void]$memoryStream.Read($keyEncrypted, 0, $keyLength)

        $keyDecrypted = $rsaProvider.Decrypt($keyEncrypted, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
        $aesModeIndicator = $memoryStream.ReadByte()

        if ($aesModeIndicator -notin (0, 1)) {
          Write-Error "Invalid AES mode indicator. Valid values are 0 or 1."
          return
        }

        switch ($aesModeIndicator) {
          0 {
            Write-Verbose "AES-CBC"
            $aesProvider = [System.Security.Cryptography.Aes]::Create()
            $aesProvider.Key = $keyDecrypted
            $aesProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
            $aesProvider.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

            $iv = New-Object byte[] 16
            [void]$memoryStream.Read($iv, 0, 16)
            $aesProvider.IV = $iv

            $transform = $aesProvider.CreateDecryptor()
            $cryptoStream = [System.Security.Cryptography.CryptoStream]::new($memoryStream, $transform, [System.Security.Cryptography.CryptoStreamMode]::Read)

            $cryptoStream.CopyTo($fileStreamWriter)
          }
          1 {
            Write-Verbose "AES-GCM"
            $aesGcm = [System.Security.Cryptography.AesGcm]::new($keyDecrypted)
            $nonce = New-Object byte[] 12
            $tag = New-Object byte[] 16
            [void]$memoryStream.Read($nonce, 0, 12)

            $ciphertext = New-Object byte[] ($memoryStream.Length - $memoryStream.Position - 16)
            [void]$memoryStream.Read($ciphertext, 0, $ciphertext.Length)
            [void]$memoryStream.Read($tag, 0, 16)

            $plaintext = New-Object byte[] $ciphertext.Length
            $aesGcm.Decrypt($nonce, $ciphertext, $tag, $plaintext)

            $null = $fileStreamWriter.Write($plaintext, 0, $plaintext.Length)
          }
        }
      }

      $fileStreamWriter.Close()

      Get-Item $decryptedFilePath
    } catch {
      Write-Error "Failed to decrypt file: $_"
    } finally {
      if ($null -ne $aesProvider) { $aesProvider.Dispose() }
      if ($null -ne $memoryStream -and $memoryStream -ne $fileStreamReader) { $memoryStream.Dispose() }
      if ($null -ne $fileStreamReader) { $fileStreamReader.Dispose() }
      if ($null -ne $fileStreamWriter) { $fileStreamWriter.Dispose() }
      if ($null -ne $cryptoStream) { $cryptoStream.Dispose() }

      if ($DeleteOriginal) {
        Remove-Item $FilePath.FullName -Force
      }
    }
  }
}