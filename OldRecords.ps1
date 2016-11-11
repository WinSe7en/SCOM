#Import PowerShell Modules 
import-module OperationsManager
import-module ActiveDirectory

$domain = "dc02du.du.edu"
#$domain = "dc01cair.cair.du.edu"
$DaysInactive = 90  
$time = (Get-Date).Adddays(-($DaysInactive))
#$SearchBase = "dc=cair,DC=DU,DC=EDU"
$SearchBase = "ou=DU Service Accounts,ou=uts,DC=DU,DC=EDU"

#Connect to OpsMgr Management Group
Start-OperationsManagerClientShell -ManagementServerName: "scomvm02.du.edu" -PersistConnection: $true -Interactive: $true;

#--------------------------------------------------
#Read agents into an array (so we query OpsMgr only once)
#--------------------------------------------------

$Agents = get-scomagent 

ForEach($Agent in $Agents) {

$AgentName = $Agent.DisplayName.ToString()
[array]$AgentList = $AgentList + $AgentName + ','
}

#------------------------------------------------------------
#Retrieve computers from Active Directory
#Check each to see if it appears in the list of OpsMgr agents 
#------------------------------------------------------------

Function Run-ADAgentGapRpt { 

    param([parameter(Mandatory=$true)]$SearchDC,[parameter(Mandatory=$true)]$SearchBase)

    $FileHeader = "OpsMgr Agent Gap Report"
   $FileHeader | out-file "c:\temp\ADAgentGap.csv" 

    $ADQuery = get-ADComputer -filter { OperatingSystem -Like '*Windows Server*' -and LastLogonTimeStamp -gt $time} `
    -Server $SearchDC -SearchBase   $SearchBase 

     ForEach($Comp in $ADQUery) {

        $InstallStatus = $AgentList -contains $Comp.DNSHostName 

            If ($InstallStatus -eq $true) {
            Write-host "Agent is already installed on " $Comp.DNSHostName 
            }

    else {

         $Comp.DNSHostName | out-file "c:\temp\ADAgentGap.csv" -Append -NoClobber

     }
  }
}

#Call the function with DC and distinguished name of root search OU/ container
Run-ADAgentGapRpt -SearchDC $domain -SearchBase $SearchBase