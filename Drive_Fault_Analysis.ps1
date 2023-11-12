# Specify the file paths
$logFilePath = "TRiiAGE_Analysis.txt"
$spLogFilePath = "TRiiAGE_SPlogs.txt"
$emcLogFilePath = ".\spb\EMC\backend\log_shared\EMCSystemLogFile.log"
$spaFilePath = "SPA_fbecli_exe_ccollectall.txt"
$spbFilePath = "SPB_fbecli_exe_ccollectall.txt"
$outputFolder = ".\Analysis"
$outputFilePath = Join-Path $outputFolder "Evidence.txt"
$pattern = "Disk\s[0-9]+_[0-9]+_[0-9]+ taken offline\. Reinsert the drive\. SN:[A-Za-z0-9]+ TLA:[0-9]+"


# Check if the output folder exists, if not, create it
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Read the content of the log file
$logContent = Get-Content $logFilePath -Raw

# Define the patterns for the log file
$patternStart = "ARRAY CONFIGURATION INFORMATION"
$patternEnd = "No installed hotfixes."

# Use regex to extract text between the patterns, including the patterns
$matchedTextLog = [regex]::Match($logContent, "(?s)($patternStart.*?$patternEnd)").Groups[1].Value

# Read the content of the SPA file
$spaContent = Get-Content $spaFilePath -Raw

# Define the patterns for the SPA file
$patternStartSPA = "FBECLI> sptime:"
$patternEndSPA = "FBECLI> Enclstat:"

# Use regex to extract text between the patterns
$matchedTextSPA = [regex]::Match($spaContent, "(?s)$patternStartSPA(.*?)$patternEndSPA").Groups[1].Value

# Read the content of the SPB file
$spbContent = Get-Content $spbFilePath -Raw

# Define the patterns for the SPB file
$patternStartSPB = "FBECLI> sptime:"
$patternEndSPB = "FBECLI> Enclstat:"

# Use regex to extract text between the patterns
$matchedTextSPB = [regex]::Match($spbContent, "(?s)$patternStartSPB(.*?)$patternEndSPB").Groups[1].Value

# Check if any matches were found in all three files
if (-not [string]::IsNullOrWhiteSpace($matchedTextLog) -and -not [string]::IsNullOrWhiteSpace($matchedTextSPA) -and -not [string]::IsNullOrWhiteSpace($matchedTextSPB)) {
    # Combine the text from all three files with 2 empty lines in between
    $combinedText = "$matchedTextLog`n`n$matchedTextSPA`n`n$matchedTextSPB"

    # Append the result to the Evidence.txt file
    $combinedText | Out-File -FilePath $outputFilePath -Append
    Write-Host "Text from all three files appended to $outputFilePath"
} else {
    Write-Host "No matching text found in one or more files."
}


# Read the content of the Evidence.txt file and find lines containing the keyword "EnclFaultLedStatus: ON"
$faultInstance = Get-Content -Path "$outputFolder\Evidence.txt" | Where-Object { $_ -match "EnclFaultLedStatus: ON"}

# Check if any matches were found
if ($faultInstance.Count -eq 0) {
    # Output the healthy message to Analysis\Summary-Action_Plan.txt
	
	$summaryContent = @"
Summary : 
We have analyzed the logs and found that the array is healthy.
No hardware issue found.
All drives are in healthy state.
No replacement is required.
		
Action plan :
-- As the array is operating normally, No further actions are required on this SR.
-- Share the findings with the customer and ask for closure permission.
-- Once customer approves, The case can be archived.

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt"
	Write-Host "Summary saved to $outputFolder\Summary-Action_Plan.txt"
	
} else {
	# Read the content of the log file and find lines containing the keyword "offline"
	$logFileContent = Get-Content -Path $spLogFilePath | Where-Object { $_ -match "offline" }
	
	$logResult = "`n`n" + ($logFileContent -join "`n") + "`n"
    $logResult | Out-File -FilePath $outputFilePath -Append -Force
    Write-Host "Faulted lines appended to $outputFilePath"


# Read the content of the input file
$fileContent = Get-Content -Path $outputFilePath -Raw

# Use Select-String to find matches based on the pattern defined in starting of file to identify the faulted drive and part number
$matches = $fileContent | Select-String -Pattern $pattern -AllMatches | ForEach-Object { $_.Matches.Value }

# Print each match on a new line
$matches | ForEach-Object { Write-Host $_ }

    # Prepare summary and Action Plan; and write to Analysis\Summary-Action_Plan.txt
	$summaryContent = @"
Summary :

We have analyzed the logs and found the below part is faulted.
$matches

Action Plan :
CE needs to go onsite and replace the drive [Refer drive location from above summary] with part number [Refer Part Number from above summary].

Drop an email to customer and ask below details , so that we can create the work order accordingly. 

1. Kindly confirm if you need technician onsite to perform the replacement. 
2. Please share the primary contact info. (Name, email, Phone) 
3. Kindly Share your complete address with Pincode. 

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt"
    Write-Host "Faulted lines appended to $outputFilePath"
}

