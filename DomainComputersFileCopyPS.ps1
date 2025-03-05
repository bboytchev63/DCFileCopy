
# Backup Configuration
$BackupSourcePath = "D$\My Documents\"   # Path to backup (relative to each machine)
$backupFileExt = "*.doc*"
$BackupSource = $BackupSourcePath+$backupFileExt
# Define Domain Name 
$DomainName ="DC=court-sh,DC=local"

# For testing
$Test = $true 
$IfCompress = $true # If not test make it $True
$ouRoot = "court-sh"  # OU Root
#---------------------------
# Define OU Root name and sub Name 
if ($Test -eq $false) {
    $ou_1 = "magistrati" # OU Level 1    
    $BackupDestinationRoot =  "f:\bak"        # "\\BackupServer\Backup"  # Central backup location (Modify as needed)
    $LogFile = "f:\bak\backup_log.txt"        # Log file path
}
else {  ###### For Test ######
    $ou_1 = "secretaries" # OU Level 1    
    $BackupDestinationRoot =  "J:\Projects\powershell\data" 
    $LogFile = "J:\Projects\powershell\data\backup_log.txt"        
}
$OUName = "OU=$ou_1,OU=$ouRoot"

# Define the OU Distinguished Name (Modify as needed)
$OU = "$OUName,$DomainName"
#---------------------------
$DayName = [datetime]::Now.DayOfWeek 
$YearMontNames =[datetime]::Now.Year+[datetime]::Now.Month
$flDay = $true # Put in dedestination day of week
$flOU = $true  # Put in dedestination OU name
$LogFile = $YearMontNames+$LogFile

# Ensure log directory exists
$LogDir = Split-Path -Path $LogFile -Parent
If (!(Test-Path -Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force }

# Get list of computers from Active Directory
Import-Module ActiveDirectory

Add-Content -Path $LogFile -Value "---------- Start_backup $(Get-Date) ----------"

# Get all enabled computers in the specified OU
$Computers = Get-ADComputer -Filter {Enabled -eq $true} -SearchBase $OU | Select-Object -ExpandProperty Name  # $Computers = Get-ADComputer -Filter {Enabled -eq $true} | Select-Object -ExpandProperty Name

# Iterate over each computer and attempt backup
foreach ($Computer in $Computers) {
    $SourcePath = "\\$Computer\$BackupSource"
    
    # put day of week into destination path
    if ($flDay)  {
        if ($flOU) {   
            $DestinationPath = "$BackupDestinationRoot\$ou_1\$DayName\$Computer"  
        }
        else {$DestinationPath = "$BackupDestinationRoot\$DayName\$Computer" }
    }
    else {
        $DestinationPath = "$BackupDestinationRoot\$Computer" 
        }
    
    # Check if computer is online
    if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        # Ensure destination folder exists
        If (!(Test-Path -Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force
        }

        # Perform backup using robocopy
        # robocopy $SourcePath $DestinationPath /E /COPY:DAT /LOG+:$LogFile /R:2 /W:5
        xcopy $SourcePath $DestinationPath /S /D /Y /Z 
        # Log success
        Add-Content -Path $LogFile -Value "$(Get-Date) - Backup successful for $Computer"
    } else {
        # Log failure
        Add-Content -Path $LogFile -Value "$(Get-Date) - Skipping $Computer (Offline)"
    }
}

# Archive files with standart PS command
Add-Content -Path $LogFile -Value "Start archive $(Get-Date)"
if ($IfCompress) {
    if ( $flDay ) { 
        if ($flOU) {
            Compress-Archive -Path "$BackupDestinationRoot\$ou_1\$dayname" -Update -DestinationPath $BackupDestinationRoot\$ou_1$dayName.zip -CompressionLevel Optimal
        }
        else {
            Compress-Archive -Path "$BackupDestinationRoot\" -Update -DestinationPath $BackupDestinationRoot\$dayName.zip -CompressionLevel Optimal
        }
         
    
    }
     
    Add-Content -Path $LogFile -Value "- End Archive, backup [$ouRoot'\'$ou_1] $(Get-Date) -"
    # Add-Content -Path $LogFile -Value  "$BackupDestinationRoot\$ou_1\$dayname"
}
Write-Host "Backup process completed. Check log:  + $LogFile " 
