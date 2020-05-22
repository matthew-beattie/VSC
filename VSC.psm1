<#'-----------------------------------------------------------------------------
'Script Name : VSC.psm1  
'Author      : Matthew Beattie
'Email       : mbeattie@netapp.com
'Created     : 2020-05-22
'Description : This code provides Functions for invoking NetApp VSC REST API's.
'            : It also contains functions for invoking VMWare REST API's that
'            : to enumerate vCenter managed object references used by some VSC API's.
'Link        : https://www.netapp.com/us/documentation/virtual-storage-console.aspx
'Disclaimer  : THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
'            : IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
'            : WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
'            : PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR 
'            : ANYDIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
'            : DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
'            : GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
'            : INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
'            : WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
'            : NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
'            : THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'-----------------------------------------------------------------------------#>
#'VSC REST API Functions.
#'------------------------------------------------------------------------------
Function Connect-VSCSession{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Create a hashtable for VSC authetication and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$login = @{};
   [HashTable]$login.Add("vcenterPassword", $credential.GetNetworkCredential().Password)
   [HashTable]$login.Add("vcenterUserName", $credential.GetNetworkCredential().Username)
   $body = $login | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/security/user/login"
   #'---------------------------------------------------------------------------
   #'Login to VSC.
   #'---------------------------------------------------------------------------
   [String]$username = $credential.GetNetworkCredential().Username
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Method POST -Body $body -ErrorAction Stop
      Write-Host "Authenticated to VSC ""$VSC"" using URI ""$uri"" as VMWare vCenter user ""$userName"""
   }Catch{
      Write-Warning -Message $("Failed Authenticating to VSC ""$VSC"" using URI ""$uri"" as VMWare vCenter user ""$userName"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VMWare session ID from the response to return.
   #'---------------------------------------------------------------------------
   [String]$sessionID = $response.vmwareApiSessionId
   If([String]::IsNullOrEmpty($sessionID)){
      Write-Warning -Message "Failed Authenticating to VSC ""$VSC"" using URI ""$uri"" as VMWare vCenter user ""$userName"""
      Return $Null;
   }
   Return $sessionID;
}#End Function Connect-VSCSession.
#'------------------------------------------------------------------------------
Function Disconnect-VSCSession{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Logout of the VSC.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/security/user/logout"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -ContentType "application/json" -ErrorAction Stop
      Write-Host "Logged out of VSC ""$VSC"" Session ID ""$sessionID"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed logging out of VSC ""$VSC"" VSC Session ID ""$SessionID"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $False;
   }
   Return $response;
}#End Function Disconnect-VSCSession.
#'------------------------------------------------------------------------------
Function Get-VSCCapability{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC capabilities.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/product/capabilities"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated VSC capabilities on ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating VSC capabilities on ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCCapability.
#'------------------------------------------------------------------------------
Function Set-VSCCapability{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Capability. Valid values are 'vp' (VASA Provider) or 'sra' (Storage Replication Adapter)")]
      [ValidateNotNullOrEmpty()]
      [ValidateSet("vp","sra")]
      [String]$Capability,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Capability Enabled State")]
      [String]$Enabled,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the datastore body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$capabilities = @{};
   [HashTable]$capabilities.Add("enableCapability", $Enabled)
   [HashTable]$capabilities.Add("password",         $Credential.GetNetworkCredential().Password)
   [HashTable]$capabilities.Add("serviceType",    $($Capability + "Enabled"))
   $body = $capabilities | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC capabilities.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/product/capabilities"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -ContentType "application/json" -ErrorAction Stop
      Write-Host "Set VSC capability ""$Capability"" to ""$Enabled"" on ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting VSC capability ""$Capability"" to ""$Enabled"" on ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCCapability.
#'------------------------------------------------------------------------------
Function Get-VSCService{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC services.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/services"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated VSC services on ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating VSC services on ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VSCService.
#'------------------------------------------------------------------------------
Function Restart-VSCService{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Services. Valid values are 'VSC' (Virtual Storage Console), 'VP' (VASA Provider) or 'ALL'")]
      [ValidateNotNullOrEmpty()]
      [ValidateSet("VSC","VP","ALL")]
      [String]$Service
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the services body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$services = @{};
   [HashTable]$services.Add("action", "restart")
   [HashTable]$services.Add("serviceType", $Service)
   $body = $services | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Restart the VSC services.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/services"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method PUT -ContentType "application/json" -ErrorAction Stop
      Write-Host "Restarted VSC service ""$Service"" on ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed restarting VSC service ""$Service"" on ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Restart-VSCService.
#'------------------------------------------------------------------------------
Function Add-VSCStorageCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Storage Cluster Hostname or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Hostname,
      [Parameter(Mandatory = $False, HelpMessage = "The Storage Cluster Port Number")]
      [Int]$Port=443,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to the storage cluster")]
      [ValidateNotNullOrEmpty()]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the services body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$cluster = @{};
   [HashTable]$cluster.Add("nameOrIpAddress", $Hostname)
   [HashTable]$cluster.Add("password",        $Credential.GetNetworkCredential().Password)
   [HashTable]$cluster.Add("port",            $Port.ToString())
   [HashTable]$cluster.Add("username",        $Credential.GetNetworkCredential().Username)
   $body = $cluster | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Restart the VSC services.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -ContentType "application/json" -ErrorAction Stop
      Write-Host "Added VSC Storage Cluster ""$Hostname"" on ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed adding VSC Storage Cluster ""$Hostname"" on ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Add-VSCStorageCluster.
#'------------------------------------------------------------------------------
Function Remove-VSCStorageCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The storage controller managed object reference identifier")]
      [ValidateNotNullOrEmpty()]
      [String]$ClusterID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Remove the VSC storage controller.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters/$ControllerID"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method DELETE -ContentType "application/json" -ErrorAction Stop
      Write-Host "Removed VSC Storage Cluster ""$ControllerID"" on ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed removing VSC Storage Cluster ""$ControllerID"" on ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Remove-VSCStorageCluster.
#'------------------------------------------------------------------------------
Function Get-VSCStorageCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Storage Controller ID")]
      [ValidateNotNullOrEmpty()]
      [String]$ControllerID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters"
   If($ControllerID){
      [String]$uri += "/$ControllerID"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Storage Clusters.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated Storage Clusters for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Storage Clusters for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VSCStorageCluster.
#'------------------------------------------------------------------------------
Function Get-VSCFlexvol{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()] 
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
      [ValidateNotNullOrEmpty()] 
      [String]$ClusterIP,
      [Parameter(Mandatory = $True, HelpMessage = "The vserver name")]
      [ValidateNotNullOrEmpty()] 
      [String]$VserverName,
      [Parameter(Mandatory = $True, HelpMessage = "The storage capability profile name")]
      [Array]$ProfileName,
      [Parameter(Mandatory = $True, HelpMessage = "The protocol name")]
      [ValidateSet("fcp","iscsi","nfs")]
      [String]$Protocol
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/flexvolumes?vserver-name=$VserverName&cluster=$ClusterIP&protocol=$Protocol"
   If($ProfileName){
      ForEach($p In $ProfileName){
         [String]$uri += "&scps=$p"
      }
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the FlexVols.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host $("Enumerated FlexVols on vserver ""$VserverName"" on cluster ""$ClusterIP"" for protocol ""$Protocol"" matching storage capabitility profiles """ + $([String]::Join(", ", $ProfileName)) + """ using URI ""$uri""")
   }Catch{
      Write-Warning -Message $("Failed enumerating FlexVols on vserver ""$VserverName"" on cluster ""$ClusterIP"" for protocol ""$Protocol"" matching storage capabitility profiles """ + $([String]::Join(", ", $ProfileName)) + """ using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null
   }
   Return $response;
}#End Function Get-VSCFlexvol.
#'------------------------------------------------------------------------------
Function Get-VSCDatastoreReport{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Datastores.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/reports/datastores"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated Datastore report on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating Datastore report on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCDatastoreReport.
#'------------------------------------------------------------------------------
Function Get-VSCVMReport{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Virtual Machines.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/reports/virtual-machines"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated Virtual Machine report on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating Virtual Machine report on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCVMReport.
#'------------------------------------------------------------------------------
Function Export-VSCLogs{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Export the logs.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/vsc/exportLogs"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Exported logs for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed exporting logs for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Export-VSCLogs.
#'------------------------------------------------------------------------------
Function Get-VSCPlugin{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC plugin status.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/plugin/vcenter"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCPlugin.
#'------------------------------------------------------------------------------
Function Register-VSCPlugin{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [Int]$VSCPortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC")]
      [ValidateNotNullOrEmpty()]
      [System.Management.Automation.PSCredential]$VSCCredential,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter hostname or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Hostname,
      [Parameter(Mandatory = $False, HelpMessage = "The vCenter port number")]
      [Int]$VcenterPortNumber=443,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to vCenter")]
      [ValidateNotNullOrEmpty()]
      [System.Management.Automation.PSCredential]$VcenterCredential
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for registering VSC and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$registerVsc = @{};
   [HashTable]$vCenter = @{};
   [HashTable]$vCenter.Add("hostname", $Hostname)
   [HashTable]$vCenter.Add("password", $VcenterCredential.GetNetworkCredential().Password)
   [HashTable]$vCenter.Add("port",     $VcenterPortNumber)
   [HashTable]$vCenter.Add("username", $VcenterCredential.GetNetworkCredential().Username)
   [HashTable]$vApp = @{};
   [HashTable]$vCenter.Add("hostname", $VSC)
   [HashTable]$vCenter.Add("password", $VSCCredential.GetNetworkCredential().Password)
   [HashTable]$registerVsc.Add("vcenter", $vCenter)
   [HashTable]$registerVsc.Add("vsc_unified_appliance", $vApp)
   $body = $registerVsc | ConvertTo-Json
   [String]$uri = "https://$VSC`:$VSCPortNumber/api/rest/2.0/plugin/vcenter"
   #'---------------------------------------------------------------------------
   #'Register VSC.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host "Registered VSC ""$VSC"" on vCenter ""$Hostname"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed registering VSC ""$VSC"" on vCenter ""$Hostname"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Register-VSCPlugin.
#'------------------------------------------------------------------------------
Function Unregister-VSCPlugin{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [Int]$PortNumber=8143,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/plugin/vcenter"
   #'---------------------------------------------------------------------------
   #'Unregister VSC.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method DELETE -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host "Unregistered VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed unregistering VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Unregister-VSCPlugin.
#'------------------------------------------------------------------------------
Function Add-VSCDatastoreMount{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VMWare ESX Host managed object reference")]
      [Array]$EsxHostID,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC datastore managed object reference")]
      [String]$DatastoreID,
      [Parameter(Mandatory = $False, HelpMessage = "The datastore type")]
      [ValidateSet("VVOL")]
      [String]$DatastoreType="VVOL"
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the datastore body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$mount = @{};
   [HashTable]$mount.Add("datastoreMoref", $DatastoreID)
   [HashTable]$mount.Add("datastoreType",  $DatastoreType)
   [HashTable]$mount.Add("hostMoref",      $EsxHostID)
   $body = $mount | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/admin/datastore/mount-on-additional-hosts"
   #'---------------------------------------------------------------------------
   #'Mount the datastore on the ESX host.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method PUT -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host $("Mounted datastore ""$DatastoreName"" on ESX host """ + $([String]::Join(", ", $EsxHostID)) + """ in VSC ""$VSC"" using URI ""$uri""")
   }Catch{
      Write-Warning -Message $("Failed Mounting ""$DatastoreName"" on ESX host """ + $([String]::Join(", ", $EsxHostID)) + """ in VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $response;
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC task ID and wait for completion.
   #'---------------------------------------------------------------------------
   [Int]$taskId = $response.taskId
   If($taskId -ne 0){
      $response = Wait-VSCTask -VSC $VSC -PortNumber $PortNumber -SessionID $SessionId -TaskID $taskId
   }Else{
      Write-Warning -Message "Failed enumerating VSC Task ID"
   }
   Return $response;
}#End Function Add-VSCDatastoreMount.
#'------------------------------------------------------------------------------
Function Dismount-VSCDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VMWare ESX Host managed object reference")]
      [Array]$EsxHostID,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC datastore managed object reference")]
      [String]$DatastoreID,
      [Parameter(Mandatory = $False, HelpMessage = "The datastore type")]
      [ValidateSet("VVOL")]
      [String]$DatastoreType="VVOL"
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the datastore body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$mount = @{};
   [HashTable]$mount.Add("datastoreType",  $DatastoreType)
   [HashTable]$mount.Add("hostMoref",      $EsxHostID)
   $body = $mount | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/admin/datastore/$DatastoreID/unmount"
   #'---------------------------------------------------------------------------
   #'Dismount the datastore on the ESX host.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method PUT -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host $("Dismounted datastore ""$DatastoreID"" on ESX host """ + $([String]::Join(", ", $EsxHostID)) + """ in VSC ""$VSC"" using URI ""$uri""")
   }Catch{
      Write-Warning -Message $("Failed dismounting datastore ""$DatastoreID"" on ESX host """ + $([String]::Join(", ", $EsxHostID)) + """ in VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Dismount-VSCDatastore.
#'------------------------------------------------------------------------------
Function Mount-VSCDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VMWare ESX Host managed object reference")]
      [String]$EsxHostID,
      [Parameter(Mandatory = $False, HelpMessage = "The volume container ID")]
      [String]$ContainerID,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The datastore name")]
      [String]$DatastoreName,
      [Parameter(Mandatory = $False, HelpMessage = "The datastore type")]
      [ValidateSet("VVOL")]
      [String]$DatastoreType="VVOL"
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the datastore body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$mount   = @{};
   [HashTable]$mount.Add("containerId",   $ContainerId)
   [HashTable]$mount.Add("datastoreType", "VVOL")
   [HashTable]$mount.Add("hostMoref",     $EsxHostID)
   $body = $mount | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/hosts/datastores/$DatastoreName"
   [String]$mounturi = $uri
   #'---------------------------------------------------------------------------
   #'Mount the datastore on the ESX host.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method PUT -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host "Mounted datastore ""$DatastoreName"" on ESX host ""$EsxHostID"" in VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Mounting ""$DatastoreName"" on ESX host ""$EsxHostID"" in VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $response;
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC task ID and wait for completion.
   #'---------------------------------------------------------------------------
   [Int]$taskId = $response.taskId
   If($taskId -ne 0){
      $response = Wait-VSCTask -VSC $VSC -PortNumber $PortNumber -SessionID $SessionId -TaskID $taskId
   }Else{
      Write-Warning -Message "Failed enumerating VSC Task ID"
   }
   Return $response;
}#End Function Mount-VSCDatastore.
#'------------------------------------------------------------------------------
Function New-VSCVvolDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VMWare ESX Host managed object reference")]
      [String]$EsxHostID,
      [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
      [String]$ClusterIP,
      [Parameter(Mandatory = $True, HelpMessage = "The Vserver name")]
      [String]$VserverName,
      [Parameter(Mandatory = $True, HelpMessage = "The Storage Capability Profile name")]
      [String]$ProfileName,
      [Parameter(Mandatory = $True, HelpMessage = "The Aggregate name")]
      [String]$AggregateName,
      [Parameter(Mandatory = $True, HelpMessage = "The Flexvol Volume name")]
      [String]$VolumeName,
      [Parameter(Mandatory = $True, HelpMessage = "The VVOL name")]
      [String]$VvolName,
      [Parameter(Mandatory = $False, HelpMessage = "The VVOL comment")]
      [String]$Comment,
      [Parameter(Mandatory = $True, HelpMessage = "The Protocol name")]
      [ValidateSet("FCP","ISCSI","NFS")]
      [String]$Protocol
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the flexVol body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$vvol = @{};
   [HashTable]$vvol.Add("clusterIp",      $ClusterIP)
   [HashTable]$vvol.Add("dataStoreType",  "VVOL")
   [HashTable]$vvol.Add("defaultSCP",     $ProfileName)
   If($Comment){
      [HashTable]$vvol.Add("description", $Comment)
   }Else{
      [HashTable]$vvol.Add("description", "")
   }
   [HashTable]$vvol.Add("flexVolSCPMap",  "*")
   [HashTable]$vvol.Add("name",           $VvolName)
   [HashTable]$vvol.Add("protocol",       $Protocol)
   [HashTable]$vvol.Add("targetMoref",    $EsxHostID)
   [HashTable]$vvol.Add("vserverName",    $VserverName)
   $body = $vvol | ConvertTo-Json
   $body = $body.Replace("*", $('{"' + $VolumeName + '":"' + $ProfileName + '"}'))
   $body = $body.Replace("""`{", "{")
   $body = $body.Replace("`}""", "}")
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/hosts/datastores"
   [String]$vvoluri = $uri
   #'---------------------------------------------------------------------------
   #'Create the VVOL.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host "Created VVOL ""$VvolName"" on vserver ""$VserverName"" on cluster ""$ClusterIP"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Creating VVOL ""$VvolName"" on vserver ""$VserverName"" on cluster ""$ClusterIP"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $response;
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC task ID and wait for completion.
   #'---------------------------------------------------------------------------
   Start-Sleep -Seconds 5 #Wait a few seconds for VSC to initiate the task.
   [Int]$taskId = $response.taskId
   If($taskId -ne 0){
      $response = Wait-VSCTask -VSC $VSC -PortNumber $PortNumber -SessionID $SessionID -TaskID $taskId
   }Else{
      Write-Warning -Message "Failed enumerating VSC Task ID"
   }
   Return $response;
}#End Function New-VSCVvolDataStore.
#'------------------------------------------------------------------------------
Function New-VSCFlexvol{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()] 
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
      [String]$ClusterIP,
      [Parameter(Mandatory = $True, HelpMessage = "The Vserver name")]
      [String]$VserverName,
      [Parameter(Mandatory = $True, HelpMessage = "The Storage Capability Profile name")]
      [String]$ProfileName,
      [Parameter(Mandatory = $True, HelpMessage = "The Aggregate name")]
      [String]$AggregateName,
      [Parameter(Mandatory = $True, HelpMessage = "The Volume name")]
      [String]$VolumeName,
      [Parameter(Mandatory = $True, HelpMessage = "The Volume size in GigaBytes")]
      [Int]$SizeGB
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the flexVol body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$volume  = @{};
   [HashTable]$flexVol = @{};
   [HashTable]$volume.Add("clusterIp",      $ClusterIP)
   [HashTable]$flexVol.Add("aggrName",      $AggregateName)
   [HashTable]$flexVol.Add("profileName",   $ProfileName)
   [HashTable]$flexVol.Add("sizeInMB",     $($SizeGB * 1024))
   [HashTable]$flexVol.Add("volumeName",    $VolumeName)
   [HashTable]$volume.Add("flexibleVolume", $flexVol)
   [HashTable]$volume.Add("vServerName",    $VserverName)
   $body = $volume | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/flexvolumes"
   #'---------------------------------------------------------------------------
   #'Create the FlexVol.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host "Created FlexVol ""$VolumeName"" on vserver ""$VserverName"" on cluster ""$Cluster"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Creating FlexVol ""$VolumeName"" on vserver ""$VserverName"" on cluster ""$Cluster"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function New-VSCFlexvol.
#'------------------------------------------------------------------------------
Function Add-VSCFlexvolDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()] 
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
      [String]$ClusterIP,
      [Parameter(Mandatory = $True, HelpMessage = "The Vserver name")]
      [String]$VserverName,
      [Parameter(Mandatory = $True, HelpMessage = "The Storage Capability Profile name")]
      [String]$ProfileName,
      [Parameter(Mandatory = $True, HelpMessage = "The Flexvol Volume name to add to the VVOL datastore")]
      [String]$VolumeName,
      [Parameter(Mandatory = $True, HelpMessage = "The VVOL Volume datastore name that the flexvol will be added to")]
      [String]$DatastoreName
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the flexVol body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$addVol   = @{};
   [HashTable]$scpNames = @{};
   [HashTable]$scpNames.Add("flexVolName", $VolumeName)
   [HashTable]$scpNames.Add("scpName",     $ProfileName)
   [HashTable]$addVol.Add("clusterIP", $ClusterIP)
   [HashTable]$addVol.Add("flexVolSCPNames", @($scpNames))
   [HashTable]$addVol.Add("vserverName", $VserverName)
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/hosts/datastores/$DatastoreName/storage/flexvolumes"
   $body = $addVol | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Add the FlexVol to the VVOL.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method PUT -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host "Added FlexVol ""$VolumeName"" to VVOL Datastore ""$DatastoreName"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed adding FlexVol ""$VolumeName"" to VVOL Datastore ""$DatastoreName"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Add-VSCFlexvolDatastore.
#'------------------------------------------------------------------------------
Function Remove-VSCFlexvolDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()] 
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VVOL Datastore ID")]
      [ValidateNotNullOrEmpty()] 
      [String]$DatastoreID,
      [Parameter(Mandatory = $True, HelpMessage = "The Flexvol volume name to remove from the VVOL datastore")]
      [ValidateNotNullOrEmpty()] 
      [Array]$VolumeName
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the flexVol body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$removeVolumes = @{};
   [HashTable]$removeVolumes.Add("datastoreType", "VVOL")
   [HashTable]$removeVolumes.Add("flexVolNames", $VolumeName)
   $body = $removeVolumes | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/hosts/datastores/$DatastoreID/storage/flexvolumes"
   #'---------------------------------------------------------------------------
   #'Remove the FlexVols from the VVOL.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
      Write-Host $("Removed FlexVols """ + $([String]::Join(",", $VolumeName)) + """ from VVOL Datastore ""$DatastoreID"" using URI ""$uri""")
   }Catch{
      Write-Warning -Message $("Failed removing FlexVols """ + $([String]::Join(",", $VolumeName)) + """ from VVOL Datastore ""$DatastoreID"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Remove-VSCFlexvolDatastore.
#'------------------------------------------------------------------------------
Function Remove-VSCDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC datastore managed object reference")]
      [String]$DatastoreID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/hosts/datastores/$DatastoreID"
   #'---------------------------------------------------------------------------
   #'Remove the datastore.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method DELETE -ContentType "application/json" -ErrorAction Stop
      Write-Host "Deleted datastore ""$DatastoreID"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed deleting datastore ""$DatastoreID"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Remove-VSCDatastore.
#'------------------------------------------------------------------------------
Function Get-VSCScpAggregate{
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
      [String]$ClusterIP,
      [Parameter(Mandatory = $True, HelpMessage = "The Vserver name")]
      [String]$VserverName,
      [Parameter(Mandatory = $True, HelpMessage = "The Storage Capability Profile ID's")]
      [Array]$ProfileID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the aggregates matching the SCP ID's.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/aggregates?cluster=$ClusterIP&vserver-name=$VserverName"
   ForEach($p In $ProfileID){
      [String]$uri += "`&profile-ids=$p"
   }
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host $("Enumerated aggregates match SCP ID's """ + $([String]::Join(",", $ProfileID)) + """ on VSC ""$VSC"" using URI ""$uri""")
   }Catch{
      Write-Warning -Message $("Failed enumerating aggregates match SCP ID's """ + $([String]::Join(",", $ProfileID)) + """ on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCScpAggregate.
#'------------------------------------------------------------------------------
Function Get-VSCDatastore{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $False, HelpMessage = "The datastore name")]
      [String]$DatastoreName,
      [Parameter(Mandatory = $True, HelpMessage = "The datastore type")]
      [ValidateSet("VVOL")]
      [String]$DatastoreType
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Datastores.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/hosts/datastores?datastore-type=$DatastoreType"
   If($DatastoreName){
      [String]$uri += "`&name=$DatastoreName"
   }
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated Datastores on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating Datastores on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCDatastore.
#'------------------------------------------------------------------------------
Function Get-VSCDatastoreCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The SCP profile names")]
      [Array]$ProfileName,
      [Parameter(Mandatory = $True, HelpMessage = "The Protocol")]
      [ValidateSet("nfs","nfs41","iscsi","fcp")]
      [String]$Protocol
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
      "protocol"              = $Protocol
      "profile-names"         = $([String]::Join(",", $ProfileName))
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Datastore Cluster.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/admin/datastore/clusters"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      Write-Host "Enumerated Datastore Cluster on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating Datastore Cluster on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCDatastoreCluster.
#'------------------------------------------------------------------------------
Function Get-VSCCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $False, HelpMessage = "The Controller ID of the cluster to enumerate")]
      [ValidateNotNullOrEmpty()]
      [String]$ControllerID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters"
   If($ControllerID){
      [String]$uri += "/$ControllerID"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Clusters.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      If($ControllerID){
         Write-Host "Enumerated Cluster ID ""$ControllerID"" on VSC ""$VSC"" using URI ""$uri"""
      }Else{
         Write-Host "Enumerated Clusters on VSC ""$VSC"" using URI ""$uri"""
      }
   }Catch{
      If($ControllerID){
         Write-Warning -Message $("Failed Enumerating Cluster ""$ControllerID"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      }Else{
         Write-Warning -Message $("Failed Enumerating Clusters on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      }
   }
   Return $response;
}#End Function Get-VSCCluster.
#'------------------------------------------------------------------------------
Function Add-VSCCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$ClusterIP,
      [Parameter(Mandatory = $False, HelpMessage = "The Cluster Port Number")]
      [Int]$Port=443,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to the Cluster")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the cluster body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$cluster = @{};
   [HashTable]$cluster.Add("nameOrIpAddress", $ClusterIP)
   [HashTable]$cluster.Add("password",        $Credential.GetNetworkCredential().Password)
   [HashTable]$cluster.Add("port",            $Port)
   [HashTable]$cluster.Add("username",        $Credential.GetNetworkCredential().Username)
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters"
   $body = $cluster | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Add the VSC Cluster.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ErrorAction Stop
      Write-Host "Enumerated Clusters for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Clusters for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Add-VSCCluster.
#'------------------------------------------------------------------------------
Function Remove-VSCCluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Controller ID to remove")]
      [ValidateNotNullOrEmpty()]
      [String]$ControllerID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Remove the Cluster from VSC.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters/$ControllerID"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method DELETE -ErrorAction Stop
      Write-Host "Enumerated Clusters for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Clusters for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Remove-VSCCluster.
#'------------------------------------------------------------------------------
Function Get-VSCAggregate{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Cluster ID")]
      [ValidateNotNullOrEmpty()]
      [String]$ClusterID,
      [Parameter(Mandatory = $True, HelpMessage = "The Aggregate name")]
      [ValidateNotNullOrEmpty()]
      [String]$AggregateName
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
      "aggregateName"         = $AggregateName
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/admin/storage-systems/$ClusterID/aggregate"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Clusters.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated Aggregate ""$AggregateName"" for cluster ID ""$ClusterID"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Aggregate ""$AggregateName"" for cluster ID ""$ClusterID"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCAggregate.
#'------------------------------------------------------------------------------
Function Get-VSCAggregates{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Cluster ID")]
      [ValidateNotNullOrEmpty()]
      [String]$ClusterID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters/$ClusterID/aggregates"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Aggregates.
   #'---------------------------------------------------------------------------
   Write-Host "Enumerating Aggregates for cluster ID ""$ClusterID"" on VSC ""$VSC"" using URI ""$uri"""
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated Aggregates for cluster ID ""$ClusterID"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Aggregates for cluster ID ""$ClusterID"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCAggregates.
#'------------------------------------------------------------------------------
Function Get-VSCScp{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP ID")]
      [Int]$Id
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/capability-profiles"

   $uri
   If($Id){
      [String]$uri = "$uri/$Id"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Storage Capability Profiles.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      If($Id){
         Write-Host "Enumerated Storage Capability Profile ID ""$Id"" on VSC ""$VSC"" using URI ""$uri"""
      }Else{
         Write-Host "Enumerated Storage Capability Profiles on VSC ""$VSC"" using URI ""$uri"""
      }
   }Catch{
      If($Id){
         Write-Warning -Message $("Failed Enumerating Storage Capability Profile ""$Id"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      }Else{
         Write-Warning -Message $("Failed Enumerating Storage Capability Profiles on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      }
   }
   Return $response;
}#End Function Get-VSCScp.
#'------------------------------------------------------------------------------
Function Get-VSCScpNames{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/admin/storage-capabilities/profile-names"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Storage Capability Profiles.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated Storage Capability Profile Names on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Storage Capability Profile Names on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCScpNames.
#'------------------------------------------------------------------------------
Function New-VSCScp{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Adaptive QoS policy name")]
      [String]$AdaptiveQoS,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Compression status")]
      [Switch]$Compression,
      [Parameter(Mandatory = $False, HelpMessage = "The SCPDeduplication status")]
      [Switch]$Deduplication,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Encryption status")]
      [Switch]$Encryption,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Maximum Throughput IOPS")]
      [Int]$MaxThroughputIops,
      [Parameter(Mandatory = $True, HelpMessage = "The SCP Platform Type. EG 'FAS'")]
      [String]$PlatformType,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Space Efficiency. EG 'Thin'")]
      [String]$SpaceEfficiency,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Tiering Policy. EG 'Thin'")]
      [String]$TieringPolicy,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Description")]
      [String]$Description,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Name")]
      [String]$Name,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the SCP body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$scp = @{};
   [HashTable]$capabilities = @{};
   If($AdaptiveQoS){
      [HashTable]$capabilities.Add("adaptiveQoS", $AdaptiveQoS)
   }
   If($Compression){
      [HashTable]$capabilities.Add("compression", $($Compression.ToString()).ToLower() )
   }
   If($Deduplication){
      [HashTable]$capabilities.Add("deduplication", $($Deduplication.ToString()).ToLower())
   }
   If($Encryption){
      [HashTable]$capabilities.Add("encryption", $($Encryption.ToString()).ToLower())
   }
   If($MaxThroughputIops){
      [HashTable]$capabilities.Add("maxThroughputIops", $MaxThroughputIops)
   }
   If($PlatformType){
      [HashTable]$capabilities.Add("platformType", $PlatformType)
   }
   If($SpaceEfficiency){
      [HashTable]$capabilities.Add("spaceEfficiency", $SpaceEfficiency)
   }
   If($TieringPolicy){
      [HashTable]$capabilities.Add("tieringPolicy", $TieringPolicy)
   }
   [HashTable]$scp.Add("capabilities", $capabilities)
   If($Description){
      [HashTable]$scp.Add("description", $Description)
   }
   [HashTable]$scp.Add("name", $Name)
   $body = $scp | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/capability-profiles"
   #'---------------------------------------------------------------------------
   #'Create the storage capability profile.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method POST -Body $body -ErrorAction Stop
      Write-Host "Created storage capabilty profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed creating storage capability profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function New-VSCScp.
#'------------------------------------------------------------------------------
Function Set-VSCScp{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Adaptive QoS policy name")]
      [String]$AdaptiveQoS,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Compression status")]
      [Switch]$Compression,
      [Parameter(Mandatory = $False, HelpMessage = "The SCPDeduplication status")]
      [Switch]$Deduplication,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Encryption status")]
      [Switch]$Encryption,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Maximum Throughput IOPS")]
      [Int]$MaxThroughputIops,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Platform Type. EG 'FAS'")]
      [String]$PlatformType,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Space Efficiency. EG 'Thin'")]
      [String]$SpaceEfficiency,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Tiering Policy. EG 'Thin'")]
      [String]$TieringPolicy,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Description")]
      [String]$Description,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP ID")]
      [Int]$Id,
      [Parameter(Mandatory = $True, HelpMessage = "The SCP Name")]
      [String]$Name,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the SCP body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$s   = @{};
   [HashTable]$scp = @{};
   [HashTable]$capabilities = @{};
   If($AdaptiveQoS){
      [HashTable]$capabilities.Add("adaptiveQoS", $AdaptiveQoS)
   }
   If($Compression){
      [HashTable]$capabilities.Add("compression", $($Compression.ToString()).ToLower() )
   }
   If($Deduplication){
      [HashTable]$capabilities.Add("deduplication", $($Deduplication.ToString()).ToLower())
   }
   If($Encryption){
      [HashTable]$capabilities.Add("encryption", $($Encryption.ToString()).ToLower())
   }
   If($MaxThroughputIops){
      [HashTable]$capabilities.Add("maxThroughputIops", $MaxThroughputIops)
   }
   If($PlatformType){
      [HashTable]$capabilities.Add("platformType", $PlatformType)
   }
   If($SpaceEfficiency){
      [HashTable]$capabilities.Add("spaceEfficiency", $SpaceEfficiency)
   }
   If($TieringPolicy){
      [HashTable]$capabilities.Add("tieringPolicy", $TieringPolicy)
   }
   [HashTable]$scp.Add("capabilities", $capabilities)
   If($Description){
      [HashTable]$scp.Add("description", $Description)
   }
   If($Id){
      [HashTable]$scp.Add("id", $Id.ToString())
   }
   [HashTable]$scp.Add("name", $Name)
   [HashTable]$s.Add("storageCapabilityProfile", $scp)
   $body = $s | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/capability-profiles"
   #'---------------------------------------------------------------------------
   #'Update the storage capability profile.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Updated storage capabilty profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed updating storage capability profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCScp.
#'------------------------------------------------------------------------------
Function New-VSCScpClone{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Adaptive QoS policy name")]
      [String]$AdaptiveQoS,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Compression status")]
      [Switch]$Compression,
      [Parameter(Mandatory = $False, HelpMessage = "The SCPDeduplication status")]
      [Switch]$Deduplication,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Encryption status")]
      [Switch]$Encryption,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Maximum Throughput IOPS")]
      [Int]$MaxThroughputIops,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Platform Type. EG 'FAS'")]
      [String]$PlatformType,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Space Efficiency. EG 'Thin'")]
      [String]$SpaceEfficiency,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Tiering Policy. EG 'Thin'")]
      [String]$TieringPolicy,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Description")]
      [String]$Description,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP ID")]
      [Int]$Id,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Name")]
      [String]$Name,
      [Parameter(Mandatory = $True, HelpMessage = "The SCP Base Profile Name to clone")]
      [ValidateNotNullOrEmpty()]
      [String]$BaseProfile,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Validate the input parameters.
   #'---------------------------------------------------------------------------
   If((-Not($Name)) -And (-Not($Id))){
      Write-Warning -Message "Neither the ""Name"" or ""Id"" parameters were provided. Please provide either the Name or ID"
      Return $Null
   }Else{
      If($Name -And $Id){
         Write-Warning -Message "The ""Name"" parameter and the ""Id"" parameters were both provided. Please provide either the Name or ID"
         Return $Null
      }
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the SCP body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$s   = @{};
   [HashTable]$scp = @{};
   [HashTable]$capabilities = @{};
   If($AdaptiveQoS){
      [HashTable]$capabilities.Add("adaptiveQoS", $AdaptiveQoS)
   }
   If($Compression){
      [HashTable]$capabilities.Add("compression", $($Compression.ToString()).ToLower() )
   }
   If($Deduplication){
      [HashTable]$capabilities.Add("deduplication", $($Deduplication.ToString()).ToLower())
   }
   If($Encryption){
      [HashTable]$capabilities.Add("encryption", $($Encryption.ToString()).ToLower())
   }
   If($MaxThroughputIops){
      [HashTable]$capabilities.Add("maxThroughputIops", $MaxThroughputIops)
   }
   If($PlatformType){
      [HashTable]$capabilities.Add("platformType", $PlatformType)
   }
   If($SpaceEfficiency){
      [HashTable]$capabilities.Add("spaceEfficiency", $SpaceEfficiency)
   }
   If($TieringPolicy){
      [HashTable]$capabilities.Add("tieringPolicy", $TieringPolicy)
   }
   [HashTable]$scp.Add("capabilities", $capabilities)
   If($Description){
      [HashTable]$scp.Add("description", $Description)
   }
   If($Id){
      [HashTable]$scp.Add("id", $Id.ToString())
   }
   [HashTable]$scp.Add("name", $Name)
   [HashTable]$s.Add("storageCapabilityProfile", $scp)
   $body = $s | ConvertTo-Json
   Write-Host $body -ForegroundColor Green
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/capability-profiles/$BaseProfile"
   #'---------------------------------------------------------------------------
   #'Clone the storage capability profile.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method POST -Body $body -ErrorAction Stop
      Write-Host "Updated storage capabilty profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed updating storage capability profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function New-VSCScpClone.
#'------------------------------------------------------------------------------
Function Remove-VSCScp{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP Profile Name")]
      [ValidateNotNullOrEmpty()]
      [String]$Name,
      [Parameter(Mandatory = $False, HelpMessage = "The SCP ID")]
      [Int]$Id
   )
   #'---------------------------------------------------------------------------
   #'Validate the input parameters.
   #'---------------------------------------------------------------------------
   If((-Not($Name)) -And (-Not($Id))){
      Write-Warning -Message "Neither the ""Name"" or ""Id"" parameters were provided. Please provide either the Name or ID"
      Return $Null
   }Else{
      If($Name -And $Id){
         Write-Warning -Message "The ""Name"" parameter and the ""Id"" parameters were both provided. Please provide either the Name or ID"
         Return $Null
      }
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   If($Name){
      $headers = @{
         "vmware-api-session-id" = $SessionID
         "profile-name"          = $Name
         "Accept"                = "application/json"
      }
   }
   If($Id){
      $headers = @{
         "vmware-api-session-id" = $SessionID
         "Accept"                = "application/json"
      }
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/admin/storage-capabilities"
   If($Id){
      [String]$uri += "/$Id"
   }
   #'---------------------------------------------------------------------------
   #'Delete the VSC Storage Capability Profile.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method DELETE -ErrorAction Stop
      If($Id){
         Write-Host "Deleted Storage Capability Profile ID ""$Id"" on VSC ""$VSC"" using URI ""$uri"""
      }Else{
         Write-Host "Deleted Storage Capability Profile ""$Name"" on VSC ""$VSC"" using URI ""$uri"""
      }
   }Catch{
      If($Id){
         Write-Warning -Message $("Failed Deleting Storage Capability Profile ID ""$Id"""" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      }Else{
         Write-Warning -Message $("Failed Deleting Storage Capability Profile ""$Name"""" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      }
   }
   Return $response;
}#End Function Remove-VSCScp.
#'------------------------------------------------------------------------------
Function Invoke-VSCRediscover{
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Discover the storage for VSC.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/storage/clusters/discover"
   [String]$discoverUri = $uri
   Write-Host "Discovering storage for VSC ""$VSC"" using URI ""$uri"""
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -ContentType "application/json" -ErrorAction Stop
      Write-Host "Discovered storage for VSC ""$Vsc"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed discovering storage for VSC ""$Vsc"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $response;
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC task ID and wait for completion.
   #'---------------------------------------------------------------------------
   [Int]$taskId = $response.taskId
   If($taskId -eq 0){
      Write-Warning -Message "Failed enumerating VSC Task ID"
      Return $Null;
   }
   $task = Wait-VSCTask -VSC $VSC -PortNumber $PortNumber -SessionID $SessionID -TaskID $taskId
   If($Null -eq $task){
      Return $Null; 
   }
   Return $task;
}#End Function Invoke-VSCRediscover.
#'------------------------------------------------------------------------------
Function Ping-VSCIPAddress{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The IP Address to ping")]
      [ValidateNotNullOrEmpty()]
      [String]$IPAddress,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
      "hostname" = $IPAddress
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/appliance/management/network-settings/ping-host"
   #'---------------------------------------------------------------------------
   #'Ping the IP Address.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
   }Catch{
      Write-Warning -Message $("Failed pinging IP Address ""$IPAddress"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   If($Null -ne $response){
      If($response.responseMessage.Contains("SUCCESS")){
         Write-Host "Pinged IP Address ""$IPAddress"" on VSC ""$VSC"" using URI ""$uri"""
      }Else{
         Write-Warning -Message "Failed pinging IP Address ""$IPAddress"" on VSC ""$VSC"" using URI ""$uri"""
      }
   }Else{
      Write-Warning -Message "Failed pinging IP Address ""$IPAddress"" on VSC ""$VSC"" using URI ""$uri"""
   }
   Return $response;
}#End Function Ping-VSCIPAddress.
#'------------------------------------------------------------------------------
Function Get-VSCLogLevel{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The service type to enumerate log configuration levels for")]
      [ValidateSet("VSC","VP","SRA")]
      [String]$ServiceType,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = $("https://$VSC`:$PortNumber/api/rest/2.0/logs/configuration?service-type=" + $ServiceType.ToUpper())
   #'---------------------------------------------------------------------------
   #'Get the VSC Log configuration.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerating log configuration level for service type ""$ServiceType"""
   }Catch{
      Write-Warning -Message $("Failed enumerating log configuration level for service type ""$ServiceType"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   [String]$logLevel = $Null
   If($Null -ne $response){
      [String]$logLevel = $response.logLevel
   }
   If(-Not([String]::IsNullOrEmpty($logLevel))){
      Write-Host $("Enumerated log configuration level for service type ""$ServiceType"" as """ + $response.logLevel + """ on VSC ""$VSC"" using URI ""$uri""")
   }Else{
      Write-Warning -Message "Failed enumerating log configuration level for service type ""$ServiceType"" on VSC ""$VSC"" using URI ""$uri"""
   }
   Return $response;
}#End Function Get-VSCLogLevel.
#'------------------------------------------------------------------------------
Function Set-VSCLogLevel{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The service type to set the log configuration level for")]
      [ValidateSet("VSC","VP","SRA")]
      [String]$ServiceType,
      [Parameter(Mandatory = $True, HelpMessage = "The log configuration level")]
      [ValidateSet("INFO","DEBUG","ERROR","TRACE")]
      [String]$LogLevel,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the log configration body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$config = @{};
   [HashTable]$config.Add("logLevel",    $LogLevel.ToUpper())
   [HashTable]$config.Add("serviceType", $ServiceType.ToUpper())
   $body = $config | ConvertTo-Json
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/logs/configuration"
   #'---------------------------------------------------------------------------
   #'Set the VSC Service Type Log configuration level.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Set log configuration level for service type ""$ServiceType"" to ""$LogLevel"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting log configuration level for service type ""$ServiceType"" to ""$LogLevel"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCLogLevel.
#'------------------------------------------------------------------------------
Function Get-VSCSyslogServer{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/logs/syslog/servers"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Syslog servers.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated syslog servers for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating syslog servers for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VSCSyslogServer.
#'------------------------------------------------------------------------------
Function Remove-VSCSyslogServer{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $False, HelpMessage = "The Syslog server UUID")]
      [String]$UUID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/logs/syslog/servers/$UUID"
   #'---------------------------------------------------------------------------
   #'Remove the VSC Syslog server.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method DELETE -ErrorAction Stop
      Write-Host "Removed syslog server ""$UUID"" from VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed removing syslog server ""$UUID"" from VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Remove-VSCSyslogServer.
#'------------------------------------------------------------------------------
Function Set-VSCSyslogServer{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Hostname, FQDN or IP Address of the Syslog Server")]
      [String]$Hostname,
      [Parameter(Mandatory = $True, HelpMessage = "The Logging Level. Valid values are 'INFO', 'DEBUG', 'ERROR', 'TRACE', 'WARN', 'FATAL', 'OFF' and 'ALL'")]
      [ValidateSet("INFO","DEBUG","ERROR","TRACE","WARN","FATAL","OFF","ALL")]
      [String]$LogLevel,
      [Parameter(Mandatory = $True, HelpMessage = "The log pattern. Example pattern: '%d (%t) %-5p [%c{1}] - %m%n'")]
      [String]$Pattern,
      [Parameter(Mandatory = $True, HelpMessage = "The Syslog Server Port Number")]
      [ValidateRange(1,65535)]
      [Int]$Port
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/logs/syslog/servers"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the syslog server body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$syslog = @{};
   [HashTable]$syslog.Add("hostname", $Hostname)
   [HashTable]$syslog.Add("logLevel", $LogLevel)
   [HashTable]$syslog.Add("pattern",  $Pattern)
   [HashTable]$syslog.Add("port",     $Port.ToString())
   $body = $syslog | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC Syslog servers.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method POST -Body $body -ErrorAction Stop
      Write-Host "Set syslog servers for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting syslog servers for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCSyslogServer.
#'------------------------------------------------------------------------------
Function Update-VSCSyslogServer{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The Hostname, FQDN or IP Address of the Syslog Server")]
      [String]$Hostname,
      [Parameter(Mandatory = $True, HelpMessage = "The Logging Level. Valid values are 'INFO', 'DEBUG', 'ERROR', 'TRACE', 'WARN', 'FATAL', 'OFF' and 'ALL'")]
      [ValidateSet("INFO","DEBUG","ERROR","TRACE","WARN","FATAL","OFF","ALL")]
      [String]$LogLevel,
      [Parameter(Mandatory = $True, HelpMessage = "The log pattern. Example pattern: '%d (%t) %-5p [%c{1}] - %m%n'")]
      [String]$Pattern,
      [Parameter(Mandatory = $True, HelpMessage = "The Syslog Server Port Number")]
      [ValidateRange(1,65535)]
      [Int]$Port,
      [Parameter(Mandatory = $True, HelpMessage = "The Syslog server UUID")]
      [String]$UUID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/logs/syslog/servers/$UUID"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the syslog server body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$syslog = @{};
   If($Hostname){
      [HashTable]$syslog.Add("hostname", $Hostname)
   }
   If($LogLevel){
      [HashTable]$syslog.Add("logLevel", $LogLevel)
   }
   If($Pattern){
      [HashTable]$syslog.Add("pattern", $Pattern)
   }
   If($Port){
      [HashTable]$syslog.Add("port", $Port.ToString())
   }
   $body = $syslog | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Update the VSC Syslog server.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Updated syslog server ""$UUID"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed updating syslog server ""$UUID"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Update-VSCSyslogServer.
#'------------------------------------------------------------------------------
Function Get-VSCSystemInfo{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/product-detail"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC product details.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated product details for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed pinging IP Address ""$IPAddress"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCSystemInfo.
#'------------------------------------------------------------------------------
Function Get-VSCCertificate{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Service Type. Valid values are 'VSC' (Virtual Storage Console) or 'VP' (VASA Provider)")]
      [ValidateNotNullOrEmpty()]
      [ValidateSet("VSC","VP")]
      [String]$ServiceType,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/security/certificate?service-type=$ServiceType"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC certificate.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated the certificate for service ""$ServiceType"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating the certificate for service ""$ServiceType"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCCertificate.
#'------------------------------------------------------------------------------
Function Set-VSCCertificate{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The Certificate Chain")]
      [Array]$CertificateChain,
      [Parameter(Mandatory = $True, HelpMessage = "The Certificate operation. Valid values are 'reset', 'import' and 'generatecsr'")]
      [ValidateNotNullOrEmpty()]
      [ValidateSet("reset","import","generatecsr")]
      [String]$Operation,
      [ValidateNotNullOrEmpty()]
      [ValidateSet("VSC","VP")]
      [String]$ServiceType,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/security/certificate"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the certificate body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$cert   = @{};
   [HashTable]$import = @{};
   [HashTable]$import.Add("certificateChain", $CertificateChain)
   [HashTable]$cert.Add("certificateImport",  $import)
   [HashTable]$cert.Add("operation",          $Operation)
   [HashTable]$cert.Add("serviceType",        $ServiceType)
   $body = $cert | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC certificate.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method POST -Body $body -ErrorAction Stop
      Write-Host "Set the ""$Operation"" method for the service ""$ServiceType"" certificate on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting the ""$Operation"" method for the service ""$ServiceType"" certificate on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCCertificate.
#'------------------------------------------------------------------------------
Function Export-VSCSupportLogs{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/support/logs"
   #'---------------------------------------------------------------------------
   #'Export the VSC support logs.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method POST -ErrorAction Stop
      Write-Host "Exported the support logs for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed exporting the support logs for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $response;
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC task ID and wait for completion.
   #'---------------------------------------------------------------------------
   [Int]$taskId = $response.taskId
   If($taskId -ne 0){
      $response = Wait-VSCTask -VSC $VSC -PortNumber $PortNumber -SessionID $SessionID -TaskID $taskId
   }Else{
      Write-Warning -Message "Failed enumerating VSC Task ID"
   }
   Return $response;
}#End Function Export-VSCSupportLogs.
#'------------------------------------------------------------------------------
Function Get-VSCNetInterface{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/network/interfaces"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC network interfaces.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated network interface for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating network interface for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCNetInterface.
#'------------------------------------------------------------------------------
Function Set-VSCNetInterface{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The DNS Servers")]
      [Array]$DnsServer,
      [Parameter(Mandatory = $False, HelpMessage = "The network interface gateway")]
      [String]$Gateway,
      [Parameter(Mandatory = $False, HelpMessage = "The network interface IP Address")]
      [String]$IPAddress,
      [Parameter(Mandatory = $False, HelpMessage = "The network interface IP Family. Valid values are 'IPV4'")]
      [ValidateSet("IPV4")]
      [String]$IPFamily,
      [Parameter(Mandatory = $False, HelpMessage = "The network interface IP Address")]
      [ValidateSet("DHCP","STATIC")]
      [String]$Mode,
      [Parameter(Mandatory = $False, HelpMessage = "The network interface network mask")]
      [String]$Netmask,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/network/interfaces"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the network interface body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$interface = @{};
   [HashTable]$dns       = @{};
   [HashTable]$dns.Add("dnsServers",     $DnsServers)
   [HashTable]$interface.Add("gateway",  $Gateway)
   [HashTable]$interface.Add("ip",       $IPAddress)
   [HashTable]$interface.Add("ipFamily", $IPFamily)
   [HashTable]$interface.Add("mode",     $Mode)
   [HashTable]$interface.Add("netmask",  $Netmask)
   $body = $interface | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC network interface.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Set network interface for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting network interface for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCNetInterface.
#'------------------------------------------------------------------------------
Function Get-VSCNetRoute{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/network/routes"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC network routes.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated network routes for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating network routes for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCNetRoute.
#'------------------------------------------------------------------------------
Function Set-VSCNetRoute{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Network Address")]
      [String]$Network,
      [Parameter(Mandatory = $True, HelpMessage = "The Network Bits")]
      [ValidateRange(0,32)]
      [Int]$NetworkBits,
      [Parameter(Mandatory = $True, HelpMessage = "The Network gateway IP Address")]
      [String]$Gateway,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/network/routes"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the network interface body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$route = @{};
   [HashTable]$route.Add("gateway",        $Gateway)
   [HashTable]$route.Add("hostOrNetwork", $($Network + "/" + $NetworkBits.ToString()))
   $body = $route | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC network routes.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Set route for network ""$Network/$NetworkBits"" to gateway ""$Gateway"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting route for network ""$Network/$NetworkBits"" to gateway ""$Gateway"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Set-VSCNetRoute.
#'------------------------------------------------------------------------------
Function Remove-VSCNetRoute{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Network Address")]
      [String]$Network,
      [Parameter(Mandatory = $True, HelpMessage = "The Network Bits")]
      [ValidateRange(0,32)]
      [Int]$NetworkBits,
      [Parameter(Mandatory = $True, HelpMessage = "The Network gateway IP Address")]
      [String]$Gateway,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"          = "application/json"
      "username"        = $Credential.GetNetworkCredential().Username
      "password"        = $Credential.GetNetworkCredential().Password
      "host-or-network" = $($Network + "/" + $($NetworkBits.ToString()))
      "gateway"         = $Gateway
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/network/routes"
   #'---------------------------------------------------------------------------
   #'Delete the VSC network routes.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method DELETE -ErrorAction Stop
      Write-Host "Deleted route for network ""$Network/$NetworkBits"" to gateway ""$Gateway"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed deleting route for network ""$Network/$NetworkBits"" to gateway ""$Gateway"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Remove-VSCNetRoute.
#'------------------------------------------------------------------------------
Function Get-VSCSshService{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/security/ssh"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC SSH Service status.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated SSH service status for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating SSH service status for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCSshService.
#'------------------------------------------------------------------------------
Function Set-VSCSshService{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The SSH service state. If True the service is set to enabled otherwise disabled")]
      [Bool]$Enabled,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/security/ssh"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the SSH Service body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$ssh = @{};
   [HashTable]$ssh.Add("enable", $($Enabled.ToString()).ToLower())
   $body = $ssh | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC SSH Service enabled state.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method POST -Body $body -ErrorAction Stop
      Write-Host "Set SSH service state to ""$State"" for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting SSH service state to ""$State"" for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCSshService.
#'------------------------------------------------------------------------------
Function Reset-VSCPassword{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The administrator Credentials to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$AdminCredential,
      [Parameter(Mandatory = $True, HelpMessage = "The old Credentials for the VSC user to reset the password to VSC")]
      [System.Management.Automation.PSCredential]$OldCredential,
      [Parameter(Mandatory = $True, HelpMessage = "The administrator Credentials to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$NewCredential
   )
   #'---------------------------------------------------------------------------
   #'Validate the administrator VSC username.
   #'---------------------------------------------------------------------------
   [String]$adminUser = $AdminCredential.GetNetworkCredential().Username
   If($adminUser -ne "administrator"){
      Write-Warning -Message "The username ""$adminUser"" does not match the required username of ""administrator"""
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Ensure the old and new VSC username match.
   #'---------------------------------------------------------------------------
   [String]$oldUser = $OldCredential.GetNetworkCredential().Username
   [String]$newUser = $NewCredential.GetNetworkCredential().Username
   If($oldUser -cne $newUser){
      Write-Warning -Message "The old username ""$oldUser"" does not match the new username ""$newUser"". Please note that usernames are case sensitive. The Password has not been reset"
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"       = "application/json"
      "username"     = $AdminCredential.GetNetworkCredential().Username
      "password"     = $AdminCredential.GetNetworkCredential().Password
      "old-password" = $OldCredential.GetNetworkCredential().Password
      "new-password" = $NewCredential.GetNetworkCredential().Password
   }
   If($OldCredential.GetNetworkCredential().Username -ne "administrator"){
      $headers.Add("reset-user", $OldCredential.GetNetworkCredential().Username)
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/security/user/password"
   #'---------------------------------------------------------------------------
   #'Reset the VSC user password.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -ErrorAction Stop
      Write-Host "Reset the the password for user ""$oldUser"" on VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed resetting the the password for user ""$oldUser"" on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Reset-VSCPassword.
#'------------------------------------------------------------------------------
Function Get-VSCNtpServer{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/time/ntp"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC NTP Servers.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated NTP servers for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating NTP Servers for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCNtpServer.
#'------------------------------------------------------------------------------
Function Set-VSCNtpServer{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The NTP Server")]
      [String]$NTPServer,
      [Parameter(Mandatory = $False, HelpMessage = "If true the NTP time is not updated")]
      [Bool]$SkipRefresh,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"      = "application/json"
      "username"    = $Credential.GetNetworkCredential().Username
      "password"    = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/time/ntp"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the NTP Server body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$ntp = @{};
   [HashTable]$ntp.Add("name",          $NtpServer)
   [HashTable]$ntp.Add("skipRefresh", $($SkipRefresh.ToString().ToLower()))
   $body = $ntp | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC NTP Servers.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Set NTP servers for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting NTP Servers for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCNtpServer.
#'------------------------------------------------------------------------------
Function Get-VSCTimezone{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/time/timezone"
   #'---------------------------------------------------------------------------
   #'Enumerate the VSC Timezone.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated timezone for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating timezone for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCTimezone.
#'------------------------------------------------------------------------------
Function Get-VSCTimezones{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/time/timezones"
   #'---------------------------------------------------------------------------
   #'Get the VSC Timezones.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated timezones for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed enumerating timezones for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCTimezones.
#'------------------------------------------------------------------------------
Function Set-VSCTimezone{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Timezone")]
      [String]$Timezone,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC. Username must match 'administrator'")]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Validate the VSC username.
   #'---------------------------------------------------------------------------
   If($Credential.GetNetworkCredential().Username -ne "administrator"){
      Write-Warning -Message $("The username """ + $Credential.GetNetworkCredential().Username + """ does not match the required username of ""administrator""")
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"      = "application/json"
      "username"    = $Credential.GetNetworkCredential().Username
      "password"    = $Credential.GetNetworkCredential().Password
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/system/time/timezone"
   #'---------------------------------------------------------------------------
   #'Create a hashtable for the Timezone body and convert it to JSON.
   #'---------------------------------------------------------------------------
   [HashTable]$tz = @{};
   [HashTable]$tz.Add("timezone", $Timezone)
   $body = $tz | ConvertTo-Json
   #'---------------------------------------------------------------------------
   #'Set the VSC Timezone.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method PUT -Body $body -ErrorAction Stop
      Write-Host "Set Timezone to ""$Timezone"" for VSC ""$VSC"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed setting Timezone to ""$Timezone"" for VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Set-VSCTimezone.
#'------------------------------------------------------------------------------
Function Wait-VSCTask{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC name or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC port number")]
      [String]$PortNumber=8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Task ID")]
      [ValidateNotNullOrEmpty()]
      [String]$TaskID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/tasks/$TaskId"
   [Bool]$completed = $False
   [Int]$checkCount = 0
   [Int]$totalCount = 60
   While($completed -eq $False -And $checkCount -le $totalCount){
      Try{
         $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ContentType "application/json" -ErrorAction Stop
      }Catch{
         Write-Warning -Message $("Failed enumerating task ID ""$taskId"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
         Return $response;
      }
      [String]$status        = $($response.status).ToLower();
      [String]$statusMessage = $response.statusMessage
      If($status -eq "failed"){
         Write-Warning -Message $("Task ID`: $taskId. Status`: $status. Error """ + $response.errorMessage + """")
         Return $response;
      }Else{
         If($status -eq "complete"){
            Write-Host "Task ID`: $taskId. Status: $status"
            [Bool]$completed = $True
         }Else{
            [Bool]$completed = $False
            [Int]$checkCount++
            Write-Host "Waiting for VSC Task ID $taskId to complete. Status: $status. Sleeping. Iteration number: $checkCount of $totalCount"
            Start-Sleep -Seconds 15
         }
      }
   }
   Write-Host "Complete`: $completed. Iteration Count`: $checkCount"
   #'------------------------------------------------------------------------------
   #'Raise an error if the VSC task timeout is exceeded.
   #'------------------------------------------------------------------------------
   If($checkCount -ge $totalCheck -And $completed -eq $False){
      Write-Warning -Message "VSC task ID $taskID did not complete within a 5 minute timeout"
   }
   Return $response;
}#End Function Wait-VSCTask.
#'------------------------------------------------------------------------------
Function Get-VSCPrivilege{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The VMWare Managed Object Reference Identifier")]
      [Array]$PrivilegeID,
      [Parameter(Mandatory = $True, HelpMessage = "The VMWare Managed Object Reference Identifier")]
      [Array]$ObjectID,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for VSC authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "Accept"   = "application/json"
      "username" = $Credential.GetNetworkCredential().Username
      "password" = $Credential.GetNetworkCredential().Password
   }
   #'---------------------------------------------------------------------------
   #'Set the URI for enumerating VSC Privileges.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$VSC`:$PortNumber/api/rest/2.0/security/user/privileges?"
   ForEach($p In $PrivilegeID){
      [String]$uri += "privilege-id=$p" 
   }
   ForEach($o In $ObjectID){
      [String]$uri += "&morefs=$o"
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the  VSC Privileges.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $headers -Method GET -ErrorAction Stop
      Write-Host $("Enumerated Privileges """ + $([String]::Join(",", $PrivilegeID)) + """ for objects """ + $([String]::Join(",", $ObjectID)) + """ on VSC ""$VSC"" using URI ""$uri""")
   }Catch{
      Write-Warning -Message $("Failed enumerating Privilege """ + $([String]::Join(",", $PrivilegeID)) + """ for objects """ + $([String]::Join(",", $ObjectID)) + """ on VSC ""$VSC"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
   }
   Return $response;
}#End Function Get-VSCPrivilege.
#'------------------------------------------------------------------------------
Function Add-VSCApi{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143,
      [Parameter(Mandatory = $True, HelpMessage = "The REST API Category")]
      [String]$Category,
      [Parameter(Mandatory = $True, HelpMessage = "The REST API Description")]
      [Array]$Description,
      [Parameter(Mandatory = $True, HelpMessage = "The Function Name")]
      [String]$Name,
      [Parameter(Mandatory = $True, HelpMessage = "The VSC REST API URI Endpoints")]
      [Array]$EndPoint,
      [Parameter(Mandatory = $True, HelpMessage = "The REST API Method")]
      [ValidateSet("DELETE","GET","POST","PUT")]
      [String]$Method
   )
   #'---------------------------------------------------------------------------
   #'Convert the endpoints into an array of URI's.
   #'---------------------------------------------------------------------------
   [Array]$uris = @();
   ForEach($ep In $EndPoint){
      If($Endpoint.StartsWith("/")){
         [String]$ep = $ep.SubString(1)
      }
      [Array]$uris += "https`://$VSC`:$PortNumber/api/rest/$ep"
   }
   [Array]$descriptions
   ForEach($d in $Description){
      [Array]$descriptions += $d
   }
   #'---------------------------------------------------------------------------
   #'Create the custom object to return.
   #'---------------------------------------------------------------------------
   $api = [PSCustomObject]@{
      Category    = $Category
      Description = $Descriptions
      Method      = $Method
      Name        = $Name
      Uri         = $uris
   }
   Return $api
}#'End Function Add-VSCApi.
#'------------------------------------------------------------------------------
Function Get-VSCApiMapping{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143
   )
   #'---------------------------------------------------------------------------
   #'Create hashtable for API mapping.
   #'---------------------------------------------------------------------------
   $apis = @();
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Ping-VSCIPAddress"          -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/appliance/management/network-settings/ping-host"                        -Description "Get host status"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCLogLevel"            -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/logs/configuration"                                                     -Description "Gets the log level of the virtual appliance for VSC, VASA Provider, and SRA"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCLogLevel"            -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/logs/configuration"                                                     -Description "Updates the log level of the virtual appliance for VSC, VASA Provider, and SRA"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCSyslogServer"        -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/logs/syslog/servers"                                                    -Description "Gets all configured remote logging servers details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCSyslogServer"        -Category "Appliance Management"       -Method "POST"   -EndPoint "/2.0/logs/syslog/servers"                                                    -Description "Configures the remote syslog forwarding server"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCSyslogServer"     -Category "Appliance Management"       -Method "DELETE" -EndPoint "/2.0/logs/syslog/servers/{uuid}"                                             -Description "Deletes the configured remote server (used to write sys-log)"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Update-VSCSyslogServer"     -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/logs/syslog/servers/{uuid}"                                             -Description "Updates the configured remote log forwarding server (used to write sys-log)"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCSystemInfo"          -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/product-detail"                                                         -Description "Gets appliance details for the unified appliance"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCCertificate"         -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/security/certificate"                                                   -Description "Gets the certificate details of the appliance"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCCertificate"         -Category "Appliance Management"       -Method "POST"   -EndPoint "/2.0/security/certificate"                                                   -Description "Resets or imports or generates CSR certificates of the appliance"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Export-VSCSupportLogs"      -Category "Appliance Management"       -Method "POST"   -EndPoint "/2.0/support/logs"                                                           -Description "Generates a support bundle"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCNetInterface"        -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/system/network/interfaces"                                              -Description "Gets network settings details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCNetInterface"        -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/system/network/interfaces"                                              -Description "Updates the network setting details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCNetRoute"         -Category "Appliance Management"       -Method "DELETE" -EndPoint "/2.0/system/network/interfaces"                                              -Description "Deletes the static route"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCNetRoute"            -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/system/network/interfaces"                                              -Description "Gets the static route details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCNetRoute"            -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/system/network/interfaces"                                              -Description "Adds the details for a static route"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCSshService"          -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/system/security/ssh"                                                    -Description "Gets the SSH status"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCSshService"          -Category "Appliance Management"       -Method "POST"   -EndPoint "/2.0/system/security/ssh"                                                    -Description "Enables or disables SSH"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Reset-VSCPassword"          -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/system/security/user/password"                                          -Description "Resets the maintenance or administrator password"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCNtpServer"           -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/system/time/ntp"                                                        -Description "Gets NTP server configuration"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCNtpServer"           -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/system/time/ntp"                                                        -Description "Sets NTP server in the UA config"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCTimezone"            -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/system/time/timezone"                                                   -Description "Gets the time zone for the virtual appliance for VSC, VASA Provider, and SRA"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCTimezone"            -Category "Appliance Management"       -Method "PUT"    -EndPoint "/2.0/system/time/timezone"                                                   -Description "Changes the time zone for the virtual appliance for VSC, VASA Provider, and SRA"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCTimezones"           -Category "Appliance Management"       -Method "GET"    -EndPoint "/2.0/system/time/timezone"                                                   -Description "Get available time zones"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCDatastoreCluster"    -Category "Datastore"                  -Method "GET"    -EndPoint "/2.0/admin/datastore/clusters"                                               -Description "Gets all clusters matching protocol and storage capability profiles"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Add-VSCDatastoreMount"      -Category "Datastore"                  -Method "PUT"    -EndPoint "/2.0/admin/datastore/mount-on-additional-hosts"                              -Description "Mounts the datastore to a given host"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCDatastoreMount"   -Category "Datastore"                  -Method "PUT"    -EndPoint "/2.0/admin/datastore/{datastore-moref}/unmount"                              -Description "Unmounts the datastore from the specified host"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCDatastore"           -Category "Datastore"                  -Method "GET"    -EndPoint "/2.0/hosts/datastores"                                                       -Description "Retrieves all the available VVol datastores with their details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "New-VSCVvolDataStore"       -Category "Datastore"                  -Method "POST"   -EndPoint "/2.0/hosts/datastores"                                                       -Description "Creates a VVOL datastore"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCDatastore"        -Category "Datastore"                  -Method "DELETE" -EndPoint "/2.0/hosts/datastores/{datastore-moref}"                                     -Description "Deletes a VVOL datastore"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCFlexvolDatastore" -Category "Datastore"                  -Method "POST"   -EndPoint "/2.0/hosts/datastores/{datastore-moref}/storage/flexvolumes"                 -Description "Removes flexVols from a datastore"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Mount-VSCDatastore"         -Category "Datastore"                  -Method "PUT"    -EndPoint "/2.0/hosts/datastores/{datastore-name}"                                      -Description "Mounts the datastore on a given host"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Add-VSCFlexvolDatastore"    -Category "Datastore"                  -Method "PUT"    -EndPoint "/2.0/hosts/datastores/{datastore-name}/storage/flexvolumes"                  -Description "Adds flexVols to a datastore"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCScpAggregate"        -Category "Datastore"                  -Method "GET"    -EndPoint "/2.0/storage/aggregates"                                                     -Description "Get list of aggregates that match the storage capability profiles"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Unregister-VSCPlugin"       -Category "Extension Management"       -Method "DELETE" -EndPoint "/2.0/plugin/vcenter"                                                         -Description "Unregister VSC from vCenter server"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCPlugin"              -Category "Extension Management"       -Method "GET"    -EndPoint "/2.0/plugin/vcenter"                                                         -Description "Gets registered virtual appliance extensions details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Register-VSCSPlugin"        -Category "Extension Management"       -Method "PUT"    -EndPoint "/2.0/plugin/vcenter"                                                         -Description "Registers virtual appliance for VSC, VASA Provider, and SRA to the vCenter Server"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCCapability"          -Category "Product Capability"         -Method "GET"    -EndPoint "/2.0/product/capabilities"                                                   -Description "Lists all the product capabilities"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCCapability"          -Category "Product Capability"         -Method "POST"   -EndPoint "/2.0/product/capabilities"                                                   -Description "Enables or disables Storage Replication Adapter (SRA) or VASA Provider"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCService"             -Category "Product Capability"         -Method "GET"    -EndPoint "/2.0/system/services"                                                        -Description "Gets the running status of VSC and VASA Provider server"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCService"             -Category "Product Capability"         -Method "PUT"    -EndPoint "/2.0/system/services"                                                        -Description "Restarts VSC, VASA Provider or both the services"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCDatastoreReport"     -Category "Reports"                    -Method "GET"    -EndPoint "/2.0/reports/datastores"                                                     -Description "Gets the VSC Datastores Report"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCVMReport"            -Category "Reports"                    -Method "GET"    -EndPoint "/2.0/reports/virtual-machines"                                               -Description "Gets the VSC Virtual Machines Report"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCScp"                 -Category "Storage Capability Profile" -Method "GET"    -EndPoint @("/2.0/storage/capability-profiles","/2.0/storage/capability-profiles/{id}") -Description @("Lists all the storage capability profiles","Gets the storage capability profile that has the specified ID")
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCScpNames"            -Category "Storage Capability Profile" -Method "GET"    -EndPoint "/2.0/admin/storage-capabilities/profile-names"                               -Description "List storage capability profile names"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "New-VSCScp"                 -Category "Storage Capability Profile" -Method "POST"   -EndPoint "/2.0/storage/capability-profiles"                                            -Description "Creates a storage capability profile"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCScp"              -Category "Storage Capability Profile" -Method "DELETE" -EndPoint @("/2.0/admin/storage-capabilities","/2.0/admin/storage-capabilities/{id}")   -Description @("Delete a Storage Capability Profile by name","Deletes the storage capability profile that has the specified ID")
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Set-VSCScp"                 -Category "Storage Capability Profile" -Method "PUT"    -EndPoint "/2.0/storage/capability-profiles"                                            -Description "Updates a storage capability profile"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "New-VSCScpClone"            -Category "Storage Capability Profile" -Method "POST"   -EndPoint "/2.0/storage/capability-profiles/{base-profile-name}"                        -Description "Clones a storage capability profile"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Add-VSCCluster"             -Category "Storage Systems"            -Method "POST"   -EndPoint "/2.0/storage/clusters"                                                       -Description "Adds a storage system"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Invoke-VSCRediscover"       -Category "Storage Systems"            -Method "POST"   -EndPoint "/2.0/storage/clusters/discover"                                              -Description "Rediscovers the storage systems"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCAggregates"          -Category "Storage Systems"            -Method "GET"    -EndPoint "/2.0/storage/clusters/{cluster-id}/aggregates"                               -Description "Get all the aggregates and their details"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Remove-VSCCluster"          -Category "Storage Systems"            -Method "DELETE" -EndPoint "/2.0/storage/clusters/{controller-id}"                                       -Description "Removes the storage system with the specified ID"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCCluster"             -Category "Storage Systems"            -Method "GET"    -EndPoint @("/2.0/storage/clusters","/2.0/storage/clusters/{controller-id}")            -Description @("Gets all the storage systems and their details","Gets the storage system and details of a specified ID")
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCFlexvol"             -Category "Storage Systems"            -Method "GET"    -EndPoint @("/2.0/storage/flexvolumes")                                                 -Description "Retreives flexVols matching the given storage capability profiles"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "New-VSCFlexvol"             -Category "Storage Systems"            -Method "POST"   -EndPoint @("/2.0/storage/flexvolumes")                                                 -Description "Creates a flexVol based on the storage capabiity profile provided"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Wait-VSCTask"               -Category "Tasks"                      -Method "GET"    -EndPoint "/2.0/tasks/{id}"                                                             -Description "Retrieves the status of the asynchronous task"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Connect-VSCSession"         -Category "User Authentication"        -Method "POST"   -EndPoint "/2.0/security/user/login"                                                    -Description "Gets the user login details and generates a session (vmware-api-session-id created)"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Disconnect-VSCSession"      -Category "User Authentication"        -Method "POST"   -EndPoint "/2.0/tasks/{id}"                                                             -Description "Logs off a user from the current session"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Export-VSCLogs"             -Category "VSC Configurations"         -Method "GET"    -EndPoint "/2.0/vsc/exportLogs"                                                         -Description "VSC Export logs"
   $apis += Add-VSCApi -VSC $VSC -PortNumber $PortNumber -Name "Get-VSCPrivilege"           -Category "Vsphere Privilege"          -Method "GET"    -EndPoint "/2.0/security/user/privileges"                                               -Description "Validates the privileges for an operation on a specified entity"
   Return $apis;
}#'End Function Get-VSCApiMapping.
#'------------------------------------------------------------------------------
Function Invoke-VSCSwaggerUI{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
      [ValidateNotNullOrEmpty()]
      [String]$VSC,
      [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
      [Int]$PortNumber = 8143
   )
   [String]$uri = "https`://$VSC`:$PortNumber/api/rest/swagger-ui.html`#"
   Try{
      Start-Process $uri -ErrorAction Stop
   }Catch{
      Write-Warning -Message "Failed opening URI`: $uri"
   }
   Return $uri;
}#'End Function Invoke-VSCSwaggerUI
#'------------------------------------------------------------------------------
#'VMWare REST API Functions.
#'------------------------------------------------------------------------------
Function Connect-VISession{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter server Hostname, FQDN or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Server,
      [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to vCenter")]
      [ValidateNotNullOrEmpty()]
      [System.Management.Automation.PSCredential]$Credential
   )
   #'---------------------------------------------------------------------------
   #'Set the authentication header to connect to virtual center.
   #'---------------------------------------------------------------------------
   $auth    = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName + ':' + $Credential.GetNetworkCredential().Password))
   $headers = @{
      "Authorization" = "Basic $auth"
   }
   #'---------------------------------------------------------------------------
   #'Connect to virtual center and return the session ID.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$Server/rest/com/vmware/cis/session"
   Try{
      $response  = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -ErrorAction Stop
      $sessionId = $response.Value
      Write-Host "Connected to Virtual Center ""$Server"". Session ID`: $sessionId"
   }Catch{
      Write-Warning -Message $("Failed connecting to Virtual Center ""$Server"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $sessionId;
}#End Function Connect-VISession.
#'------------------------------------------------------------------------------
Function Disconnect-VISession{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter server Hostname, FQDN or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Server,
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for Vcenter authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'---------------------------------------------------------------------------
   #'Disconnect from virtual center.
   #'---------------------------------------------------------------------------
   [String]$uri = "https://$Server/rest/com/vmware/cis/session"
   Try{
      $response = Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers -ErrorAction Stop
      Write-Host "Disconnected from Virtual Center ""$Server"". Session ID`: $SessionID"
   }Catch{
      Write-Warning -Message $("Failed disconnecting from Virtual Center ""$Server"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Break;
   }
   Write-Host $response.StatusCode.value
}#End Function Disconnect-VISession.
#'------------------------------------------------------------------------------
Function Get-VIHost{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The Vcenter Server Hostname, FQDN or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Server,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter cluster managed object references")]
      [Array]$Cluster,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter datacenter managed object references")]
      [Array]$DataCenter,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter ESX host managed object references")]
      [Array]$EsxHost,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter Folder managed object references")]
      [Array]$Folder,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter ESX hostnames")]
      [Array]$Name,
      [Parameter(Mandatory = $False, HelpMessage = "The standalone state of the ESX Hosts")]
      [Bool]$Standalone,
      [Parameter(Mandatory = $False, HelpMessage = "The connection state of the ESX Hosts")]
      [ValidateSet("connected","disconnected","not_responding")]
      [String]$State,
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for Vcenter authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'------------------------------------------------------------------------------
   #'Set the URI for querying input parameters if required.
   #'------------------------------------------------------------------------------
   [String]$uri = "https://$Server/rest/vcenter/host"
   [Bool]$query = $False;
   If($Cluster){
      [Bool]$query = $True;
      ForEach($c In $Cluster){
         [String]$uri += "filter.clusters=$c`&"
      }
   }
   If($DataCenter){
      [Bool]$query = $True;
      ForEach($dc In $DataCenter){
         [String]$uri += "filter.datacenters=$dc`&"
      }
   }
   If($EsxHost){
      [Bool]$query = $True;
      ForEach($h In $EsxHost){
         [String]$uri += "filter.hosts=$h`&"
      }
   }
   If($Folder){
      [Bool]$query = $True;
      ForEach($f In $Folder){
         [String]$uri += "filter.folders=$f`&"
      }
   }
   If($Name){
      [Bool]$query = $True;
      ForEach($n In $Name){
         [String]$uri += "filter.names=$n`&"
      }
   }
   If($State){
      [Bool]$query = $True;
      [String]$uri += $("filter.connection`_states`=" + $State.ToUpper() + "`&")
   }
   If($Standalone){
      [Bool]$query = $True;
      [String]$uri += $("filter.standalone`=" + ($Standalone.ToString()).ToLower() + "`&")
   }
   If($query){
      [String]$uri = $uri.Replace("/hostfilter.", "/host`?filter.")
      If($uri.EndsWith("`&")){
         [String]$uri = $uri.SubString(0, $uri.Length -1)
      }
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the ESX Hosts.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated ESX Hosts for Virtual Center ""$Server"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating ESX Hosts for Virtual Center ""$Server"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VIHost.
#'------------------------------------------------------------------------------
Function Get-VIDatacenter{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The Vcenter Server Hostname, FQDN or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Server,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter datacenter managed object references")]
      [Array]$DataCenter,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter Folder managed object references")]
      [Array]$Folder,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter Datacenter names")]
      [Array]$Name,
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for Vcenter authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'------------------------------------------------------------------------------
   #'Set the URI for querying input parameters if required.
   #'------------------------------------------------------------------------------
   [String]$uri = "https://$Server/rest/vcenter/datacenter"
   [Bool]$query = $False;
   If($DataCenter){
      [Bool]$query = $True;
      ForEach($dc In $DataCenter){
         [String]$uri += "filter.datacenters=$dc`&"
      }
   }
   If($Folder){
      [Bool]$query = $True;
      ForEach($f In $Folder){
         [String]$uri += "filter.folders=$f`&"
      }
   }
   If($Name){
      [Bool]$query = $True;
      ForEach($n In $Name){
         [String]$uri += "filter.names=$n`&"
      }
   }
   If($query){
      [String]$uri = $uri.Replace("/datacenterfilter.", "/datacenter`?filter.")
      If($uri.EndsWith("`&")){
         [String]$uri = $uri.SubString(0, $uri.Length -1)
      }
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Datacenter.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated Datacenter for Virtual Center ""$Server"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Datacenter for Virtual Center ""$Server"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VIDatacenter.
#'------------------------------------------------------------------------------
Function Get-VICluster{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The Vcenter Server Hostname, FQDN or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Server,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter cluster managed object references")]
      [Array]$Cluster,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter datacenter managed object references")]
      [Array]$DataCenter,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter Folder managed object references")]
      [Array]$Folder,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter Cluster names")]
      [Array]$Name,
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for Vcenter authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'------------------------------------------------------------------------------
   #'Set the URI for querying input parameters if required.
   #'------------------------------------------------------------------------------
   [String]$uri = "https://$Server/rest/vcenter/cluster"
   [Bool]$query = $False;
   If($Cluster){
      [Bool]$query = $True;
      ForEach($c In $Cluster){
         [String]$uri += "filter.clusters=$c`&"
      }
   }
   If($DataCenter){
      [Bool]$query = $True;
      ForEach($dc In $DataCenter){
         [String]$uri += "filter.datacenters=$dc`&"
      }
   }
   If($Folder){
      [Bool]$query = $True;
      ForEach($f In $Folder){
         [String]$uri += "filter.folders=$f`&"
      }
   }
   If($Name){
      [Bool]$query = $True;
      ForEach($n In $Name){
         [String]$uri += "filter.names=$n`&"
      }
   }
   If($query){
      [String]$uri = $uri.Replace("/clusterfilter.", "/cluster`?filter.")
      If($uri.EndsWith("`&")){
         [String]$uri = $uri.SubString(0, $uri.Length -1)
      }
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Cluster.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated Cluster for Virtual Center ""$Server"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating Cluster for Virtual Center ""$Server"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VICluster.
#'------------------------------------------------------------------------------
Function Get-VIFolder{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory = $True, HelpMessage = "The Vcenter Server Hostname, FQDN or IP Address")]
      [ValidateNotNullOrEmpty()]
      [String]$Server,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter datacenter managed object references")]
      [Array]$DataCenter,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter folder managed object references")]
      [Array]$Folder,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter folder names")]
      [Array]$Name,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter parent folder managed object references")]
      [Array]$ParentFolder,
      [Parameter(Mandatory = $False, HelpMessage = "The Vcenter folder type. Valid values are 'datacenter', 'datacenter', 'host', 'network' and 'virtual_machine'")]
      [ValidateSet("datacenter","datastore","host","network","virtual_machine")]
      [String]$FolderType,
      [Parameter(Mandatory = $True, HelpMessage = "The vCenter Session ID")]
      [ValidateNotNullOrEmpty()]
      [String]$SessionID
   )
   #'---------------------------------------------------------------------------
   #'Set the headers for Vcenter authentication.
   #'---------------------------------------------------------------------------
   $headers = @{
      "vmware-api-session-id" = $SessionID
      "Accept"                = "application/json"
   }
   #'------------------------------------------------------------------------------
   #'Set the URI for querying input parameters if required.
   #'------------------------------------------------------------------------------
   [String]$uri = "https://$Server/rest/vcenter/folder"
   [Bool]$query = $False;
   If($Name){
      [Bool]$query = $True;
      ForEach($n In $Name){
         [String]$uri += "filter.names=$n`&"
      }
   }
   If($DataCenter){
      [Bool]$query = $True;
      ForEach($dc In $DataCenter){
         [String]$uri += "filter.datacenters=$dc`&"
      }
   }
   If($Folder){
      [Bool]$query = $True;
      ForEach($f In $Folder){
         [String]$uri += "filter.folders=$f`&"
      }
   }
   If($ParentFolder){
      [Bool]$query = $True;
      ForEach($p In $ParentFolder){
         [String]$uri += "filter.parent_folders=$p`&"
      }
   }
   If($FolderType){
      [String]$uri += $("filter.type=" + $FolderType.ToUpper() + "`&")
   }
   If($query){
      [String]$uri = $uri.Replace("/folderfilter.", "/folder`?filter.")
      If($uri.EndsWith("`&")){
         [String]$uri = $uri.SubString(0, $uri.Length -1)
      }
   }
   If($uri.EndsWith("`&")){
      [String]$uri = $uri.SubString(0, $uri.Length -1)
   }
   #'---------------------------------------------------------------------------
   #'Enumerate the Folder.
   #'---------------------------------------------------------------------------
   Try{
      $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
      Write-Host "Enumerated folder for Virtual Center ""$Server"" using URI ""$uri"""
   }Catch{
      Write-Warning -Message $("Failed Enumerating folder for Virtual Center ""$Server"" using URI ""$uri"". Error " + $_.Exception.Message + ". Status Code " + $_.Exception.Response.StatusCode.value__)
      Return $Null;
   }
   Return $response;
}#End Function Get-VIFolder.
#'------------------------------------------------------------------------------
Function ConvertTo-Hashtable{
   [CmdletBinding()]
   [OutputType('hashtable')]
   Param(
      [Parameter(ValueFromPipeline)]
      $InputObject
   )
   #'---------------------------------------------------------------------------
   #'Return null if the input is null. This can happen when calling the function
   #'recursively and a property is null.
   #'---------------------------------------------------------------------------
   If($Null -eq $InputObject){
      Return $Null;
   }
   #'---------------------------------------------------------------------------
   #'Check if the input is an array or collection. If so, we also need to
   #'convert those types into hash tables as well. This function will convert
   #'all child objects into hash tables (if applicable)
   #'---------------------------------------------------------------------------
   If($InputObject -is [System.Collections.IEnumerable] -And $InputObject -IsNot [String]){
      $collection = @(
         ForEach($object In $InputObject){
            ConvertTo-Hashtable -InputObject $object
         }
      )
      #'------------------------------------------------------------------------
      #'Return the array but don't enumerate it because the object may be complex
      #'------------------------------------------------------------------------
      Write-Output -NoEnumerate $collection
   }ElseIf($InputObject -Is [PSObject]){
      #'------------------------------------------------------------------------
      #'If the object has properties that need enumeration Convert it to its own
      #'hash table and return it
      #'------------------------------------------------------------------------
      $hash = @{}
      ForEach($property in $InputObject.PSObject.Properties){
         $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
      }
      Return $hash;
   }Else{
      #'------------------------------------------------------------------------
      #'If the object isn't an array, collection, or other object, it's already a
      #'hash table so just return it.
      #'------------------------------------------------------------------------
      Return $InputObject;
   }
}#End Function ConvertTo-Hashtable.
#'------------------------------------------------------------------------------
#'Set the certificate policy and TLS version.
#'------------------------------------------------------------------------------
<#
Add-Type @"
   using System.Net;
   using System.Security.Cryptography.X509Certificates;
   public class TrustAllCertsPolicy : ICertificatePolicy {
   public bool CheckValidationResult(
   ServicePoint srvPoint, X509Certificate certificate,
   WebRequest request, int certificateProblem) {
      return true;
   }
}
"@
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#>
#'------------------------------------------------------------------------------
