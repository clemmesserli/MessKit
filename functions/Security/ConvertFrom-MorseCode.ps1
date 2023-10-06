Function ConvertFrom-MorseCode {
	<#
    .SYNOPSIS
        Create plain text from morse code.
    .EXAMPLE
        ConvertFrom-MorseCode -String '-.-. .- .-.. .-.. / ----. .---- .---- -.-.--'
	.EXAMPLE
		ConvertFrom-MorseCode -String '.- -... -.-. .---- ..--- ...-- .--.-. .--. ----- .-- . .-. ... .... ...-- .-.. .-.. .-.-.- .-. ----- -.-. -.- ... -.-.--'
    .EXAMPLE
        ConvertFrom-MorseCode -String '.--. ----- .-- . .-. ... .... ...-- .-.. .-.. / .-. ----- -.-. -.- ... -.-.--' | Set-Clipboard
	.EXAMPLE
		ConvertFrom-MorseCode -String (Get-Content C:\Scripts\MorseCode.txt) | Out-File C:\Scripts\PlainText2.txt
    #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[String[]]$String
	)

	$data = @()
	ForEach ($s In $String) {
		$line = @()
		foreach ($char in $s.Split(' ')) {
			switch ($char) {
				#region Upper-Case Letters
				".-" { $letter = "A" }
				"-..." { $letter = "B" }
				"-.-." { $letter = "C" }
				"-.." { $letter = "D" }
				"." { $letter = "E" }
				"..-." { $letter = "F" }
				"--." { $letter = "G" }
				"...." { $letter = "H" }
				".." { $letter = "I" }
				".---" { $letter = "J" }
				"-.-" { $letter = "K" }
				".-.." { $letter = "L" }
				"--" { $letter = "M" }
				"-." { $letter = "N" }
				"---" { $letter = "O" }
				".--." { $letter = "P" }
				"--.-" { $letter = "Q" }
				".-." { $letter = "R" }
				"..." { $letter = "S" }
				"-" { $letter = "T" }
				"..-" { $letter = "U" }
				"...-" { $letter = "V" }
				".--" { $letter = "W" }
				"-..-" { $letter = "X" }
				"-.--" { $letter = "Y" }
				"--.." { $letter = "Z" }
				#endregion Upper-Case Letters

				#region Numbers
				"-----" { $letter = "0" }
				".----" { $letter = "1" }
				"..---" { $letter = "2" }
				"...--" { $letter = "3" }
				"....-" { $letter = "4" }
				"....." { $letter = "5" }
				"-...." { $letter = "6" }
				"--..." { $letter = "7" }
				"---.." { $letter = "8" }
				"----." { $letter = "9" }
				#endregion Numbers

				#region Symbols
				"-.-.--" { $letter = "!" }
				".--.-." { $letter = "@" }
				"...-..-" { $letter = "`$" }
				".-..." { $letter = "&" }
				"-...-" { $letter = "=" }
				".-.-." { $letter = "+" }
				"-....-" { $letter = "-" }
				"-..-." { $letter = "/" }
				".-.-.-" { $letter = "." }
				"--..--" { $letter = "," }
				"-.-.-." { $letter = ";" }
				"---..." { $letter = ":" }
				"..--.-" { $letter = "_" }
				"-.--." { $letter = "(" }
				"-.--.-" { $letter = ")" }
				".----." { $letter = "`'" }
				".-..-." { $letter = "`"" }
				"..--.." { $letter = "?" }
				"..-.-" { $letter = "¿" }
				"--...-" { $letter = "¡" }
				"/" { $letter = " " }
				#endregion Symbols
			}
			$line += $letter
		}
		$data += $line -join ('')
	}
	$data -join (' ')
}