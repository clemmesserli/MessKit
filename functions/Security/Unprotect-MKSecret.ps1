function Unprotect-MKSecret {
  <#
  .SYNOPSIS
  Function to decrypt a secret using a pre-shared passphrase.

  .DESCRIPTION
  This function takes a SecureString passphrase and either an encrypted string or a file path containing the encrypted content.
  It decrypts the secret using the passphrase and returns the decrypted secret as a string.

  .PARAMETER Passphrase
  The SecureString passphrase used to decrypt the secret. This must be the same passphrase used for encryption.

  .PARAMETER FilePath
  Optional. The file path containing the encrypted content. If not provided, the default path "$env:TEMP\secret.txt" is used.

  .PARAMETER Secret
  Optional. The encrypted string to decrypt. Can be provided via pipeline. Use this parameter when the secret is stored as a variable rather than in a file.

  .EXAMPLE
  $PassPhrase = Read-Host "Enter passphrase" -AsSecureString
  Unprotect-MKSecret -Passphrase $PassPhrase -FilePath "$env:TEMP\encrypted.txt"
  # Decrypts and displays the plain-text version of "$env:TEMP\encrypted.txt" using a pre-shared passphrase.

  .EXAMPLE
  $PassPhrase = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
  $MySecret = Protect-MKSecret -Secret "My super secret" -Passphrase $PassPhrase -DisplaySecret
  Unprotect-MKSecret -Secret $MySecret -Passphrase $PassPhrase
  # Shows how to encrypt a string into a variable and then decrypt it later without using the filesystem

  .EXAMPLE
  $PassPhrase = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
  $encryptedContent = Get-Content "$env:TEMP\secret.txt"
  $encryptedContent | Unprotect-MKSecret -Passphrase $PassPhrase
  # Demonstrates using the pipeline to decrypt content read from a file

  .NOTES
  Make sure to use the exact same passphrase that was used for encryption with Protect-MKSecret.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [SecureString]$Passphrase,

    [Parameter(ParameterSetName = 'FromFile')]
    [string]$FilePath,

    [Parameter(ValueFromPipeline, ParameterSetName = 'FromString')]
    [string]$Secret
  )

  begin {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Passphrase)
    $unsecurePassphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    $key = [System.Text.Encoding]::UTF8.GetBytes($unsecurePassphrase.PadRight(32).Substring(0, 32))
  }

  process {
    try {
      if ($PSCmdlet.ParameterSetName -eq 'FromFile') {
        if (-not $FilePath) {
          $FilePath = "$env:TEMP\secret.txt"
        }
        $encryptedContent = Get-Content -Path $FilePath -ErrorAction Stop
      } else {
        $encryptedContent = $Secret
      }

      $secureString = ConvertTo-SecureString -String $encryptedContent -Key $key -ErrorAction Stop
      $decryptedSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
      )
      return $decryptedSecret
    } catch {
      Write-Warning 'Failed to decrypt the secret. Make sure the passphrase is correct and the input is valid.'
      return $null
    }
  }
}