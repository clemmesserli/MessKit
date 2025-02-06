function Get-MKSecretSantaList {
	<#
	.SYNOPSIS
	Generates a unique list of gift givers and gift receivers based on a single list of names.
	.DESCRIPTION
	Get-MKSecretSantaList is an advanced function that generates a unique list of gift givers
	and gift receivers based on a single list of names.
	.PARAMETER Name
	The name of the person. A minimum of 2 names must be provided.
	.EXAMPLE
	Get-MKSecretSantaList -Name 'Charlie Brown', 'Snoopy', 'Woodstock'
	.EXAMPLE
	Get-MKSecretSantaList -Name (Get-Content C:\temp\names.txt)
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateCount(2, [int]::MaxValue)]
		[string[]]$Name
	)

	# Shuffle the list of names
	$shuffledNames = $Name | Get-Random -Count $Name.Count

	# Initialize the Secret Santa list
	$secretSantaList = [System.Collections.ArrayList]::new()

	# Assign each person a Secret Santa
	for ($i = 0; $i -lt $shuffledNames.Count; $i++) {
		$giver = $shuffledNames[$i]
		$receiver = $shuffledNames[($i + 1) % $shuffledNames.Count]

		# Ensure no one is assigned their own name
		if ($giver -eq $receiver) {
			# Swap with the next person in the shuffled list
			$nextIndex = ($i + 1) % $shuffledNames.Count
			$temp = $shuffledNames[$i]
			$shuffledNames[$i] = $shuffledNames[$nextIndex]
			$shuffledNames[$nextIndex] = $temp
			$receiver = $shuffledNames[$i]
		}

		# Add PSCustomObject to the ArrayList
		$null = $secretSantaList.Add([PSCustomObject]@{
				Giver    = $giver
				Receiver = $receiver
			})
	}
	$secretSantaList
}