# Specify the file paths
$logFilePath = "TRiiAGE_Analysis.txt"
$emcLogFilePath = ".\spb\EMC\backend\log_shared\EMCSystemLogFile.log"
$spaFilePath = "SPA_fbecli_exe_ccollectall.txt"
$spbFilePath = "SPB_fbecli_exe_ccollectall.txt"
$outputFolder = ".\Analysis"
$outputFilePath = Join-Path $outputFolder "Evidence.txt"

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


# Read the content of the log file and find lines containing the keyword "faulted"
$logFileContent = Get-Content -Path $emcLogFilePath | Where-Object { $_ -match "faulted" -or $_ -match "Faulted" }

# If there are matching lines, append them to the output file after two empty lines
if ($logFileContent.Count -gt 0) {
    $logResult = "`n`n" + ($logFileContent -join "`n") + "`n"
    $logResult | Out-File -FilePath $outputFilePath -Append -Force
	
	 # Create and write to Analysis\Summary-Action_Plan.txt
	 $faultInstance = Get-Content -Path "$outputFolder\Evidence.txt" | Where-Object { $_ -match "Serial Number"}
	$summaryContent = @"
Summary :

We have analyzed the logs and found the below part is faulted.

$faultInstance

Action Plan :
CE needs to go onsite and perform the below :
-- Need to disable write cache and put the affected SP in service mode.
-- Need to replace the [Faulted Power Supply] with part number [Refer evidence file for the part number].
-- Need to enable the write cache and put the SP in normal mode.

Drop an email to customer and ask below details , so that we can create the work order accordingly. 

1. Kindly confirm if you need technician onsite to perform the replacement. 
2. Please share the primary contact info. (Name, email, Phone) 
3. Kindly Share your complete address with Pincode. 

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt"
	
	
    Write-Host "Faulted lines appended to $outputFilePath"
} else {
     # Create and write to Analysis\Summary-Action_Plan.txt
	$summaryContent = @"
Summary : 
We have analyzed the logs and found that the array is healthy.
No hardware issue found.
All power supplies are in healthy state.
		
Action plan :
-- As the array is operating normally, No further actions are required on this SR.
-- Share the findings with the customer and ask for closure permission.
-- Once customer approves, The case can be archived.

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt"
	Write-Host "Summary saved to $outputFolder\Summary-Action_Plan.txt"
}





