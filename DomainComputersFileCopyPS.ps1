# Backup Configuration Ver. 0.0.0.7
# to do : add params : OK
# add copy-item ; not OK
# add Robocopy // https://www.youtube.com/watch?v=099Df3jCPBI //
 
param (
    [parameter(Position = 0)]
    [string]$BackupSourcePath = "d$", 
    [parameter(Position = 1)]
    [string]$BackupDestinationRoot = "J:\Projects\powershell\data", 
    [parameter(Position = 2)]
    [string]$backupFileExt = "*.doc? *.xls?"  ,  # "*.doc? *.ppt? *.xls?",
    [parameter(Position = 3)]
    [string]$ou_1 = "staff"  
)
$logFilePath =  Get-Location
$BackupSource = $BackupSourcePath # no file extentions then using RoboCopy
#-----------------
#$CopyUsersDir = $True
$IfCompress = $true # If not test make it $True
$YearName = (Get-Date).ToString("yyyy")
$MonthName= [datetime]::Now.Month
$DayName = [datetime]::Now.DayOfWeek 
$flDay = $true # Put in dedestination day of week
$flOU = $true  # Put in dedestination OU name

# Get the domain distinguished name
#$domain = Get-ADDomain
#$DomainName  = $domain.DistinguishedName


#---------------------------


$OU = Get-ADOrganizationalUnit -Filter "Name -eq '$ou_1'" -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
$LogFile = [string]::Format("{0}\{1}_{2}_backup_log.txt",$logFilePath,$YearName,$MonthName)        # Log file path

# Define the OU Distinguished Name (Modify as needed)

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
    $SourcePath = "'\\$Computer\$BackupSource'"
    
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
        #robocopy $source $DestinationPath  $backupFileExt  /S /COPY:DATSO /UNILOG+:$logfilepath\robolog.txt /R:2 /W:5 /NFL /NDL

        # $RoboCopyParams = "  /S /COPY:DATSO /UNILOG+:robolog.txt /R:2 /W:5 /NFL /NDL"
        # OK : Robocopy.exe "\\$Computer\d$\" $DestinationPath $backupFileExt /S /COPY:DATSO /UNILOG+:robolog.txt /R:2 /W:5 /NFL /NDL
        # not Robocopy.exe = "\\$Computer\$BackupSource " "$DestinationPath "  "$backupFileExt "  "/S /COPY:DATSO /UNILOG+:robolog.txt /R:2 /W:5 /NFL /NDL"
        # Log success

        Robocopy.exe "\\$Computer\d$\" $DestinationPath $backupFileExt /S /COPY:DATSO /UNIL:robolog.txt  /V /XA:SH /XJ #/R:2 /W:5 /NFL /NDL
        Robocopy.exe "\\$Computer\c$\users\" $DestinationPath\usersC $backupFileExt /S /COPY:DATSO /UNILOG+:robolog.txt  /V /XA:SH /XJ #/R:2 /W:5 /NFL /NDL

        Add-Content -Path $LogFile -Value "$(Get-Date) - Backup successful for $Computer with source : "  # +$SourcePath+" , destination : "+destination
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
