Function ConvertTo-MorseCode {
	<#
    .SYNOPSIS
        Create Morse Code from input string.
    .EXAMPLE
        ConvertTo-MorseCode -String 'SOS'
    .EXAMPLE
        ConvertTo-MorseCode -String 'Call (123) 456-7689 - I Have Fallen and Cannot Get Up.'
    .EXAMPLE
        ConvertTo-MorseCode -String 'abc123@p0wersh3ll.r0cks!' | Set-Clipboard
	.EXAMPLE
		ConvertTo-MorseCode -String (Get-Content C:\Scripts\PlainText.txt) | Out-File C:\Scripts\MorseCode.txt
    #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[String[]]$String
	)

	$data = @()
	ForEach ($s In $String) {
		$line = @()
		foreach ($char in $s.ToUpper().ToCharArray()) {
			switch ($char) {
				#region Upper-Case Letters
				"A" { $letter = ".-" }
				"B" { $letter = "-..." }
				"C" { $letter = "-.-." }
				"D" { $letter = "-.." }
				"E" { $letter = "." }
				"F" { $letter = "..-." }
				"G" { $letter = "--." }
				"H" { $letter = "...." }
				"I" { $letter = ".." }
				"J" { $letter = ".---" }
				"K" { $letter = "-.-" }
				"L" { $letter = ".-.." }
				"M" { $letter = "--" }
				"N" { $letter = "-." }
				"O" { $letter = "---" }
				"P" { $letter = ".--." }
				"Q" { $letter = "--.-" }
				"R" { $letter = ".-." }
				"S" { $letter = "..." }
				"T" { $letter = "-" }
				"U" { $letter = "..-" }
				"V" { $letter = "...-" }
				"W" { $letter = ".--" }
				"X" { $letter = "-..-" }
				"Y" { $letter = "-.--" }
				"Z" { $letter = "--.." }
				#endregion Upper-Case Letters

				#region Numbers
				"0" { $letter = "-----" }
				"1" { $letter = ".----" }
				"2" { $letter = "..---" }
				"3" { $letter = "...--" }
				"4" { $letter = "....-" }
				"5" { $letter = "....." }
				"6" { $letter = "-...." }
				"7" { $letter = "--..." }
				"8" { $letter = "---.." }
				"9" { $letter = "----." }
				#endregion Numbers

				#region Symbols
				"!" { $letter = "-.-.--" }
				"@" { $letter = ".--.-." }
				"`$" { $letter = "...-..-" }
				"&" { $letter = ".-..." }
				"=" { $letter = "-...-" }
				"+" { $letter = ".-.-." }
				"-" { $letter = "-....-" }
				"/" { $letter = "-..-." }
				"." { $letter = ".-.-.-" }
				"," { $letter = "--..--" }
				";" { $letter = "-.-.-." }
				":" { $letter = "---..." }
				"_" { $letter = "..--.-" }
				"(" { $letter = "-.--." }
				")" { $letter = "-.--.-" }
				"`'" { $letter = ".----." }
				"`"" { $letter = ".-..-." }
				"?" { $letter = "..--.." }
				"¿" { $letter = "..-.-" }
				"¡" { $letter = "--...-" }
				" " { $letter = "/" }
				#endregion Symbols
			}
			$line += $letter
		}
		$data += $line -join (' ')
	}
	$data -join (' / ')
}