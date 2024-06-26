function Unprotect-MySecret {
  <#
  .SYNOPSIS
  Decrypts a secret using a passphrase from a file.

  .DESCRIPTION
  This function reads an encrypted secret from a file, decrypts it using the provided secure passphrase,
  and returns the decrypted secret.

  .PARAMETER Passphrase
  The passphrase used for decryption, as a SecureString. It must match the passphrase used for encryption.

  .PARAMETER InputPath
  The path to the file containing the encrypted secret. Defaults to a file named 'secret.txt' in the temp directory.

  .EXAMPLE
  $securePass = Read-Host "Enter passphrase" -AsSecureString
  $secret = Unprotect-MySecret -Passphrase $securePass
  Write-Host "The secret is: $secret"

  .EXAMPLE
  $securePass = ConvertTo-SecureString "My secure passphrase" -AsPlainText -Force
  $secret = Unprotect-MySecret -Passphrase $securePass -InputPath "C:\Secrets\encrypted.txt"

  .EXAMPLE
  $securePass = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
  $secret = Unprotect-MySecret -Passphrase $securePass -InputPath "$env:TEMP\secret.txt"

  .NOTES
  If decryption fails (e.g., due to an incorrect passphrase), the function returns $null and displays a warning.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [SecureString]$Passphrase,

    [Parameter(Mandatory = $false)]
    [string]$InputPath = "$env:TEMP\secret.txt"
  )

  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Passphrase)
  $unsecurePassphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

  $key = [System.Text.Encoding]::UTF8.GetBytes($unsecurePassphrase.PadRight(32).Substring(0, 32))

  try {
    $encryptedContent = Get-Content -Path $InputPath -ErrorAction Stop
    $secureString = ConvertTo-SecureString -String $encryptedContent -Key $key -ErrorAction Stop
    $decryptedSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
      [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    )
    return $decryptedSecret
  } catch {
    Write-Warning "Failed to decrypt the secret. Make sure the passphrase is correct."
    return $null
  }
}