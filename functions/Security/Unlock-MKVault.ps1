Function Unlock-MKVault {
  <#
  .SYNOPSIS
  Unlocks the Microsoft PowerShell SecretStore vault using a seed file.

  .DESCRIPTION
  The Unlock-MKVault function unlocks the Microsoft PowerShell SecretStore vault
  using a password retrieved from an encrypted seed file. The vault will remain
  unlocked for the specified timeout period (default is 8 hours/28800 seconds).

  .PARAMETER SeedFile
  Path to the encrypted file containing the vault password. If not provided,
  the path is retrieved from the configuration using Get-MyParam.

  .EXAMPLE
  Unlock-MKVault

  Unlocks the SecretStore vault using the default seed file location.

  .EXAMPLE
  Unlock-MKVault -SeedFile "C:\Secure\my-vault-seed.txt"

  Unlocks the SecretStore vault using the specified seed file.

  .NOTES
  The seed file should be properly secured and encrypted with CMS.
  The default timeout is set to 8 hours (28800 seconds).

  .LINK
  Unlock-SecretStore
  #>
  [CmdletBinding()]
  Param (
    [String]$SeedFile = (Get-MyParam).'Unlock-MKVault'.SeedFile
  )

  Process {
    $params = @{
      Password        = (ConvertTo-SecureString -AsPlainText -Force (Unprotect-CmsMessage -Path "$SeedFile" ))
      PasswordTimeout = 28800
    }
    Unlock-SecretStore @params
  }
}