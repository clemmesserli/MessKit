function Initialize-MySecretStore {
	# Create the directory for the SecretStore
	New-Item -Path C:\MyVault\SecretStore -ItemType Directory -Force

	$password = New-Password -PwdLength 32
	$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

	# Create the PSCredential object
	$credential = New-Object System.Management.Automation.PSCredential("VaultAdmin", $securePassword)

	# Get the encryption certificate
	$cert = Get-ChildItem Cert:\currentuser\my -DocumentEncryptionCert | Select-Object -First 1

	# Encrypt and save the password
	$encryptedPassword = $credential.Password | ConvertFrom-SecureString
	$encryptedPassword | Protect-CmsMessage -To $cert -OutFile 'C:\MyVault\SecretStore\key.cms'

	# Register the SecretVault
	Register-SecretVault -Name 'PSVault' -ModuleName 'Microsoft.PowerShell.SecretStore' -DefaultVault

	# Configure the SecretStore
	$storeConfiguration = @{
		Authentication  = 'Password'
		PasswordTimeout = 1800 # 30 min
		Interaction     = 'None'
		Password        = $credential.Password
		Confirm         = $false
	}
	Set-SecretStoreConfiguration @storeConfiguration

	# Clean up sensitive variables
	Remove-Variable -Name password, securePassword, credential -Force
}

function Protect-MySecretStore {
	# Set restrictive permissions on the key file
	$acl = Get-Acl -Path "C:\MyVault\SecretStore\key.cms"
	$acl.SetAccessRuleProtection($true, $false)
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "Read", "Allow")
	$acl.SetAccessRule($rule)
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "Read", "Allow")
	$acl.SetAccessRule($rule)
	Set-Acl -Path "C:\MyVault\SecretStore\key.cms" -AclObject $acl
}

# Function to unlock the SecretStore (to be used when needed)
function Unlock-MySecretStore {
	$encryptedPassword = Get-Content -Path "C:\MyVault\SecretStore\key.cms" | Unprotect-CmsMessage
	$securePassword = ConvertTo-SecureString -String $encryptedPassword
	Unlock-SecretStore -Password $securePassword -PasswordTimeout 1800
	Remove-Variable -Name encryptedPassword, securePassword -Force
}

Initialize-MySecretStore
Protect-MySecretStore
Unlock-MySecretStore

# Verify store has been created
Get-SecretStoreConfiguration

# Create some sample entries
Set-Secret -Vault "PSVault" -Name "APIKey" -Secret $(New-Guid).guid
Set-Secret -Vault "PSVault" -Name "LabCred" -Secret (Get-Credential LabAdmin)

Get-SecretInfo