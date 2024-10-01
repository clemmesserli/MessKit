Function Encrypt-File {
    <#
    .SYNOPSIS
        This Powershell function encrypts a file using a given X.509 certificate public key.
    .DESCRIPTION
        This Powershell function encrypts a file using a given X.509 certificate public key.
        This function accepts as inputs a file to encrypt and a certificate with which to encrypt it.
        This function saves the encrypted file as *.encrypted. The file can only be decrypted with the private key of the certificate that was used to encrypt it.
        You must use a certificate that can be used for encryption, and not something like a code signing certificate.
    .PARAMETER FileToEncrypt
        Must be a System.IO.FileInfo object. $(Get-ChildItem C:\file.txt) will work.
    .PARAMETER Cert
        Must be a System.Security.Cryptography.X509Certificates.X509Certificate2 object. $(Get-ChildItem Cert:\CurrentUser\My\9554F368FEA619A655A1D49408FC13C3E0D60E11) will work. The public key of the certificate is used for encryption.
    .EXAMPLE
        PS C:\> . .\Encrypt-File.ps1
        PS C:\> Encrypt-File $File $Cert
    .EXAMPLE
        PS C:\> . .\Encrypt-File.ps1
        PS C:\> Encrypt-File $(Get-ChildItem C:\foo.txt) $(Get-ChildItem Cert:\CurrentUser\My\THUMBPRINT)
    .INPUTS
        Encrypt-File <System.IO.FileInfo> <System.Security.Cryptography.X509Certificates.X509Certificate2>
    .OUTPUTS
        A file named $FileName.encrypted
    .NOTES
        Written by Ryan Ries - ryan@myotherpcisacloud.com
    .LINK
        http://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.x509certificate2.aspx
    #>
    Param(
        [Parameter(mandatory=$true)][System.IO.FileInfo]$FileToEncrypt,
        [Parameter(mandatory=$true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert
    )

    Try
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Security.Cryptography")
    }
    Catch
    {
        Write-Error "Could not load required assembly.";
        Return
    }

    $AesProvider                = New-Object System.Security.Cryptography.AesManaged
    $AesProvider.KeySize        = 256
    $AesProvider.BlockSize      = 128
    $AesProvider.Mode           = [System.Security.Cryptography.CipherMode]::CBC
    $KeyFormatter               = New-Object System.Security.Cryptography.RSAPKCS1KeyExchangeFormatter($Cert.PublicKey.Key)
    [Byte[]]$KeyEncrypted       = $KeyFormatter.CreateKeyExchange($AesProvider.Key, $AesProvider.GetType())
    [Byte[]]$LenKey             = $Null
    [Byte[]]$LenIV              = $Null
    [Int]$LKey                  = $KeyEncrypted.Length
    $LenKey                     = [System.BitConverter]::GetBytes($LKey)
    [Int]$LIV                   = $AesProvider.IV.Length
    $LenIV                      = [System.BitConverter]::GetBytes($LIV)

    $FileStreamWriter
    Try
    {
        $FileStreamWriter = New-Object System.IO.FileStream("$($FileToEncrypt.FullName)`.encrypted", [System.IO.FileMode]::Create)
    }
    Catch
    {
        Write-Error "Unable to open output file for writing.";
        Return
    }

    $FileStreamWriter.Write($LenKey,         0, 4)
    $FileStreamWriter.Write($LenIV,          0, 4)
    $FileStreamWriter.Write($KeyEncrypted,   0, $LKey)
    $FileStreamWriter.Write($AesProvider.IV, 0, $LIV)
    $Transform                  = $AesProvider.CreateEncryptor()
    $CryptoStream               = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
    [Int]$Count                 = 0
    [Int]$Offset                = 0
    [Int]$BlockSizeBytes        = $AesProvider.BlockSize / 8
    [Byte[]]$Data               = New-Object Byte[] $BlockSizeBytes
    [Int]$BytesRead             = 0

    Try
    {
        $FileStreamReader = New-Object System.IO.FileStream("$($FileToEncrypt.FullName)", [System.IO.FileMode]::Open)
    }
    Catch
    {
        Write-Error "Unable to open input file for reading.";
        Return
    }

    Do
    {
        $Count   = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
        $Offset += $Count
        $CryptoStream.Write($Data, 0, $Count)
        $BytesRead += $BlockSizeBytes
    }
    While ($Count -gt 0)

    $CryptoStream.FlushFinalBlock()
    $CryptoStream.Close()
    $FileStreamReader.Close()
    $FileStreamWriter.Close()
}
