function New-LabCert {
  <#
  .SYNOPSIS
  Create various certs that may be used as part of a lab

  .DESCRIPTION
  This function can be used to create Root, Issuer, Web, CodeSigning, and Document Encryption certificates

  .EXAMPLE
  New-LabCert -CertType "Root" -Subject "MyLabRootCA" -Days 365

  .EXAMPLE
  New-LabCert -CertType "Intermediate" -Subject "MyLabIssuerCA" -Days 365 -Issuer "MyLabRootCA"

  .EXAMPLE
  New-LabCert -CertType "Web" -Subject "demo1.mylab.com" -Days 365 -Issuer "MyLabIssuerCA"

  .EXAMPLE
  New-LabCert -CertType "CodeSigning" -CertStore "CurrentUser" -Subject "MyLabCodeSign" -Days 365 -Issuer "MyLabIssuerCA"

  .EXAMPLE
  New-LabCert -CertType "DocumentEncryption" -CertStore "CurrentUser" -Subject "MyLabDocEncryption" -Days 365 -Issuer "MyLabIssuerCA" -NonExportable

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
  New-LabCert @certParams
	#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Alias("SubjectName")]
    [string]$Subject,

    [Parameter()]
    [ValidateSet("LocalMachine", "CurrentUser")]
    [string]$CertStore = "LocalMachine",

    [Parameter()]
    [string[]]$SubjectAltName,

    [Parameter()]
    [Alias("UPN")]
    [string[]]$UserPrincipalName,

    [Parameter()]
    [string[]]$GUID = (New-Guid).Guid,

    [Parameter()]
    [string[]]$TargetDomain,

    [Parameter()]
    [string]$Issuer,

    [Parameter(Mandatory)]
    [ValidateSet("Root", "Intermediate", "Web", "CodeSigning", "DocumentEncryption", "ClientAuth")]
    [string]$CertType,

    [Parameter()]
    [int]$Days = 365,

    [Parameter()]
    [switch]$NonExportable
  )

  process {
    $notAfter = (Get-Date).AddDays($Days)
    $dnsName = @([Array]$Subject + [Array]$SubjectAltName) | Sort-Object -Unique
    if ($NonExportable) {
      $keyExportPolicy = "NonExportable"
    } else {
      $keyExportPolicy = "Exportable"
    }
    $commonParams = @{
      CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
      HashAlgorithm     = "sha256"
      KeyAlgorithm      = "RSA"
      KeyExportPolicy   = "$keyExportPolicy"
      KeyLength         = 2048
      NotAfter          = $notAfter
      Subject           = "$Subject"
    }

    switch ($CertType) {
      "Root" {
        $certParams = @{
          DnsName       = "$Subject"
          KeySpec       = "Signature"
          KeyUsage      = @(
            "CRLSign",
            "CertSign"
          )
          Provider      = "Microsoft Strong Cryptographic Provider"
          TextExtension = @(
            "2.5.29.19={critical}{text}cA=true&pathLength=1"
          )
          Type          = "Custom"
        }
        $rootCert = New-SelfSignedCertificate @commonParams @certParams
        # Move the certificate to the Trusted Root Certification Authorities store
        $destStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", $CertStore)
        $destStore.Open("ReadWrite")
        $destStore.Add($rootCert)
        $destStore.Close()
        $rootCert
      }
      "Intermediate" {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "My") | Where-Object Subject -EQ "CN=$Issuer" | Select-Object -Last 1 )
        $certParams = @{
          DnsName       = "$Subject"
          KeySpec       = "Signature"
          KeyUsage      = @(
            "CRLSign",
            "CertSign"
          )
          Provider      = "Microsoft Strong Cryptographic Provider"
          Signer        = $Signer
          TextExtension = @(
            "2.5.29.19={critical}{text}cA=true&pathLength=0"
          )
          Type          = "Custom"
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
      "Web" {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )
        $certParams = @{
          DnsName       = $dnsName
          FriendlyName  = "$($Subject)_$($notAfter.ToString('yyyyMMdd'))"
          KeyUsage      = @(
            "DigitalSignature",
            "KeyEncipherment"
          )
          Provider      = "Microsoft Strong Cryptographic Provider"
          Signer        = $Signer
          TextExtension = @(
            "2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2",
            "2.5.29.19={text}cA=false"
          )
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
      "ClientAuth" {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )
        $CertParams = @{
          KeyUsage      = @("DigitalSignature")
          Provider      = "Microsoft Software Key Storage Provider"
          Signer        = $Signer
          TextExtension = @(
            "2.5.29.37={text}1.3.6.1.5.5.7.3.2",
            "2.5.29.17={text}UPN=$UserPrincipalName&DirectoryName=$Subject&GUID=$GUID&URL=$TargetDomain"
          )
          Type          = "Custom"
        }
        New-SelfSignedCertificate @commonParams @CertParams
      }
      "DocumentEncryption" {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )
        $certParams = @{
          FriendlyName  = "$($Subject)_$($notAfter.ToString('yyyyMMdd'))"
          KeyUsage      = @(
            "KeyEncipherment",
            "KeyAgreement",
            "DataEncipherment",
            "DigitalSignature"
          )
          Provider      = "Microsoft Strong Cryptographic Provider"
          Signer        = $Signer
          TextExtension = @(
            "2.5.29.37={text}1.3.6.1.4.1.311.80.1"
          )
          Type          = "DocumentEncryptionCert"
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
      "CodeSigning" {
        $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )
        $certParams = @{
          FriendlyName  = "$($Subject)_$($notAfter.ToString('yyyyMMdd'))"
          KeyUsage      = @("DigitalSignature")
          Provider      = "Microsoft Strong Cryptographic Provider"
          Signer        = $Signer
          TextExtension = @(
            "2.5.29.37={text}1.3.6.1.5.5.7.3.3"
          )
          Type          = "CodeSigningCert"
        }
        New-SelfSignedCertificate @commonParams @certParams
      }
    }
  }
}