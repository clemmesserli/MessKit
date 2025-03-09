function New-MKLabCert {
  <#
  .SYNOPSIS
  Create various certificates that may be used as part of a lab environment.

  .DESCRIPTION
  This function creates different types of certificates for lab environments, including:
  - Root CA certificates
  - Intermediate CA certificates
  - Web server certificates
  - Code signing certificates
  - Document encryption certificates
  - Client authentication certificates

  All certificates are created with appropriate extensions and key usages based on their type.

  .PARAMETER Subject
  The subject name for the certificate. For Root and Intermediate certificates, this is typically the CA name.
  For Web certificates, this should be the primary DNS name.

  .PARAMETER CertStore
  The certificate store location where the certificate will be placed.
  Valid values: "LocalMachine", "CurrentUser"
  Default: "LocalMachine"

  .PARAMETER SubjectAltName
  Additional DNS names to include in the certificate as Subject Alternative Names.

  .PARAMETER UserPrincipalName
  The User Principal Name (UPN) to include in the certificate. Primarily used for ClientAuth certificates.

  .PARAMETER GUID
  A GUID to include in the certificate. Defaults to a newly generated GUID.

  .PARAMETER TargetDomain
  The target domain for the certificate. Used primarily with ClientAuth certificates.

  .PARAMETER Issuer
  The name of the issuing CA certificate. Required for all certificate types except Root.

  .PARAMETER CertType
  The type of certificate to create.
  Valid values: "Root", "Intermediate", "Web", "CodeSigning", "DocumentEncryption", "ClientAuth"

  .PARAMETER Days
  The number of days the certificate will be valid. Default is 365 days.

  .PARAMETER NonExportable
  Switch to create a certificate with a non-exportable private key.

  .OUTPUTS
  System.Security.Cryptography.X509Certificates.X509Certificate2
  Returns the created certificate object.

  .EXAMPLE
  New-MKLabCert -CertType "Root" -Subject "MyLabRootCA" -Days 365
  Creates a Root CA certificate valid for 1 year.

  .EXAMPLE
  New-MKLabCert -CertType "Intermediate" -Subject "MyLabIssuerCA" -Days 365 -Issuer "MyLabRootCA"
  Creates an Intermediate CA certificate signed by the specified Root CA.

  .EXAMPLE
  New-MKLabCert -CertType "Web" -Subject "demo1.mylab.com" -SubjectAltName "demo1" -Days 365 -Issuer "MyLabIssuerCA"
  Creates a Web server certificate with an additional subject alternative name.

  .EXAMPLE
  New-MKLabCert -CertType "CodeSigning" -CertStore "CurrentUser" -Subject "MyLabCodeSign" -Days 365 -Issuer "MyLabIssuerCA"
  Creates a code signing certificate in the CurrentUser store.

  .EXAMPLE
  New-MKLabCert -CertType "DocumentEncryption" -CertStore "CurrentUser" -Subject "MyLabDocEncryption" -Days 365 -Issuer "MyLabIssuerCA" -NonExportable
  Creates a document encryption certificate with a non-exportable private key.

  .EXAMPLE
  $certParams = @{
      CertStore = "CurrentUser"
      CertType = "ClientAuth"
      Days = 30
      NonExportable = $true
      Issuer = "MyLabIssuerCA"
      Subject = "CN=HelpDeskUser,OU=Users,DC=mylab,DC=com"
      TargetDomain = "demo1.mylab.com"
      UPN = "HelpDeskUser@mylab.com"
  }
  New-MKLabCert @certParams
  Creates a client authentication certificate with specified parameters using splatting.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Alias('SubjectName')]
    [string]$Subject,

    [Parameter()]
    [ValidateSet('LocalMachine', 'CurrentUser')]
    [string]$CertStore = 'LocalMachine',

    [Parameter()]
    [string[]]$SubjectAltName,

    [Parameter()]
    [Alias('UPN')]
    [string[]]$UserPrincipalName,

    [Parameter()]
    [string[]]$GUID = (New-Guid).Guid,

    [Parameter()]
    [string[]]$TargetDomain,

    [Parameter()]
    [string]$Issuer,

    [Parameter(Mandatory)]
    [ValidateSet('Root', 'Intermediate', 'Web', 'CodeSigning', 'DocumentEncryption', 'ClientAuth')]
    [string]$CertType,

    [Parameter()]
    [int]$Days = 365,

    [Parameter()]
    [switch]$NonExportable
  )

  process {
    $notAfter = (Get-Date).AddDays($Days)
    $dnsName = @([Array]$Subject + [Array]$SubjectAltName) | Sort-Object -Unique
    #$SAN = @([Array]$subject + [Array]$subjectaltname) | Sort-Object -Unique | ForEach-Object { "DNS=$_" }
    if ($NonExportable) {
      $keyExportPolicy = 'NonExportable'
    } else {
      $keyExportPolicy = 'Exportable'
    }
    $commonParams = @{
      CertStoreLocation = $(Join-Path "Cert:\$CertStore" 'My')
      HashAlgorithm     = 'sha256'
      KeyAlgorithm      = 'RSA'
      KeyExportPolicy   = "$keyExportPolicy"
      KeyLength         = 2048
      NotAfter          = $notAfter
      Subject           = "$Subject"
    }

    switch ($CertType) {
      'Root' {
        $certParams = @{
          DnsName       = "$Subject"
          KeySpec       = 'Signature'
          KeyUsage      = @(
            'CRLSign',
            'CertSign'
          )
          Provider      = 'Microsoft Strong Cryptographic Provider'
          TextExtension = @(
            '2.5.29.19={critical}{text}cA=true&pathLength=1'
          )
          Type          = 'Custom'
        }
        $rootCert = New-SelfSignedCertificate @commonParams @certParams
        # Move the certificate to the Trusted Root Certification Authorities store
        $destStore = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', $CertStore)
        $destStore.Open('ReadWrite')
        $destStore.Add($rootCert)
        $destStore.Close()
        $rootCert
      }
      'Intermediate' {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" 'My') | Where-Object Subject -EQ "CN=$Issuer" | Select-Object -Last 1 )
        $certParams = @{
          DnsName       = "$Subject"
          KeySpec       = 'Signature'
          KeyUsage      = @(
            'CRLSign',
            'CertSign'
          )
          Provider      = 'Microsoft Strong Cryptographic Provider'
          Signer        = $Signer
          TextExtension = @(
            '2.5.29.19={critical}{text}cA=true&pathLength=0'
          )
          Type          = 'Custom'
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
      'Web' {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" 'CA') | Where-Object Subject -EQ "CN=$Issuer" )
        $certParams = @{
          DnsName       = $dnsName
          FriendlyName  = "$($Subject)_$($notAfter.ToString('yyyyMMdd'))"
          KeyUsage      = @(
            'DigitalSignature',
            'KeyEncipherment'
          )
          Provider      = 'Microsoft Strong Cryptographic Provider'
          Signer        = $Signer
          TextExtension = @(
            '2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2', # Extended Key Usage
            '2.5.29.19={text}cA=false' # Basic Constraints
          )
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
      'ClientAuth' {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" 'CA') | Where-Object Subject -EQ "CN=$Issuer" )
        $CertParams = @{
          KeyUsage      = @('DigitalSignature')
          Provider      = 'Microsoft Software Key Storage Provider'
          Signer        = $Signer
          TextExtension = @(
            '2.5.29.37={text}1.3.6.1.5.5.7.3.2',
            "2.5.29.17={text}UPN=$UserPrincipalName&DirectoryName=$Subject&GUID=$GUID&URL=$TargetDomain"
          )
          Type          = 'Custom'
        }
        New-SelfSignedCertificate @commonParams @CertParams
      }
      'DocumentEncryption' {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" 'CA') | Where-Object Subject -EQ "CN=$Issuer" )
        $certParams = @{
          FriendlyName  = "$($Subject)_$($notAfter.ToString('yyyyMMdd'))"
          KeyUsage      = @(
            'KeyEncipherment',
            'KeyAgreement',
            'DataEncipherment',
            'DigitalSignature'
          )
          Provider      = 'Microsoft Strong Cryptographic Provider'
          Signer        = $Signer
          TextExtension = @(
            '2.5.29.37={text}1.3.6.1.4.1.311.80.1'
          )
          Type          = 'DocumentEncryptionCert'
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
      'CodeSigning' {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" 'CA') | Where-Object Subject -EQ "CN=$Issuer" )
        $certParams = @{
          FriendlyName  = "$($Subject)_$($notAfter.ToString('yyyyMMdd'))"
          KeyUsage      = @('DigitalSignature')
          Provider      = 'Microsoft Strong Cryptographic Provider'
          Signer        = $Signer
          TextExtension = @(
            '2.5.29.37={text}1.3.6.1.5.5.7.3.3'
          )
          Type          = 'CodeSigningCert'
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
    }
  }
}