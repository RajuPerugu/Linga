# PowerCLI-Extend-Disks.ps1
# Must be run in VMware PowerCLI
# written by Linga 
# BEGIN Variables

$VC = Read-Host -Prompt 'Please input your Vcenter server  name'

$GuestUser = Read-Host -Prompt 'Please enter the OS username as root'

#Please provide us the which disk you want to increase 1 - sda, 2 - sdb, 3 - sdc ---etc
$disknumber = Read-Host -Prompt ' Please Provide us which disk you want to icrease the Size'
# this will use for disk rescan at OS level.
#$deviceid = $disknumber - 1

#####this will helpout the disk name sda,sdb,sdc ...etc.
#$diskname = if ($disknunber -eq 1) {Write-Host sda} elseif ($disknumber -eq 2) {Write-Host sdb} elseif ($disknumber -eq 3) {Write-Host sdc}

#provide the final size of the disk  current Size + expanding size = final size. here we need to provide the final size.
$newdisksizeGB = Read-Host -Prompt ' Please provide us the final size of the disk in GB'

# get the list of VM servers to increase the disk size.
$user=$(cmd.exe /c echo %username%)
$vms = Get-Content C:\Users\$user\Desktop\vms.txt

# Connect to vCenter via PowerCLI, it will gives you the login Prompt for user and password.
Connect-VIServer $VC

# BEGIN foreach loop

 
# Have vSphere PowerCLI increase the size of the given hard disk in each target VM
Get-HardDisk -VM $vms| Where-Object {$_.Name -eq "Hard Disk $disknumber"} | Set-HardDisk -CapacityGB $newdisksizeGB -Confirm:$false

### VM level disk increase activity completed Now we are prgressing with VM OS level expansion.

Invoke-VMScript -VM $vms -ScriptText "echo 1 > /sys/bus/scsi/devices/0\:0\:2\:0/rescan;parted /dev/sdc resizepart 1 100%;pvresize /dev/sdc1;lvextend -l +100%FREE /dev/testvg/testlv;xfs_growfs /testplr;df -h /testplr " -GuestUser $GuestUser -GuestPassword W@lM@rt01!
###Invoke-VMScript -VM $vms -ScriptText `Read-Host -Prompt`  -GuestUser $GuestUser -GuestPassword $GuestPassword


# Disconnect from vCenter
Disconnect-VIserver -Confirm:$false