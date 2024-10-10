function Unprotect-MKSecret {
  <#
  .SYNOPSIS
  Function to decrypt a secret using a pre-shared passphrase.

  .DESCRIPTION
  This function takes a SecureString passphrase and either an encrypted string or a file path containing the encrypted content.
  It decrypts the secret using the passphrase and returns the decrypted secret as a string.

  .PARAMETER Passphrase
  The SecureString passphrase used to decrypt the secret.

  .PARAMETER FilePath
  Optional. The file path containing the encrypted content. If not provided, a default path is used.

  .PARAMETER Secret
  Optional. The encrypted string to decrypt. Can be provided via pipeline.

  .EXAMPLE
  $PassPhrase = Read-Host "Enter passphrase" -AsSecureString
  Unprotect-MKSecret -Passphrase $PassPhrase -FilePath "$env:tmp\encrypted.txt"
  Decrypts and displays the plain-text version of "$env:tmp\encrypted.txt" using a pre-shared passphrase.

  .EXAMPLE
  $PassPhrase = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
  $MySecret = Protect-MySecret -Secret "My super secret" -Passphrase $PassPhrase -DisplaySecret
  Unprotect-MKSecret -Secret $MySecret -Passphrase $PassPhrase
  Shows how one might store into a variable and then re-populate later without use of filesystem
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [SecureString]$Passphrase,

    [Parameter(ParameterSetName = "FromFile")]
    [string]$FilePath,

    [Parameter(ValueFromPipeline, ParameterSetName = "FromString")]
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
      if ($PSCmdlet.ParameterSetName -eq "FromFile") {
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
      Write-Warning "Failed to decrypt the secret. Make sure the passphrase is correct and the input is valid."
      return $null
    }
  }
}