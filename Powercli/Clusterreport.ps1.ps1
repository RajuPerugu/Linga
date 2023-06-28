# PowerCLI script to Full the NO of cpu/Threads/Memory per Cluster
# Must be run in VMware PowerCLI


$VCenter = Read-Host -Prompt 'Please input your Vcenter server  name'
#for Multiple Vcenter Please comment  #  then remove Comment #  next line

#$VCenter = $VCenter = Get-Content ./vcenters

## Connecto to Vcenter
Connect-viserver -Server $VCenter


Get-Cluster -PipelineVariable cluster |

Get-VMHost |

Select @{N='Cluster';E={$cluster.Name}},Name,Model,ProcessorType,@{N="NumCPU";E={($_| Get-View).Hardware.CpuInfo.NumCpuPackages}},@{N="vCenter";E={$_.ExtensionData.CLient.ServiceUrl.Split('/')[2]}},

    @{N='NumCpuCores';E={$_.ExtensionData.Hardware.CpuInfo.NumCpuCores}},@{N='TotalCPUthreads';E={($_|Get-View).Summary.Hardware.NumCpuThreads}},

    @{N='MemoryTotalGB';E={[math]::Round($_.MemoryTotalGB,1)}} |

Group-Object -Property Cluster |

ForEach-Object -Process {

    $cl = $_.Name
	
	$g = (Get-Cluster $cl|Get-View).Client.ServiceUrl
	
    $_.Group | Group-Object -Property ProcessorType |

    ForEach-Object -Process {

        $obj = [ordered]@{
			
			Vcenter = $g
			
            Cluster = $cl

            Model = $_.Name
			
			TotalCPUs = ($_.Group | Measure-Object -Property NumCPU -Sum ).Sum
			
            NumCpuCores = ($_.Group | Measure-Object -Property NumCpuCores -Sum ).Sum
			
			TotalCPUthreads = ($_.Group | Measure-Object -Property TotalCPUthreads -Sum ).Sum
			
			MemoryTotalGB = ($_.Group | Measure-Object -Property MemoryTotalGB -Sum ).Sum

        }

        New-Object psobject -Property $obj

    }

} |Export-Csv ./clusterreport.csv