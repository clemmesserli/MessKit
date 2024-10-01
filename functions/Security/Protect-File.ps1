Function Protect-File {
    <#
    .SYNOPSIS
        This Powershell function encrypts a file using a given X.509 certificate public key.
    .DESCRIPTION
        This Powershell function encrypts a file using a given X.509 certificate public key.
        This function accepts as inputs a file to encrypt and a certificate with which to encrypt it.
        This function saves the encrypted file as *.encrypted. The file can only be decrypted with the private key of the certificate that was used to encrypt it.
        You must use a certificate that can be used for encryption, and not something like a code signing certificate.
    .EXAMPLE
        Protect-File -FilePath ./data/SampleText.txt
    .EXAMPLE
        Protect-File -FilePath ./data/SampleText.txt -Cert $(Get-ChildItem Cert:\CurrentUser\My | Where EnhancedKeyUsageList -match 'Document Encryption')
    .NOTES
        Adapted from Ryan Ries - ryan@myotherpcisacloud.com
    #>
    Param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$FilePath,

        [Parameter()]
        [String]$FileExtension = ".encrypted",

        [Parameter()]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Cert = $(Get-ChildItem Cert:\CurrentUser\My\B93B19CCDF5ED8B96E43F06B8D1EFEB9F50F13A6)
    )

    Begin {}

    Process {
        Try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.Security.Cryptography")
        } Catch {
            Write-Error "Could not load required assembly.";
            Return
        }

        $AesProvider = New-Object System.Security.Cryptography.AesManaged
        $AesProvider.KeySize = 256
        $AesProvider.BlockSize = 128
        $AesProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $KeyFormatter = New-Object System.Security.Cryptography.RSAPKCS1KeyExchangeFormatter($Cert.PublicKey.Key)
        [Byte[]]$KeyEncrypted = $KeyFormatter.CreateKeyExchange($AesProvider.Key, $AesProvider.GetType())
        [Byte[]]$LenKey = $Null
        [Byte[]]$LenIV = $Null
        [Int]$LKey = $KeyEncrypted.Length
        $LenKey = [System.BitConverter]::GetBytes($LKey)
        [Int]$LIV = $AesProvider.IV.Length
        $LenIV = [System.BitConverter]::GetBytes($LIV)

        $FileStreamWriter
        Try {
            $FileStreamWriter = New-Object System.IO.FileStream("$($FilePath.FullName)", [System.IO.FileMode]::Create)
        } Catch {
            Write-Error "Unable to open output file for writing.";
            Return
        }

        $FileStreamWriter.Write($LenKey, 0, 4)
        $FileStreamWriter.Write($LenIV, 0, 4)
        $FileStreamWriter.Write($KeyEncrypted, 0, $LKey)
        $FileStreamWriter.Write($AesProvider.IV, 0, $LIV)
        $Transform = $AesProvider.CreateEncryptor()
        $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
        [Int]$Count = 0
        [Int]$Offset = 0
        [Int]$BlockSizeBytes = $AesProvider.BlockSize / 8
        [Byte[]]$Data = New-Object Byte[] $BlockSizeBytes
        [Int]$BytesRead = 0

        Try {
            $FileStreamReader = New-Object System.IO.FileStream("$($FilePath.FullName)", [System.IO.FileMode]::Open)
        } Catch {
            Write-Error "Unable to open input file for reading.";
            Return
        }

        Do {
            $Count = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
            $Offset += $Count
            $CryptoStream.Write($Data, 0, $Count)
            $BytesRead += $BlockSizeBytes
        }
        While ($Count -gt 0)

        # Clean-up objects to release memory
        $CryptoStream.FlushFinalBlock()
        $CryptoStream.Close()
        $FileStreamReader.Close()
        $FileStreamWriter.Close()
    }

    End {}
}
