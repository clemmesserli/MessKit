function ConvertFrom-MKSecureStringToText {
  <#
    .SYNOPSIS
    Converts a secure string back to plain text.

    .DESCRIPTION
    Converts a SecureString object back to plain text. This function uses the .NET Framework's Marshal class
    to safely extract the plain text content from the secure string memory allocation.

    CAUTION: Converting secure strings to plain text exposes sensitive information in memory. Only use
    when absolutely necessary in controlled environments.

    .PARAMETER SecureString
    The encrypted SecureString object you wish to convert back to plain text.
    This can come from various sources such as Read-Host -AsSecureString, credential objects,
    or secure string storage mechanisms.

    .EXAMPLE
    $password = Read-Host -Prompt 'Enter password' -AsSecureString
    $plain = ConvertFrom-MKSecureStringToText -SecureString $password

    Creates a secure string from user input and converts it to plain text.

    .EXAMPLE
    $cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
    $plain = ConvertFrom-MKSecureStringToText -SecureString $cred.Password

    Extracts the password from a credential object and converts it to plain text.

    .EXAMPLE
    ConvertFrom-MKSecureStringToText -SecureString (Get-Secret demostring)

    First retrieves a secure string from Secret Vault and then converts to plain text.
    Note: Equivalent to (Get-Secret demostring -AsPlainText)

    .EXAMPLE
    Get-Secret demostring | ConvertFrom-MKSecureStringToText

    Demonstrates using the function with pipeline input.

    .INPUTS
    [System.Security.SecureString]
    You can pipe a SecureString object to this function.

    .OUTPUTS
    [System.String]
    Returns the plain text representation of the secure string.

    .NOTES
    Security Warning: Converting SecureString objects to plain text defeats the security purpose
    of the SecureString type. The resulting plain text string will remain in memory until garbage
    collected and could potentially be exposed through memory dumps or other means. Only use this
    function when absolutely necessary, and clear variables containing sensitive data when no longer needed.
    #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [System.Security.SecureString]
    $SecureString
  )

  process {
    try {
      $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecureString)
      $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
      [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr)
      return $plainText
    } catch {
      Write-Error "An error occurred during the conversion process: $_"
    }
  }
}