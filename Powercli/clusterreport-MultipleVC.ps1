# PowerCLI script to Full the VC,Cluster,NoOfHosts, NoOfcpu/Cores/Threads/Memory per Cluster
# Must be run in VMware PowerCLI
# written by Linga 
# BEGIN Variables

#$VCenter = Read-Host -Prompt 'Please input your Vcenter server  name'
#for Multiple Vcenter Please comment  #  then remove Comment #  next line
$User = Read-Host -Prompt 'Please enter User Name to Login'
$passwd = Get-Content .\passwd

$VCenter = Get-Content .\vcenters

## Connecto to Vcenter
 Connect-VIServer -Server $VCenter -User $User -Password $passwd

Foreach ($vcserver in $global:DefaultVIServers) {

Write-Host "Starting Reports Pulling from $vcserver, Please check once its completed" -ForegroundColor Yellow

Get-Cluster -PipelineVariable cluster -Server $vcserver|

Get-VMHost |

Select @{N='Cluster';E={$cluster.Name}},Name,Model,ProcessorType,@{N="NumCPU";E={($_| Get-View).Hardware.CpuInfo.NumCpuPackages}},@{N="vCenter";E={$_.ExtensionData.CLient.ServiceUrl.Split('/')[2]}},

    @{N='NumCpuCores';E={$_.ExtensionData.Hardware.CpuInfo.NumCpuCores}},@{N='TotalCPUthreads';E={($_|Get-View).Summary.Hardware.NumCpuThreads}},

    @{N='MemoryTotalGB';E={[math]::Round($_.MemoryTotalGB,1)}} |

Group-Object -Property Cluster |

ForEach-Object -Process {

    $cl = $_.Name
	$g = (Get-Cluster $cl|Get-View).Client.ServiceUrl.Split('/')[2]
	$h = (Get-Cluster $cl|Get-VMHost).Count
	
    $_.Group | Group-Object -Property Model |

    ForEach-Object -Process {

        $obj = [ordered]@{
			Vcenter = $g
			
            Cluster = $cl
			
			NoOfHosts = $h

            Model = $_.Name
			
			TotalCPUs = ($_.Group | Measure-Object -Property NumCPU -Sum ).Sum
			
            NumCpuCores = ($_.Group | Measure-Object -Property NumCpuCores -Sum ).Sum
			
			TotalCPUthreads = ($_.Group | Measure-Object -Property TotalCPUthreads -Sum ).Sum
			
			MemoryTotalGB = ($_.Group | Measure-Object -Property MemoryTotalGB -Sum ).Sum

        }

        New-Object psobject -Property $obj

    }

}|Export-Csv .\"$vcserver"-report.csv
} Write-Host "Completed Reports Pulling, Please check the Report" -ForegroundColor Green

# Disconnect from vCenter
Disconnect-VIserver * -Confirm:$false -Force