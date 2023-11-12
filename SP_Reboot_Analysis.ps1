# Specify the file paths
$logFilePath = "TRiiAGE_Analysis.txt"
$spLogFilePath = "TRiiAGE_SPlogs.txt"
$timelineFilePath = "TRiiAGE_Timeline.txt"
$emcLogFilePath = ".\spb\EMC\backend\log_shared\EMCSystemLogFile.log"
$safeNativeLogFilePath = ".\spa\EMC\C4Core\log\c4_safe_native.log"
$spaFilePath = "SPA_fbecli_exe_ccollectall.txt"
$spbFilePath = "SPB_fbecli_exe_ccollectall.txt"
$outputFolder = ".\Analysis"
$outputFilePath = Join-Path $outputFolder "Evidence.txt"
$pattern = "NO_RESOURCES"

# Check if the output folder exists, if not, create it
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Read the content of the log file
$logContent = Get-Content $logFilePath -Raw

# Define the patterns for the log file
$patternStart = "ARRAY CONFIGURATION INFORMATION"
$patternEnd = "No installed hotfixes."

# Use regex to extract ARRAY CONFIGURATION INFORMATION, using above patterns
$matchedTextLog = [regex]::Match($logContent, "(?s)$patternStart(.*?)$patternEnd").Groups[1].Value

# Append ARRAY CONFIGURATION INFORMATION in Evidence.txt file
$plainText = @"
**********************************************************************************************
ARRAY CONFIGURATION INFORMATION [ArrayInfo Script]
**********************************************************************************************

"@
		
	$plainText | Out-File -FilePath "$outputFolder\Evidence.txt" -Append
$matchedTextLog	| Out-File -FilePath "$outputFolder\Evidence.txt" -Append


# Define the patterns to extract SP BOOT HISTORY INFORMATION 
$patternStart = "SP BOOT HISTORY INFORMATION"
$patternEnd = "PROCESS GROWTH INFORMATION "

# Use regex to extract SP BOOT HISTORY INFORMATION, using above patterns
$matchedTextboot = [regex]::Match($logContent, "(?s)$patternStart(.*?)$patternEnd").Groups[1].Value


# Append ARRAY CONFIGURATION INFORMATION in Evidence.txt file
$plainText = @"

**********************************************************************************************
SP BOOT HISTORY INFORMATION                                                    [Reboot script]
**********************************************************************************************

"@
		
	$plainText | Out-File -FilePath "$outputFolder\Evidence.txt" -Append
$matchedTextboot | Out-File -FilePath "$outputFolder\Evidence.txt" -Append




# Read the content of the SPA file
$spaContent = Get-Content $spaFilePath -Raw

# Define the patterns for the SPA file
$patternStartSPA = "FBECLI> sptime:"
$patternEndSPA = "FBECLI> Enclstat:"

# Use regex to extract text between the patterns
$matchedTextSPA = [regex]::Match($spaContent, "(?s)($patternStartSPA.*?$patternEndSPA)").Groups[1].Value

# Append instances from SPA_fbecli_exe_ccollectall.txt in Evidence.txt file
$plainText = @"

***********************************************
From SPA_fbecli_exe_ccollectall.txt:-
***********************************************

"@
		
	$plainText | Out-File -FilePath "$outputFolder\Evidence.txt" -Append
$matchedTextSPA | Out-File -FilePath "$outputFolder\Evidence.txt" -Append




# Read the content of the SPB file
$spbContent = Get-Content $spbFilePath -Raw

# Define the patterns for the SPB file
$patternStartSPB = "FBECLI> sptime:"
$patternEndSPB = "FBECLI> Enclstat:"

# Use regex to extract text between the patterns
$matchedTextSPB = [regex]::Match($spbContent, "(?s)$patternStartSPB(.*?)$patternEndSPB").Groups[1].Value


# Append instances from SPB_fbecli_exe_ccollectall.txt in Evidence.txt file
$plainText = @"

***********************************************
From SPB_fbecli_exe_ccollectall.txt:-
***********************************************

"@
		
	$plainText | Out-File -FilePath "$outputFolder\Evidence.txt" -Append
$matchedTextSPB | Out-File -FilePath "$outputFolder\Evidence.txt" -Append



# Defining pattern to matched in Evidence.txt to identify if SP really rebooted or this is any False alert.
$patternSP = "Total\sReboots:\s+[1-9][0-9]*"

# Read the content of the Evidence.txt file and find lines containing the pattern defined above
$falseOrTrue = Get-Content -Path "$outputFolder\Evidence.txt" | Where-Object { $_ -match $patternSP }

# Check if any matches were found
if ($falseOrTrue.Count -eq 0) {
    # Output the healthy message to Analysis\Summary-Action_Plan.txt
	
	$summaryContent = @"
Summary : 
We have analyzed the logs and found that the array is healthy.
No hardware issue found.
All SP reboot instances found.
It implies that SP has not rebooted and this is a false alert.
		
Action plan :
-- As the array is operating normally, No further actions are required on this SR.
-- Share the findings with the customer and ask for closure permission.
-- Once customer approves, The case can be archived.

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt" -Append
	Write-Host "Summary saved to $outputFolder\Summary-Action_Plan.txt" -Append
	
} else {
	
	
	#Read the content of the file C4Core\log\c4_safe_native.log
	$logContent = Get-Content $safeNativeLogFilePath

	# Search for the pattern "CSX RT:" in C4Core\log\c4_safe_native.log
	$matches = $logContent | Where-Object { $_ -match "CSX RT:"}

# Append instances from C4Core\log\c4_safe_native.log in Evidence.txt file
$plainText = @"


***********************************************
Output from \spa\EMC\C4Core\log\c4_safe_native.log:-
***********************************************

"@
		
	$plainText | Out-File -FilePath "$outputFolder\Evidence.txt" -Append
	$matches | Out-File -FilePath "$outputFolder\Evidence.txt" -Append
	

#Read the content of the output file Evidence.txt
$fileContent = Get-Content -Path $outputFilePath -Raw

# Search for the pattern "NO_RESOURCES" in each line of the Evidence.txt"
$matches = $fileContent | Where-Object { $_ -match $pattern }

# Check if any matches were found
if ($matches.Count -eq 0) {
    # Output the final message to Summary-Action_Plan.txt
	
	$summaryContent = @"
Summary :

We have analyzed the logs and found the Storage Processor got rebooted.
However, The cause of SP Panic is not due to SupportAssist issue described in KB#000216765.

Next Action for the Engineer :
Collect required evidences from this output file and evidence file.
Escalate this issue with the Engineering Team for the detailed RCA.

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt" -Append
    Write-Host "Faulted lines appended to $outputFilePath" -Append
	
} else {

    # Prepare summary and Action Plan; and write to Analysis\Summary-Action_Plan.txt
	$summaryContent = @"
Summary :

We have analyzed and found that SP got rebooted due to below cause :

Cause : An issue with the SupportAssist network check command is generating zombie curl processes which causes a resource leak, resulting in a storage processor (SP) panic due to "No Resources" after approximately 2 months of runtime with a two SCG configuration or after approximately 4 months of runtime with a single SCG configuration, or direct connect.
The panic should only occur on the primary SP running the ESE process and following the panic the resources are released.

Workaround : The Workaround suggested for this panic is mentioned in below KB article :
https://www.dell.com/support/kbdoc/en-us/000216765

Permanent Fix:
This issue is fixed in Unity Operating Environment (OE) version 5.3.1.0.5.008.

Hence, We recommend customer to upgrade the array to latest version.
https://www.dell.com/support/kbdoc/en-us/000070507/dell-emc-unity-minimum-unity-oe-code-release-eligible-for-root-cause-analysis-user-correctable


Next Actions for the Engineer :
-- Share the findings, Evidences, Cause, Workaround and Permanent Fix with the customer.
-- Close this SR with customer's permission.

"@
		
	$summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt" -Append
    Write-Host "Faulted lines appended to $outputFilePath" -Append
}

}