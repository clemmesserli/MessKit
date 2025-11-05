# =========================
# 1. Helper: Base64URL Encode
# =========================
function ConvertTo-Base64Url {
	param([byte[]]$bytes)
	$base64 = [Convert]::ToBase64String($bytes)
	$base64.Replace('+', '-').Replace('/', '_').Replace('=', '')
}

# =========================
# 2. Create Header & Payload
# =========================
$headerHS = @{ alg = "HS256"; typ = "JWT" }
$headerRS = @{ alg = "RS256"; typ = "JWT" }

$payload = @{
	iss  = "demo-app"
	sub  = "1234567890"
	aud  = "enterprise-demo"
	exp  = [int][DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
	iat  = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
	name = "John Doe"
	role = "admin"
}

# Convert to JSON and Base64URL
$headerHSJson = ($headerHS | ConvertTo-Json -Compress)
$headerRSJson = ($headerRS | ConvertTo-Json -Compress)
$payloadJson = ($payload | ConvertTo-Json -Compress)

$headerHS64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($headerHSJson))
$headerRS64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($headerRSJson))
$payload64 = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($payloadJson))

# =========================
# 3. HS256 Token
# =========================
$secret = "my_demo_secret"
$hmac = New-Object System.Security.Cryptography.HMACSHA256 ([Text.Encoding]::UTF8.GetBytes($secret))
$signatureHS = ConvertTo-Base64Url ($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes("$headerHS64.$payload64")))
$jwtHS256 = "$headerHS64.$payload64.$signatureHS"
Write-Host "`nHS256 JWT:`n$jwtHS256"

# =========================
# 4. RS256 Token
# =========================
# Generate RSA key pair
$rsa = [System.Security.Cryptography.RSA]::Create(2048)
$privateKey = $rsa.ExportParameters($true)
$publicKey = $rsa.ExportParameters($false)

# Sign using RS256
$signData = [Text.Encoding]::UTF8.GetBytes("$headerRS64.$payload64")
$signatureRS = $rsa.SignData($signData, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
$signatureRS64 = ConvertTo-Base64Url $signatureRS
$jwtRS256 = "$headerRS64.$payload64.$signatureRS64"
Write-Host "`nRS256 JWT:`n$jwtRS256"

# =========================
# 5. (Optional) Export Public Key for Verification
# =========================
$publicPem = @"
-----BEGIN PUBLIC KEY-----
$([Convert]::ToBase64String($rsa.ExportSubjectPublicKeyInfo()) -replace '.{64}', '$&`n')
-----END PUBLIC KEY-----
"@
Write-Host "`nPublic Key (PEM):`n$publicPem"

# =========================
# 6. Verify Signatures
# =========================
function Verify-JWT {
	param([string]$jwt, [string]$secret = $null, [System.Security.Cryptography.RSA]$rsaKey = $null)

	try {
		$parts = $jwt -split '\.'
		if ($parts.Length -ne 3) {
			return $false
  }

		# Decode header
		$headerPadded = $parts[0].Replace('-', '+').Replace('_', '/')
		while ($headerPadded.Length % 4) {
			$headerPadded += '='
  }
		$header = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($headerPadded)) | ConvertFrom-Json

		# Decode signature
		$sigPadded = $parts[2].Replace('-', '+').Replace('_', '/')
		while ($sigPadded.Length % 4) {
			$sigPadded += '='
  }
		$signature = [Convert]::FromBase64String($sigPadded)

		$signData = "$($parts[0]).$($parts[1])"

		if ($header.alg -eq "HS256" -and $secret) {
			$hmacVerify = New-Object System.Security.Cryptography.HMACSHA256
			$hmacVerify.Key = [Text.Encoding]::UTF8.GetBytes($secret)
			$expectedSig = $hmacVerify.ComputeHash([Text.Encoding]::UTF8.GetBytes($signData))
			$hmacVerify.Dispose()

			if ($signature.Length -ne $expectedSig.Length) {
				return $false
   }
			for ($i = 0; $i -lt $signature.Length; $i++) {
				if ($signature[$i] -ne $expectedSig[$i]) {
					return $false
    }
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

# Verify HS256 token
$hsValid = Verify-JWT -jwt $jwtHS256 -secret $secret
Write-Host "`nHS256 Signature Valid: $hsValid" -ForegroundColor $(if ($hsValid) {
		'Green'
	} else {
		'Red'
	})

# Verify RS256 token
$rsValid = Verify-JWT -jwt $jwtRS256 -rsaKey $rsa
Write-Host "RS256 Signature Valid: $rsValid" -ForegroundColor $(if ($rsValid) {
		'Green'
	} else {
		'Red'
	})


# =========================
# 7. Decode JWT Payload (Base64URL → JSON)
# =========================
function Decode-JwtPayload {
	param([string]$token)

	$parts = $token.Split('.')
	if ($parts.Length -lt 2) {
		Write-Host "Invalid JWT format"
		return
	}

	$payloadBase64 = $parts[1] -replace '-', '+' -replace '_', '/'
	# Pad with '=' if needed
	switch ($payloadBase64.Length % 4) {
		2 {
			$payloadBase64 += '=='
		}
		3 {
			$payloadBase64 += '='
		}
	}

	$payloadBytes = [Convert]::FromBase64String($payloadBase64)
	$payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
	return ($payloadJson | ConvertFrom-Json)
}

Write-Host "`nDecoded HS256 Payload:`n" (Decode-JwtPayload $jwtHS256 | ConvertTo-Json -Depth 3)
Write-Host "`nDecoded RS256 Payload:`n" (Decode-JwtPayload $jwtRS256 | ConvertTo-Json -Depth 3)

# =========================
# 8. Invalid Token Demonstrations
# =========================

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

Write-Host "`n=== INVALID TOKEN TESTS ===" -ForegroundColor Yellow

# Test 1: Expired token (valid signature but expired)
Write-Host "`n1. Expired Token Test:" -ForegroundColor Cyan
$expiredValid = Verify-JWT -jwt $expiredJWT -secret $secret
Write-Host "Signature Valid: $expiredValid" -ForegroundColor $(if($expiredValid){'Green'}else{'Red'})
$expiredDecoded = Decode-JwtPayload $expiredJWT
$currentTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
Write-Host "Token Expired: $(if($expiredDecoded.exp -lt $currentTime){'YES'}else{'NO'})" -ForegroundColor $(if($expiredDecoded.exp -lt $currentTime){'Red'}else{'Green'})
Write-Host "Expiration: $([DateTimeOffset]::FromUnixTimeSeconds($expiredDecoded.exp).ToString('yyyy-MM-dd HH:mm:ss UTC'))"
Write-Host "Current Time: $([DateTimeOffset]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss UTC'))"

# Test 2: Wrong secret key
Write-Host "`n2. Wrong Secret Key Test:" -ForegroundColor Cyan
$wrongSecret = "wrong_secret_key"
$wrongSecretValid = Verify-JWT -jwt $jwtHS256 -secret $wrongSecret
Write-Host "Valid with correct secret: $(Verify-JWT -jwt $jwtHS256 -secret $secret)" -ForegroundColor Green
Write-Host "Valid with wrong secret: $wrongSecretValid" -ForegroundColor Red

# Test 3: Tampered payload
Write-Host "`n3. Tampered Token Test:" -ForegroundColor Cyan
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
Write-Host "Original role: admin"
Write-Host "Tampered role: superadmin"

# Test 4: Wrong RSA key
Write-Host "`n4. Wrong RSA Key Test:" -ForegroundColor Cyan
$wrongRSA = [System.Security.Cryptography.RSA]::Create(2048)
$wrongRSAValid = Verify-JWT -jwt $jwtRS256 -rsaKey $wrongRSA
Write-Host "Valid with correct RSA key: $(Verify-JWT -jwt $jwtRS256 -rsaKey $rsa)" -ForegroundColor Green
Write-Host "Valid with wrong RSA key: $wrongRSAValid" -ForegroundColor Red
$wrongRSA.Dispose()

# Test 5: Malformed token
Write-Host "`n5. Malformed Token Test:" -ForegroundColor Cyan
$malformedJWT = "invalid.token.format.extra.parts"
$malformedValid = Verify-JWT -jwt $malformedJWT -secret $secret
Write-Host "Malformed token valid: $malformedValid" -ForegroundColor Red

# Test 6: Valid token (for comparison)
Write-Host "`n6. Valid Token Test (Expected Success):" -ForegroundColor Cyan
$validHS = Verify-JWT -jwt $jwtHS256 -secret $secret
$validRS = Verify-JWT -jwt $jwtRS256 -rsaKey $rsa
$validDecoded = Decode-JwtPayload $jwtHS256
Write-Host "HS256 token valid: $validHS" -ForegroundColor Green
Write-Host "RS256 token valid: $validRS" -ForegroundColor Green
Write-Host "Token Expired: $(if($validDecoded.exp -lt $currentTime){'YES'}else{'NO'})" -ForegroundColor Green
Write-Host "Expiration: $([DateTimeOffset]::FromUnixTimeSeconds($validDecoded.exp).ToString('yyyy-MM-dd HH:mm:ss UTC'))"
Write-Host "Current Time: $([DateTimeOffset]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss UTC'))"
Write-Host "User Role: $($validDecoded.role)" -ForegroundColor Green

Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "✓ Valid tokens pass verification" -ForegroundColor Green
Write-Host "✗ Expired tokens fail time validation" -ForegroundColor Red
Write-Host "✗ Wrong keys fail signature verification" -ForegroundColor Red
Write-Host "✗ Tampered tokens fail signature verification" -ForegroundColor Red
Write-Host "✗ Malformed tokens fail structure validation" -ForegroundColor Red