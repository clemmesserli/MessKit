function Unprotect-MyFile {
  <#
    .SYNOPSIS
    Decrypts a file that was encrypted using the Protect-File function.

    .DESCRIPTION
    The Unprotect-MyFile function decrypts a file that was previously encrypted using the Protect-File function.
    It requires the X.509 certificate with the private key that corresponds to the public key used for encryption.
    The function removes the '.encrypted' extension from the decrypted file.

    .PARAMETER FileToDecrypt
    Specifies the encrypted file to be decrypted. This parameter accepts a System.IO.FileInfo object.
    The file should have a '.encrypted' extension.

    .PARAMETER Certificate
    Specifies the X.509 certificate to use for decryption. This parameter accepts a
    System.Security.Cryptography.X509Certificates.X509Certificate2 object. The private key of this
    certificate is used for decrypting the AES key.

    .EXAMPLE
    PS C:\> $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
    PS C:\> Get-ChildItem "C:\Certs\SecretFile.txt.encrypted" | Unprotect-MyFile -Certificate $cert

    This example decrypts the file 'C:\Certs\SecretFile.txt.encrypted' using the specified certificate.

    .INPUTS
    System.IO.FileInfo

    .OUTPUTS
    System.IO.FileInfo
    Returns a FileInfo object representing the decrypted file.

    .NOTES
    The function will only work with files encrypted using the corresponding Protect-File function.
    The certificate used must have the private key available, or decryption will fail.
    #>

  [CmdletBinding(SupportsShouldProcess = $true)]
  [OutputType([System.IO.FileInfo])]
  Param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$FileToDecrypt,

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  Process {
    if (-not $PSCmdlet.ShouldProcess($FileToDecrypt.FullName, "Decrypt file")) {
      return
    }

    $aesProvider = $null
    $fileStreamReader = $null
    $fileStreamWriter = $null
    $cryptoStream = $null

    try {
      if ($FileToDecrypt.Extension -ne ".encrypted") {
        throw "The file to decrypt must have a .encrypted extension."
      }

      if (-not $Certificate.HasPrivateKey) {
        throw "The supplied certificate does not contain a private key."
      }

      $fileStreamReader = New-Object System.IO.FileStream($FileToDecrypt.FullName, [System.IO.FileMode]::Open)

      $lenKey = New-Object byte[] 4
      $lenIV = New-Object byte[] 4

      $fileStreamReader.Read($lenKey, 0, 4)
      $fileStreamReader.Read($lenIV, 0, 4)

      [int]$keyLength = [System.BitConverter]::ToInt32($lenKey, 0)
      [int]$ivLength = [System.BitConverter]::ToInt32($lenIV, 0)

      $keyEncrypted = New-Object byte[] $keyLength
      $iv = New-Object byte[] $ivLength

      $fileStreamReader.Read($keyEncrypted, 0, $keyLength)
      $fileStreamReader.Read($iv, 0, $ivLength)

      $rsaProvider = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
      $keyDecrypted = $rsaProvider.Decrypt($keyEncrypted, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

      $aesProvider = New-Object System.Security.Cryptography.AesManaged
      $aesProvider.Key = $keyDecrypted
      $aesProvider.IV = $iv
      $aesProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
      $aesProvider.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

      $transform = $aesProvider.CreateDecryptor()

      $decryptedFilePath = $FileToDecrypt.FullName -replace '\.encrypted$', ''
      $fileStreamWriter = New-Object System.IO.FileStream($decryptedFilePath, [System.IO.FileMode]::Create)

      $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($fileStreamWriter, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)

      $fileStreamReader.CopyTo($cryptoStream)

      $cryptoStream.FlushFinalBlock()

      Get-Item $decryptedFilePath
    } catch {
      Write-Error "Failed to decrypt file: $_"
    } finally {
      if ($null -ne $aesProvider) { $aesProvider.Dispose() }
      if ($null -ne $fileStreamReader) { $fileStreamReader.Dispose() }
      if ($null -ne $fileStreamWriter) { $fileStreamWriter.Dispose() }
      if ($null -ne $cryptoStream) { $cryptoStream.Dispose() }
    }
  }
}