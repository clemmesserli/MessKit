 #region Pre-Talk
  $params = @{
    AudioPath = "C:\LabSources\SampleData\Audio\SomebodyWatchingMe.mp3"
    BlurRadius = 4
    FontColor = "green"
    ImagePath = "C:\LabSources\SampleData\Images\hacker-02.jpg"
    ImageOpacity = 2
    Opacity = 5
    MessageContent = "PowerShell Saturday: `nData Piracy to Data Privacy"
    Duration = "00:00:30"
    AudioVolume = 15
  }
  Enable-MKScreenLock @params
  #endregion Pre-Talk

#region Always Bet on Black
<#
While many relate this phrase to Roulette, it is also metaphorically used to suggest confidence in taking a risk
or sticking with a specific strategy.  Within IT CyberSecurity the terms 'Black Hat' and 'White Hat' hackers are
used to depict those who may use PowerShell or other tools for malicious purposes and those who use it more ethically
to help test and secure systems.  In today's talk, I will primarily focus on the application or use of PowerShell but
will be posting on https://github.com/clemmesserli later this week after I clean up some rather last minute tweaks.
Now let's get to it.
#>
#Remove-Item -Path "C:\ProgramData\Security\keystrokes*" -Force

$folderPath = "C:\LabSources\SampleData\ICOD\"

$cert = Get-ChildItem Cert:\CurrentUser\My |
	Where-Object EnhancedKeyUsageList -match 'Document Encryption'


Get-Content "C:\ProgramData\Security\keystrokes.log"
Read-KeyloggerFile -logFilePath "C:\ProgramData\Security\keystrokes.log" |
	Out-File  -FilePath "C:\ProgramData\Security\keystrokes.txt"
$readableString = Convert-LogToString -logFilePath "C:\ProgramData\Security\keystrokes.txt"
Write-Output $readableString
#endregion

#region Shuffling the Deck
<#
In poker, if the deck isn't shuffled regularly players could predict the cards and gain an unfair advantage.
When it comes to protecting our data using PowerShell, there are a number of Password Managers or downloadable tools
that will do this but here's a slight twist as this will read back the NATO alphabet:
#>
(New-MKPassword).Length
New-MKPassword -PwdLength 8 -SymCount 1 -NumCount 1 -UCCount 2 -LCCount 4 |
	Get-MKPhonetic -Output list Audio -VoiceName David -VoiceRate 3 -VoiceVolume 25 -Verbose
#endregion

#region Shredding Your Cards
$fileName = "C:\LabSources\SampleData\ShredMe.txt"
$multilineText = @"
In poker, when you fold, you discard your cards face down to help ensure no one else can see
what you had and whether or not you might have trying to bluff or should have stayed in the game.
Using PowerShell we can take this even further by shredding or deletings files using multiple passes so
that typical file recovery methods cannot be used to piece the data back together again.
"@
$multilineText | Set-Content $fileName -Force
Get-Content $fileName
Clear-Host
Remove-MKFile -Path $fileName -Passes 1 -WhatIF
Get-Content $fileName
Remove-MKFile -Path $fileName -Passes 5 -Verbose
Get-ChildItem (Split-Path $fileName) -File
#endregion

#region Playing with a Marked Deck
<#
In poker, a marked deck allows one player to secretly know the value of the cards while everyone else believes
they are playing with a fair deck as the markings are subtle enough that no one notices.
Similarly in steganography, a text message or entire data file can be concealed within an image or audio file in
such a way that the everything looks completely normal to the untrained eye.
#>

# Encrypt all files ending "*.txt" within specified directory using (AES256 + GCM)
# then adds base64 encoding before deleting the original input file.
set-location $folderPath
Get-ChildItem | Protect-MKFile -Base64 -Certificate $cert -DeleteOriginal

Get-Content "passwords.enc"

# Now that we have each file encrypted, we're going to create a zip archive which itself is also
# password protected but will make for easier transport

## First we'll use 7Zip4Powershell module to create a traditional zip archive as Compress-Archive does not offer a -Password option
Get-ChildItem $folderPath\*.enc |
	Compress-7Zip -ArchiveFileName icod.zip -Format Zip -Password "Data_Privacy_2024"
## Next we'll repeat but this time save as SevenZip format
Get-ChildItem $folderPath\*.enc |
	Compress-7Zip -ArchiveFileName icod.7z -Format SevenZip -Password "Data_Privacy_2024" -EncryptFilenames

# To see the list of files within the encrypted archive
Get-7Zip -ArchiveFileName icod.zip | Select-Object FileName, Size -First 5
Get-7Zip -ArchiveFileName icod.7z | Select-Object FileName, Size -First 5
Get-7Zip -ArchiveFileName icod.7z -Password "Data_Privacy_2024" |
	Select-Object FileName, Size -First 5

# Let's now read this password protected archive containing our encrypted files and try to hide inside an image
$fileBytes = [System.IO.File]::ReadAllBytes("$folderPath\icod.7z")

# Printing just the first few bytes to give you an idea of what the output looks like at this stage
$fileBytes[0..10]

# Convert the byte array to a Base64 Encoded string
$base64String = [Convert]::ToBase64String($fileBytes)
$base64String

$CoverFile = "C:/labsources/sampledata/images/screenshot-2.jpg"
$StegoFile = "C:/labsources/sampledata/images/screenshot-2a.jpg"
$param = @{
	Message   = $base64String
	CoverFile = $CoverFile
	StegoFile = $StegoFile
	ColorChannel = "RGB"
	BitsPerChannel = 2
}
Hide-MKPixel @param

Start-Process $CoverFile
Start-Process $StegoFile

Compare-Object -ReferenceObject (Get-FileHash $CoverFile).Hash -DifferenceObject (Get-FileHash $StegoFile).Hash

# We'll once again print just the first few bytes to validate
$stegoFileBytes = [Convert]::FromBase64String($(Show-MKPixel -StegoFile "C:/labsources/sampledata/images/screenshot-2a.jpg" -cc "B" -bpc 2))
$stegoFileBytes[0..10]

# Write the byte array back to archive file
[System.IO.File]::WriteAllBytes("$folderPath\stego-icod.7z", $stegoFileBytes)

# Let's quickly verify the archive itself seems ok
Get-7Zip -ArchiveFileName "$folderPath\stego-icod.7z" -Password "Data_Privacy_2024" |
	Select-Object FileName, Size -First 5

# Now we simply extract the encrypted files
Expand-7Zip -ArchiveFileName icod.7z -TargetPath ./7z-enc -Password "Data_Privacy_2024"

# Finally, let's decrypt the files and make sure our data is still intact
# Note: Always make sure the param options match those that were used during encryption
#Ex:
Get-ChildItem $folderPath\7z-enc\*.enc | Unprotect-MKFile -Certificate $cert

#region Forgot Something
Get-ChildItem $folderPath\7z-enc\*.enc | Unprotect-MKFile -Certificate $cert -Base64 -DeleteOriginal
Get-Content "$folderPath\passwords.enc"
Get-Content "$folderPath\7z-enc\passwords.txt"
#endregion
#endregion




#region Other Notables (Time Permitting)
exiftool C:\labsources\sampledata\images\screenshot*.jpg -EXIF:All
Start-Process C:/labsources/sampledata/images/screenshot-1.jpg
exiftool C:\labsources\sampledata\images\screenshot-1 -GPS*
Start-Process chrome "https://www.google.com/maps/"
#19.154690 N, 87.27330 W

#endregion