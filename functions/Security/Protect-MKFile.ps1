﻿function Protect-MKFile {
  <#
  .SYNOPSIS
  Function to encrypt a file using AES or RSA encryption methods with different modes and options.

  .DESCRIPTION
  This function takes a file to encrypt, a certificate, and various encryption options to encrypt the file using AES or RSA encryption methods.
  It supports AES modes CBC and GCM, different key sizes, base64 encoding, and deleting the original file after encryption.

  The encrypted file will be saved with the same name as the original file but with a .enc extension.

  .PARAMETER FilePath
  The file to be encrypted.

  .PARAMETER EncryptionMethod
  Specifies the encryption method to use, either AES (Default) or RSA.

  .PARAMETER AESKeySize
  Specifies the key size of 128, 192, 256 (Default) for AES encryption.

  .PARAMETER RSAKeySize
  Specifies the key size of 1024, 2048 (Default), 4096 for RSA encryption.

  .PARAMETER AESMode
  Specifies the AES mode to use, either CBC or GCM (Default).

  .PARAMETER Certificate
  The X.509 certificate used for encryption. This certificate should have a public key that can be used for encryption.

  .PARAMETER Base64
  Switch to enable additional base64 encoding of the encrypted file.

  .PARAMETER DeleteOriginal
  Switch to delete the original file after successful encryption.

  .OUTPUTS
  System.IO.FileInfo
  Returns a FileInfo object representing the encrypted file.

  .EXAMPLE
  $cert = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.EnhancedKeyUsageList -match 'Document Encryption' } |
      Select-Object -First 1
  Protect-MKFile -Certificate $cert -FilePath "C:\Certs\SecretFile.txt"

  Encrypts the file "SecretFile.txt" using default values (AES256 + GCM).

  .EXAMPLE
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  Protect-MKFile -Certificate $cert -FilePath "C:\Certs\SecretFile2.txt" -AESMode CBC -AESKeySize 128

  Encrypts the file "SecretFile2.txt" using AES128 + CBC.

  .EXAMPLE
  Protect-MKFile -Certificate $cert -FilePath "C:\Certs\SecretFile.txt" -Base64 -EncryptionMethod RSA -RSAKeySize 1024

  Encrypts the file "SecretFile.txt" using RSA encryption algorithm with a 1024 bit keysize and then adds base64 encoding.

  .EXAMPLE
  Get-ChildItem "C:\LabSources\SampleData\ICOD" | Protect-MKFile -Base64 -Certificate $cert -DeleteOriginal

  Encrypts all files in the specified directory using default encryption (AES256 + GCM), adds base64 encoding,
  and deletes the original input files.

  .EXAMPLE
  Protect-MKFile -FilePath "C:\Certs\MoreSecrets.csv" -Certificate $cert -DeleteOriginal

  Encrypts the csv file using default encryption (AES256 + GCM) and deletes the original.

  .NOTES
  Adapted from Ryan Ries - ryan@myotherpcisacloud.com

  For AES encryption, the function encrypts the AES key using the certificate's RSA public key,
  and then uses the AES key to encrypt the actual file content.

  RSA encryption is limited by key size and can only encrypt small amounts of data at a time.
  #>
  [CmdletBinding(SupportsShouldProcess = $true)]
  [OutputType([System.IO.FileInfo])]
  Param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$FilePath,

    [Parameter()]
    [ValidateSet('AES', 'RSA')]
    [string]$EncryptionMethod = 'AES',

    [Parameter()]
    [ValidateSet(128, 192, 256)]
    [int]$AESKeySize = 256,

    [Parameter()]
    [ValidateSet(1024, 2048, 4096)]
    [int]$RSAKeySize = 2048,

    [Parameter()]
    [ValidateSet('CBC', 'GCM')]
    [string]$AESMode = 'GCM',

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [switch]$Base64,

    [switch]$DeleteOriginal
  )

  process {
    if (-not $PSCmdlet.ShouldProcess($FilePath.FullName, 'Encrypt file')) {
      return
    }

    $encryptedFilePath = "$($FilePath.DirectoryName)\$($FilePath.BaseName).enc"
    $fileStreamReader = $fileStreamWriter = $cryptoStream = $null

    try {
      # Use FileStream with FileAccess.Read to ensure no other process can write to it simultaneously
      $fileStreamReader = [System.IO.File]::Open($FilePath.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
      $fileStreamWriter = [System.IO.File]::Create($encryptedFilePath)

      if ($EncryptionMethod -eq 'AES') {
        $aesProvider = [System.Security.Cryptography.Aes]::Create()
        $aesProvider.KeySize = $AESKeySize
        $aesProvider.BlockSize = 128
        $aesProvider.GenerateKey()  # Ensure key is generated

        $rsaProvider = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($Certificate)
        $encryptedKey = $rsaProvider.Encrypt($aesProvider.Key, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

        $lenKey = [System.BitConverter]::GetBytes($encryptedKey.Length)
        $fileStreamWriter.Write($lenKey, 0, 4)
        $fileStreamWriter.Write($encryptedKey, 0, $encryptedKey.Length)
        $fileStreamWriter.WriteByte([byte](if ($AESMode -eq 'GCM') { 1 } else { 0 }))  # Write AES mode indicator

        if ($AESMode -eq 'GCM') {
          $aesGcm = [System.Security.Cryptography.AesGcm]::new($aesProvider.Key)
          $nonce = New-Object byte[] 12
          $tag = New-Object byte[] 16
          [System.Security.Cryptography.RandomNumberGenerator]::Fill($nonce)
          $fileStreamWriter.Write($nonce, 0, $nonce.Length)

          $buffer = New-Object byte[] 1048576  # 1 MB buffer
          $bytesRead = 0
          while (($bytesRead = $fileStreamReader.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $ciphertext = New-Object byte[] $bytesRead
            $aesGcm.Encrypt($nonce, $buffer[0..($bytesRead - 1)], $ciphertext, $tag, $null)
            $fileStreamWriter.Write($ciphertext, 0, $ciphertext.Length)
          }
          $fileStreamWriter.Write($tag, 0, $tag.Length)
        } else {
          # CBC mode
          $aesProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
          $aesProvider.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
          $aesProvider.GenerateIV()  # Ensure IV is generated
          $fileStreamWriter.Write($aesProvider.IV, 0, $aesProvider.IV.Length)

          $transform = $aesProvider.CreateEncryptor()
          $cryptoStream = [System.Security.Cryptography.CryptoStream]::new($fileStreamWriter, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
          $fileStreamReader.CopyTo($cryptoStream)
          $cryptoStream.FlushFinalBlock()
        }
      } elseif ($EncryptionMethod -eq 'RSA') {
        $rsaProvider = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($Certificate)
        Write-Verbose "RSA Key Size: $($rsaProvider.KeySize) bits"

        # Calculate the maximum data size that can be encrypted
        $maxDataSize = $rsaProvider.KeySize / 8 - 42  # For OAEP with SHA-256

        $buffer = New-Object byte[] $maxDataSize
        $bytesRead = 0

        while (($bytesRead = $fileStreamReader.Read($buffer, 0, $buffer.Length)) -gt 0) {
          $dataToEncrypt = $buffer[0..($bytesRead - 1)]
          $encryptedData = $rsaProvider.Encrypt($dataToEncrypt, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

          $lenEncryptedData = [System.BitConverter]::GetBytes($encryptedData.Length)
          $fileStreamWriter.Write($lenEncryptedData, 0, 4)
          $fileStreamWriter.Write($encryptedData, 0, $encryptedData.Length)
        }
      }

      if ($Base64) {
        $fileStreamWriter.Close()
        $base64String = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($encryptedFilePath))
        [System.IO.File]::WriteAllText($encryptedFilePath, $base64String)
      }

      Get-Item $encryptedFilePath
    } catch {
      Write-Error "Failed to encrypt file: $_"
    } finally {
      if ($null -ne $aesProvider) { $aesProvider.Dispose() }
      if ($null -ne $fileStreamReader) { $fileStreamReader.Dispose() }
      if ($null -ne $fileStreamWriter) { $fileStreamWriter.Dispose() }
      if ($null -ne $cryptoStream) { $cryptoStream.Dispose() }

      if ($DeleteOriginal) {
        Remove-Item $FilePath.FullName -Force
      }
    }
  }
}
