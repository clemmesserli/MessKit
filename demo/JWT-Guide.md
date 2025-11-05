# JWT Tokens: A Complete Guide with PowerShell

## What are JWT Tokens?

JSON Web Tokens (JWT) are a compact, URL-safe means of representing claims between two parties. They consist of three parts separated by dots:

```text
header.payload.signature
```

## JWT Structure

### 1. Header

Contains metadata about the token:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### 2. Payload

Contains the claims (user data):

```json
{
  "iss": "demo-app",
  "sub": "1234567890",
  "aud": "enterprise-demo",
  "exp": 1735689600,
  "iat": 1735686000,
  "name": "John Doe",
  "role": "admin"
}
```

### 3. Signature

Ensures token integrity and authenticity.

## Step-by-Step Implementation

### Step 1: Base64URL Encoding Helper

```powershell
function ConvertTo-Base64Url {
    param([byte[]]$bytes)
    $base64 = [Convert]::ToBase64String($bytes)
    $base64.Replace('+', '-').Replace('/', '_').Replace('=', '')
}
```

### Step 2: Create Header and Payload

```powershell
# Headers for different algorithms
$headerHS = @{ alg = "HS256"; typ = "JWT" }
$headerRS = @{ alg = "RS256"; typ = "JWT" }

# Sample payload with standard claims
$payload = @{
    iss  = "demo-app"           # Issuer
    sub  = "1234567890"         # Subject
    aud  = "enterprise-demo"    # Audience
    exp  = [int][DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()  # Expiration
    iat  = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()               # Issued At
    name = "John Doe"           # Custom claim
    role = "admin"              # Custom claim
}
```

### Step 3: Convert to JSON and Encode

```powershell
# Convert to JSON
$headerHSJson = ($headerHS | ConvertTo-Json -Compress)
$headerRSJson = ($headerRS | ConvertTo-Json -Compress)
$payloadJson = ($payload | ConvertTo-Json -Compress)

# Base64URL encode
$headerHS64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($headerHSJson))
$headerRS64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($headerRSJson))
$payload64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($payloadJson))
```

## HS256 vs RS256 - The Key Difference

### HS256 (Symmetric)

- **Single secret key** for both signing and verification
- **Faster** performance
- **Shared secret** must be known by all parties

### RS256 (Asymmetric)

- **Private key** for signing, **public key** for verification
- **Slower** performance but more secure
- **Public key** can be freely distributed

## Step 4: Create HS256 Token

```powershell
$secret = "my_demo_secret"
$hmac = New-Object System.Security.Cryptography.HMACSHA256 ([Text.Encoding]::UTF8.GetBytes($secret))
$signatureHS = ConvertTo-Base64Url ($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes("$headerHS64.$payload64")))
$jwtHS256 = "$headerHS64.$payload64.$signatureHS"

Write-Host "HS256 JWT: $jwtHS256"
```

## Step 5: Create RS256 Token

```powershell
# Generate RSA key pair
$rsa = [System.Security.Cryptography.RSA]::Create(2048)

# Sign using RS256
$signData = [Text.Encoding]::UTF8.GetBytes("$headerRS64.$payload64")
$signatureRS = $rsa.SignData($signData, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
$signatureRS64 = ConvertTo-Base64Url $signatureRS
$jwtRS256 = "$headerRS64.$payload64.$signatureRS64"

Write-Host "RS256 JWT: $jwtRS256"
```

## Step 6: Signature Verification

```powershell
function Verify-JWT {
    param([string]$jwt, [string]$secret = $null, [System.Security.Cryptography.RSA]$rsaKey = $null)

    try {
        $parts = $jwt -split '\.'
        if ($parts.Length -ne 3) { return $false }

        # Decode header
        $headerPadded = $parts[0].Replace('-', '+').Replace('_', '/')
        while ($headerPadded.Length % 4) { $headerPadded += '=' }
        $header = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($headerPadded)) | ConvertFrom-Json

        # Decode signature
        $sigPadded = $parts[2].Replace('-', '+').Replace('_', '/')
        while ($sigPadded.Length % 4) { $sigPadded += '=' }
        $signature = [Convert]::FromBase64String($sigPadded)

        $signData = "$($parts[0]).$($parts[1])"

        if ($header.alg -eq "HS256" -and $secret) {
            $hmacVerify = New-Object System.Security.Cryptography.HMACSHA256
            $hmacVerify.Key = [Text.Encoding]::UTF8.GetBytes($secret)
            $expectedSig = $hmacVerify.ComputeHash([Text.Encoding]::UTF8.GetBytes($signData))
            $hmacVerify.Dispose()

            # Compare byte arrays
            if ($signature.Length -ne $expectedSig.Length) { return $false }
            for ($i = 0; $i -lt $signature.Length; $i++) {
                if ($signature[$i] -ne $expectedSig[$i]) { return $false }
            }
            return $true
        }

        if ($header.alg -eq "RS256" -and $rsaKey) {
            return $rsaKey.VerifyData([Text.Encoding]::UTF8.GetBytes($signData), $signature, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        }

        return $false
    } catch {
        Write-Host "Verification error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Verify tokens
$hsValid = Verify-JWT -jwt $jwtHS256 -secret $secret
$rsValid = Verify-JWT -jwt $jwtRS256 -rsaKey $rsa

Write-Host "HS256 Valid: $hsValid" -ForegroundColor $(if($hsValid){'Green'}else{'Red'})
Write-Host "RS256 Valid: $rsValid" -ForegroundColor $(if($rsValid){'Green'}else{'Red'})
```

## Step 7: Decode JWT Payload

```powershell
function Decode-JwtPayload {
    param([string]$token)

    $parts = $token.Split('.')
    if ($parts.Length -lt 2) {
        Write-Host "Invalid JWT format"
        return
    }

    $payloadBase64 = $parts[1] -replace '-', '+' -replace '_', '/'

    # Add padding if needed
    switch ($payloadBase64.Length % 4) {
        2 { $payloadBase64 += '==' }
        3 { $payloadBase64 += '=' }
    }

    $payloadBytes = [Convert]::FromBase64String($payloadBase64)
    $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
    return ($payloadJson | ConvertFrom-Json)
}

# Decode and display payloads
$decodedHS = Decode-JwtPayload $jwtHS256
$decodedRS = Decode-JwtPayload $jwtRS256

Write-Host "Decoded Payload:" ($decodedHS | ConvertTo-Json -Depth 3)
```

## Step 8: Invalid Token Demonstrations

```powershell
# Create expired token (1 hour ago)
$expiredPayload = @{
    iss  = "demo-app"
    sub  = "1234567890"
    aud  = "enterprise-demo"
    exp  = [int][DateTimeOffset]::UtcNow.AddHours(-1).ToUnixTimeSeconds()  # Expired 1 hour ago
    iat  = [int][DateTimeOffset]::UtcNow.AddHours(-2).ToUnixTimeSeconds()  # Issued 2 hours ago
    name = "John Doe"
    role = "admin"
}

$expiredPayloadJson = ($expiredPayload | ConvertTo-Json -Compress)
$expiredPayload64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($expiredPayloadJson))
$expiredSignature = ConvertTo-Base64Url ($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes("$headerHS64.$expiredPayload64")))
$expiredJWT = "$headerHS64.$expiredPayload64.$expiredSignature"

Write-Host "\n=== INVALID TOKEN TESTS ===" -ForegroundColor Yellow

# Test 1: Expired token (valid signature but expired)
Write-Host "\n1. Expired Token Test:" -ForegroundColor Cyan
$expiredValid = Verify-JWT -jwt $expiredJWT -secret $secret
Write-Host "Signature Valid: $expiredValid" -ForegroundColor $(if($expiredValid){'Green'}else{'Red'})
$expiredDecoded = Decode-JwtPayload $expiredJWT
$currentTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
Write-Host "Token Expired: $(if($expiredDecoded.exp -lt $currentTime){'YES'}else{'NO'})" -ForegroundColor $(if($expiredDecoded.exp -lt $currentTime){'Red'}else{'Green'})

# Test 2: Wrong secret key
Write-Host "\n2. Wrong Secret Key Test:" -ForegroundColor Cyan
$wrongSecret = "wrong_secret_key"
$wrongSecretValid = Verify-JWT -jwt $jwtHS256 -secret $wrongSecret
Write-Host "Valid with correct secret: $(Verify-JWT -jwt $jwtHS256 -secret $secret)" -ForegroundColor Green
Write-Host "Valid with wrong secret: $wrongSecretValid" -ForegroundColor Red

# Test 3: Tampered payload
Write-Host "\n3. Tampered Token Test:" -ForegroundColor Cyan
$tamperedPayload = @{
    iss  = "demo-app"
    sub  = "1234567890"
    aud  = "enterprise-demo"
    exp  = [int][DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
    iat  = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    name = "John Doe"
    role = "superadmin"  # Changed from 'admin' to 'superadmin'
}
$tamperedPayloadJson = ($tamperedPayload | ConvertTo-Json -Compress)
$tamperedPayload64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($tamperedPayloadJson))
# Use original signature with tampered payload
$tamperedJWT = "$headerHS64.$tamperedPayload64.$signatureHS"
$tamperedValid = Verify-JWT -jwt $tamperedJWT -secret $secret
Write-Host "Tampered token valid: $tamperedValid" -ForegroundColor Red

# Test 4: Wrong RSA key
Write-Host "\n4. Wrong RSA Key Test:" -ForegroundColor Cyan
$wrongRSA = [System.Security.Cryptography.RSA]::Create(2048)
$wrongRSAValid = Verify-JWT -jwt $jwtRS256 -rsaKey $wrongRSA
Write-Host "Valid with correct RSA key: $(Verify-JWT -jwt $jwtRS256 -rsaKey $rsa)" -ForegroundColor Green
Write-Host "Valid with wrong RSA key: $wrongRSAValid" -ForegroundColor Red
$wrongRSA.Dispose()

# Test 5: Malformed token
Write-Host "\n5. Malformed Token Test:" -ForegroundColor Cyan
$malformedJWT = "invalid.token.format.extra.parts"
$malformedValid = Verify-JWT -jwt $malformedJWT -secret $secret
Write-Host "Malformed token valid: $malformedValid" -ForegroundColor Red

# Test 6: Valid token (for comparison)
Write-Host "\n6. Valid Token Test (Expected Success):" -ForegroundColor Cyan
$validHS = Verify-JWT -jwt $jwtHS256 -secret $secret
$validRS = Verify-JWT -jwt $jwtRS256 -rsaKey $rsa
$validDecoded = Decode-JwtPayload $jwtHS256
Write-Host "HS256 token valid: $validHS" -ForegroundColor Green
Write-Host "RS256 token valid: $validRS" -ForegroundColor Green
Write-Host "Token Expired: $(if($validDecoded.exp -lt $currentTime){'YES'}else{'NO'})" -ForegroundColor Green
Write-Host "User Role: $($validDecoded.role)" -ForegroundColor Green

Write-Host "\n=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "✓ Valid tokens pass verification" -ForegroundColor Green
Write-Host "✗ Expired tokens fail time validation" -ForegroundColor Red
Write-Host "✗ Wrong keys fail signature verification" -ForegroundColor Red
Write-Host "✗ Tampered tokens fail signature verification" -ForegroundColor Red
Write-Host "✗ Malformed tokens fail structure validation" -ForegroundColor Red
```

### Invalid Token Test Results

The demonstrations above show various failure scenarios:

1. **Expired Token** - Valid signature but past expiration time
2. **Wrong Secret Key** - Signature verification fails with incorrect HMAC secret
3. **Tampered Payload** - Modified claims fail signature verification
4. **Wrong RSA Key** - RS256 token fails with different key pair
5. **Malformed Token** - Invalid JWT structure
6. **Valid Token** - Shows expected successful validation for comparison

## Security Considerations

### ⚠️ Important Security Notes

1. **JWTs are NOT encrypted** - Anyone can decode and read the payload
2. **Never store sensitive data** in JWT payloads (passwords, SSNs, Personally Identifiable (PII), etc.)
3. **Use HTTPS** to protect tokens in transit
4. **Beware of Logs** as tokens often travel across networks, may be cached, or stored in browsers.
5. **Keep expiration times short** for sensitive applications
6. **Validate all claims** on the receiving end

### What Makes JWTs Secure

- **Integrity**: Signature ensures token hasn't been tampered with
- **Authenticity**: Signature proves token came from trusted issuer
- **Non-repudiation**: Issuer can't deny creating the token

## When to Use Each Algorithm

### Use HS256 When

- Single application/service
- Performance is critical
- Simple architecture
- Internal APIs
- Session tokens

### Use RS256 When

- Multiple services need verification
- Third-party integration
- Distributed systems
- Public APIs
- Identity providers (OAuth2/OpenID Connect)

## Testing Your Implementation

1. **Generate tokens** using the code above
2. **Copy tokens** to [jwt.io](https://jwt.io) to verify structure
3. **Test verification** with correct and incorrect secrets/keys
4. **Check expiration** by creating tokens with past expiration times

## Complete Example Output

When you run the complete implementation, you'll see:

```text
HS256 JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkZW1vLWFwcCIsInN1YiI6IjEyMzQ1Njc4OTAiLCJhdWQiOiJlbnRlcnByaXNlLWRlbW8iLCJleHAiOjE3MzU2ODk2MDAsImlhdCI6MTczNTY4NjAwMCwibmFtZSI6IkpvaG4gRG9lIiwicm9sZSI6ImFkbWluIn0.signature

RS256 JWT: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkZW1vLWFwcCIsInN1YiI6IjEyMzQ1Njc4OTAiLCJhdWQiOiJlbnRlcnByaXNlLWRlbW8iLCJleHAiOjE3MzU2ODk2MDAsImlhdCI6MTczNTY4NjAwMCwibmFtZSI6IkpvaG4gRG9lIiwicm9sZSI6ImFkbWluIn0.signature

HS256 Valid: True
RS256 Valid: True
```

This guide provides an introduction to JWT implementations using PowerShell, covering both symmetric and asymmetric signing algorithms with practical examples and security considerations.
