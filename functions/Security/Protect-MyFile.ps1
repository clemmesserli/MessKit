function Protect-MyFile {
  <#
    .SYNOPSIS
    Encrypts a file using a specified X.509 certificate's public key.

    .DESCRIPTION
    The Protect-MyFile function encrypts a file using the public key from a specified X.509 certificate.
    It uses AES encryption with a 256-bit key size and CBC mode. The encrypted file is saved with a
    '.encrypted' extension added to the original filename.

    .PARAMETER FileToEncrypt
    Specifies the file to be encrypted. This parameter accepts a System.IO.FileInfo object.

    .PARAMETER Certificate
    Specifies the X.509 certificate to use for encryption. This parameter accepts a
    System.Security.Cryptography.X509Certificates.X509Certificate2 object. The public key of this
    certificate is used for encrypting the AES key.

    .EXAMPLE
    PS C:\> $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
    PS C:\> Get-ChildItem "C:\Certs\SecretFile.txt" | Protect-MyFile -Certificate $cert

    This example encrypts the file 'C:\Certs\SecretFile.txt' using the specified certificate.

    .INPUTS
    System.IO.FileInfo

    .OUTPUTS
    System.IO.FileInfo
    Returns a FileInfo object representing the encrypted file.

    .NOTES
    The encrypted file can only be decrypted using the private key corresponding to the certificate used for encryption.
    Ensure that you have access to this private key, or the file cannot be decrypted.

    #>

  [CmdletBinding(SupportsShouldProcess = $true)]
  [OutputType([System.IO.FileInfo])]
  Param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$FileToEncrypt,

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  Process {
    if (-not $PSCmdlet.ShouldProcess($FileToEncrypt.FullName, "Encrypt file")) {
      return
    }

    $aesProvider = $null
    $fileStreamWriter = $null
    $fileStreamReader = $null
    $cryptoStream = $null

    try {
      $aesProvider = New-Object System.Security.Cryptography.AesManaged
      $aesProvider.KeySize = 256
      $aesProvider.BlockSize = 128
      $aesProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
      $aesProvider.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

      $rsaProvider = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($Certificate)
      $encryptedKey = $rsaProvider.Encrypt($aesProvider.Key, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

      $encryptedFilePath = "$($FileToEncrypt.FullName).encrypted"
      $fileStreamWriter = New-Object System.IO.FileStream($encryptedFilePath, [System.IO.FileMode]::Create)

      $lenKey = [System.BitConverter]::GetBytes($encryptedKey.Length)
      $lenIV = [System.BitConverter]::GetBytes($aesProvider.IV.Length)

      $fileStreamWriter.Write($lenKey, 0, 4)
      $fileStreamWriter.Write($lenIV, 0, 4)
      $fileStreamWriter.Write($encryptedKey, 0, $encryptedKey.Length)
      $fileStreamWriter.Write($aesProvider.IV, 0, $aesProvider.IV.Length)

      $transform = $aesProvider.CreateEncryptor()
      $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($fileStreamWriter, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)

      $fileStreamReader = New-Object System.IO.FileStream($FileToEncrypt.FullName, [System.IO.FileMode]::Open)
      $fileStreamReader.CopyTo($cryptoStream)

      $cryptoStream.FlushFinalBlock()

      Get-Item $encryptedFilePath
    } catch {
      Write-Error "Failed to encrypt file: $_"
    } finally {
      if ($null -ne $aesProvider) { $aesProvider.Dispose() }
      if ($null -ne $fileStreamWriter) { $fileStreamWriter.Dispose() }
      if ($null -ne $fileStreamReader) { $fileStreamReader.Dispose() }
      if ($null -ne $cryptoStream) { $cryptoStream.Dispose() }
    }
  }
}