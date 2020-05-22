<#'-----------------------------------------------------------------------------
'Script Name : NewVSCFlexvol.ps1 
'Author      : Matthew Beattie
'Email       : mbeattie@netapp.com
'Created     : 2020-05-22
'Description : Creates a new Flexvol volume using the NetApp VSC REST API's.
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
'-------------------------------------------------------------------------------
Step 1) Ensure the 'NewVSCFlexvol.ps1' file and 'VSC.psm1' are saved in the same directory.

C:\Scripts\PowerShell\Projects\VSC> Get-ChildItem | Select-Object -ExpandProperty Name
GetVSCDatastores.ps1
VSC.psm1

Step 2) Create a PowerShell Credential object to connect to VSC.

C:\Scripts\PowerShell\Projects\VSC> $credentials = Get-Credential -Credential administrator@vsphere.local

Step 3) Invoke the 'NewVSCFlexvol.ps1' PowerShell script and pass it the input parameters required to create the new VSC Flexvol Volume to the script.

C:\Scripts\PowerShell\Projects\VSC> .\NewVSCFlexvol.ps1 -VSC 'vsc.demo.netapp.com' -PortNumber 8143 -ClusterIP 192.168.0.101 -VserverName svm1 -ProfileName Silver -AggregateName aggr1_01 -VolumeName vvol_beats_vol4 -SizeGB 10 -Credential $credentials

Authenticated to VSC "vsc.demo.netapp.com" using URI "https://vsc.demo.netapp.com:8143/api/rest/2.0/security/user/login" as VMWare vCenter user "administrator@vsphere.local"
Created FlexVol "vvol_beats_vol4" on vserver "svm1" on cluster "" using URI "https://vsc.demo.netapp.com:8143/api/rest/2.0/storage/flexvolumes"

id                 : 10046253
typeStr            : FlexVol
name               : vvol_beats_vol4
junctionPath       : /vvol_beats_vol4
sizeAvailable      : 10737184768
aggregateUuid      : 69031f6d-2df9-4e2c-8dbd-4a256c6990bc
sizeTotal          : 10737418240
sizeUsed           : 233472
storageController  : @{id=10000151; typeStr=StorageController; name=svm1; controllerIp=192.168.0.101; controllerId=0; uri=vsc:vsc:StorageController:null/10000151}
uuid               : fb4292d7-9c1c-11ea-85f5-005056011d47
hosedValue         : 0
aggrName           : aggr1_01
state              : online
type               : rw
autoGrowEnabled    : True
root               : False
tieringPolicy      : NONE
dedupeEnabled      : False
moving             : False
encryptionEnabled  : False
compressionEnabled : False
uri                : vsc:vsc:FlexVol:null/10046253

Logged out of VSC "vsc.demo.netapp.com" Session ID "21a002a98b82bfc7c3ab9173c812ee5100790808" using URI "https://vsc.demo.netapp.com:8143/api/rest/2.0/security/user/logout"
'-----------------------------------------------------------------------------#>
Param(
   [Parameter(Mandatory = $True, HelpMessage = "The VSC hostname, IP Address or FQDN")]
   [ValidateNotNullOrEmpty()]
   [String]$VSC,
   [Parameter(Mandatory = $False, HelpMessage = "The VSC Port Number. Default is 8143")]
   [Int]$PortNumber = 8143,
   [Parameter(Mandatory = $True, HelpMessage = "The Cluster IP Address")]
   [String]$ClusterIP,
   [Parameter(Mandatory = $True, HelpMessage = "The Vserver Name")]
   [String]$VserverName,
   [Parameter(Mandatory = $True, HelpMessage = "The Storage Capability Profile Name")]
   [String]$ProfileName,
   [Parameter(Mandatory = $True, HelpMessage = "The Aggregate Name to create the Flexvol volume on")]
   [String]$AggregateName,
   [Parameter(Mandatory = $True, HelpMessage = "The Flexvol Volume Name")]
   [String]$VolumeName,
   [Parameter(Mandatory = $False, HelpMessage = "The Volume Size in GigaBytes")]
   [Int]$SizeGB,
   [Parameter(Mandatory = $True, HelpMessage = "The Credential to authenticate to VSC")]
   [System.Management.Automation.PSCredential]$Credential
)
#'------------------------------------------------------------------------------
#'Set the certificate policy and TLS version.
#'------------------------------------------------------------------------------
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
#'------------------------------------------------------------------------------
#'Create the VSC Flexvol Volume.
#'------------------------------------------------------------------------------
Import-Module .\VSC.psm1
[String]$sessionId = Connect-VSCSession -VSC $VSC -Credential $Credential
$flexVol = New-VSCFlexvol -VSC $VSC -SessionID $sessionId -ClusterIP $ClusterIP -VserverName $VserverName -ProfileName $ProfileName -AggregateName $AggregateName -VolumeName $VolumeName -SizeGB $SizeGB
$flexVol.volume #'Note: If you prefer the output in a Hashtable than a PSObject use: '$flexvol.volume | ConvertTo-HashTable'
Disconnect-VSCSession -VSC $VSC -SessionID $sessionID
#'------------------------------------------------------------------------------
