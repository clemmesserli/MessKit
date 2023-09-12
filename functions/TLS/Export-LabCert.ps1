Function Export-LabCert {
  <#
	.SYNOPSIS
		Exports crt + pfx (optional) files from computer certificate store
	.DESCRIPTION
		This function can be used to export existing Windows certificates that have 'Exportable=True'.
    You have the option of passing in a string to use for the password or it will autogenerate one and store in a text file within the same directory of the exported files.
	.EXAMPLE
		Export-LabCert -Subject 'MyRootCA'
	.EXAMPLE
		Export-LabCert -Subject 'MyIntermediateCA' -FolderPath 'C:\Certs'
  .EXAMPLE
		Export-LabCert -Subject 'demo1.mylab.com' -FolderPath 'C:\Certs' -PassPhrase (ConvertTo-SecureString 'GetABetterPwd' -AsPlainText -Force) -includekey
  .NOTES
    WARNING:
    Use of this function could result in certificate passwords being stored in plain text.
    This should only be used in lab environments.
	#>
  [cmdletbinding()]
  param(
    [Parameter()]
    [string]$FolderPath = "C:\Certs",

    [Parameter(Mandatory)]
    [Alias("SubjectName")]
    [String]$Subject,

    [Parameter()]
    [ValidateSet("LocalMachine", "CurrentUser")]
    [String]$CertStore = "CurrentUser",

    [Parameter()]
    [securestring]$PassPhrase,

    [Parameter()]
    [switch]$IncludeKey
  )

  Begin {}

  Process {

    if ($PSBoundParameters.ContainsKey('PassPhrase')) {
      # Since a SecureString was passed in, we will now have to revert it to plaintext in order to save in file
      $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PassPhrase)
      $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    } else {
      # Generate a pseudo-random password using the 'New-Password' function
      $PlainTextPassword = New-Password -PwdLength 18
      $PassPhrase = ConvertTo-SecureString -String "$PlainTextPassword" -Force -AsPlainText
    }

    $Cert = Get-ChildItem "Cert:\$CertStore\My" | Where-Object Subject -Match "$Subject"
    Export-Certificate -Cert "Cert:\$CertStore\My\$($Cert.Thumbprint)" -FilePath "$FolderPath\$Subject.crt"

    if ($PSBoundParameters.ContainsKey('IncludeKey')) {
      Export-PfxCertificate -Cert "Cert:\$CertStore\My\$($Cert.Thumbprint)"  -FilePath "$FolderPath\$Subject.pfx" -Password $PassPhrase
      Add-Content -Value "$Subject - $PlainTextPassword" -Path "$FolderPath\CertInfo.txt"
    }
  }

  End {}
}