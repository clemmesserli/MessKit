New-Item C:\MyVault\HashiCorp -ItemType Directory -Force

$srcFolder = "C:\LabSources\CustomPackages\vault.zip"
$dstFolder = "C:\MyVault\HashiCorp"

[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$dstFolder", [System.EnvironmentVariableTarget]::Machine)

Invoke-WebRequest -Uri "https://releases.hashicorp.com/vault/1.17.6/vault_1.17.6_windows_amd64.zip" -OutFile $srcFolder

Expand-Archive -Path $srcFolder -DestinationPath $dstFolder

New-Item "$dstFolder\data" -ItemType Directory -Force

Set-Location $dstFolder

& .\vault.exe version

& .\vault.exe server -dev

# Create a config hcl
$config = @"
storage "file" {
  path = "./data"
  node_id = "node1"
}
listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = "true"
}

disable_mlock = true

api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true
"@
Set-Content -Path "C:\MyVault\HashiCorp\config.hcl" -Value $config

& .\vault.exe server -config="C:\MyVault\HashiCorp\config.hcl"


# Launch CMD window and paste in the following
Set-Variable VAULT_ADDR=http://127.0.0.1:8200
vault.exe operator init

vault operator unseal { { $var1 } }
vault operator unseal { { $var2 } }
vault operator unseal { { $var3 } }

<#
# To Set as a ScheduledTask to run upon Startup

$action = New-ScheduledTaskAction -Execute "C:\MyVault\HashiCorp\vault.exe" -Argument "server -config=C:\MyVault\HashiCorp\config.hcl"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "VaultServer" -User "SYSTEM"

Start-ScheduledTask -TaskName "VaultServer"
#>


#Extract the Certificate:
openssl pkcs12 -in C:\MyVault\HashiCorp\cert\myvault.pfx -clcerts -nokeys -out C:\MyVault\HashiCorp\cert\myvault.crt

#Extract the Private Key:
openssl pkcs12 -in C:\MyVault\HashiCorp\cert\myvault.pfx -nocerts -nodes -out C:\MyVault\HashiCorp\cert\myvault.key


$env:VAULT_ADDR = "https://l4ws1901.messlabs.com:8200"
$env:VAULT_TOKEN = $vault_token

$headers = @{
  "X-VAULT-TOKEN" = $env:VAULT_TOKEN
}

$keys = @(
  $key1
  $key2
  $key3
)

#region Unseal
foreach ($key in $keys) {
  $json = @"
    {"key":"$key"}
"@
  Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/unseal" -Body $json
}
#endregion

#region Verify initialize status
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/init"
#endregion

& .\vault.exe login $env:VAULT_TOKEN

#region Enable AppRole Auth
$headers = @{
  "X-VAULT-TOKEN"   = $env:VAULT_TOKEN
  "X-Vault-Request" = "true"
}
$json = @"
    {
        "type":"approle",
        "description":"",
        "config": {
            "options":null,
            "default_lease_ttl":"0s",
            "max_lease_ttl":"0s",
            "force_no_cache":false,
        },
        "local":false,
        "seal_wrap":false,
        "external_entropy_access":false,
        "options":null
    }

"@
$response = Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/auth/approle" -Body $json
$response
#endregion


#region View Secrets Engine Paths
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/mounts" | Get-Member -MemberType NoteProperty | Select-Object Name, Definition
#endregion


#region Enable a new secrets engine
Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/mounts/work" -Body (Get-Content ./config/work.json)

Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/mounts/family" -Body (Get-Content ./config/family.json)

Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/mounts/leisure" -Body (Get-Content ./config/leisure.json)

## Upgrade v1 to v2
Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/mounts/leisure/tune" -Body (Get-Content ./config/leisure.json)
#endregion


#region Add secrets to new secrets engine path
Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/work/data/apikey01" -Body (Get-Content ./config/apikey01.json)

# to verify
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/work/data/apikey01" | Select-Object -ExpandProperty data | ConvertTo-Json
#endregion

#region verify path settings
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/leisure/tune" | Select-Object -ExpandProperty data
#endregion

#region disable secrets engine
Invoke-RestMethod -Method Delete -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/mounts/leisure"
#endregion



#region List Enabled Auth Methods
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/auth" | Get-Member -MemberType NoteProperty | Select-Object Name

# enable userpass
Invoke-RestMethod -Method Post -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/auth/userpass" -Body '{"type":"userpass"}'

# list userpass users
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/auth/userpass/users"

# add userpass user
Invoke-RestMethod -Method Get -Headers $headers -Uri "$($env:VAULT_ADDR)/v1/sys/auth/userpass/users/jane_doe" -Body (Get-Content ./config/jane_doe.json)


#endregion





#region Certificate Auth
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object Subject -Match 'LabAdmin' | Sort-Object -Descending | Select-Object -Top 1

$param = @{
  uri         = "$($env:VAULT_ADDR)/v1/auth/cert/login"
  certificate = $cert
  method      = "Post"
}
$response = Invoke-RestMethod @param

$env:VAULT_TOKEN = $response.auth.client_token
$env:VAULT_TOKEN
#endregion