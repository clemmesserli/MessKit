function Test-MKStringHash {
  <#
  .SYNOPSIS
  Takes an input string and compares its hash to one already stored in a lookup database or secrets vault

  .DESCRIPTION
  This function takes an input string, a stored hash, and a stored salt, then verifies
  if the input password matches the original password that generated the stored hash.
  It's designed to work in conjunction with the Get-MKStringHash function.

  .PARAMETER String
  The password to be verified.

  .PARAMETER StoredHash
  The previously generated hash to compare against.

  .PARAMETER StoredSalt
  The salt used when generating the stored hash.

  .PARAMETER Algorithm
  The hashing algorithm to use. Should match the algorithm used to generate the stored hash.
  Valid options are SHA256, SHA384, and SHA512. Default is SHA256.

  .EXAMPLE
  $storedData = Get-MKStringHash -String "MyPassword123" -UseSalt -SaltLength 16
  $isValid = Test-MKStringHash -String "MyPassword123" -StoredHash $storedData.Hash -StoredSalt $storedData.Salt
  This example demonstrates how to use Get-MKStringHash to create a hash and salt, and then use
  Test-MKStringHash to verify a password against that hash and salt.

  .EXAMPLE
  Test-MKStringHash -String "WrongPassword" -StoredHash $storedHash -StoredSalt $storedSalt -Algorithm SHA512
  This example shows how to use the function with a specific algorithm (SHA512) to test an incorrect password.

  .OUTPUTS
  Returns a boolean value: $true if the password is correct, $false otherwise.

  .NOTES
  Ensure that you're using the same hashing algorithm in both Get-MKStringHash and Test-MKStringHash
  for consistent results.
  #>
  param(
    [string]$String,

    [string]$StoredHash,

    [string]$StoredSalt,

    [Parameter()]
    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [string]$Algorithm = 'SHA256'
  )

  $newHash = Get-MKStringHash -String ($String + $StoredSalt) -Algorithm $Algorithm
  return $newHash.Hash -eq $StoredHash
}

<#
# Usage:
$storedPasswordData = Get-MKStringHash -String "MyPassword123" -UseSalt
$isValid = Test-MKStringHash -String "MyPassword123" -StoredHash $storedPasswordData.Hash -StoredSalt $storedPasswordData.Salt

if ($isValid) {
  Write-Output "Password is correct"
} else {
  Write-Output "Password is incorrect"
}

Test-MKStringHash -string "Password123" -StoredHash D353FCF738260AF721D33C25A82014E6003E08DD2436E67AAABD88ADFF0A169A -storedsalt XIKmU4f/76migqdlPLrMAXi6fDbTmYkIhxg7q832YbA=
Test-MKStringHash -string "MyPassword123" -StoredHash D353FCF738260AF721D33C25A82014E6003E08DD2436E67AAABD88ADFF0A169A -storedsalt XIKmU4f/76migqdlPLrMAXi6fDbTmYkIhxg7q832YbA=
#>