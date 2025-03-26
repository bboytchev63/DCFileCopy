rem [0] $BackupSourcePath 
rem [1] $BackupDestinationRoot
rem [2] $backupFileExt    // *.doc? *.xls? *.ppt? ... 
rem [3] $ou1

powershell .\DomainComputersFileCopyPS.ps1 d$\ J:\Projects\powershell\data *.ppt? "staff" 