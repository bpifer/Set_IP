$store = ($env:computername).Substring(4,4)
$build = ($env:computername).IndexOf("-")
$buildType = ($env:computername).Substring($build+1)

$conn = get-wmiobject win32_networkadapter | select netconnectionstatus, netconnectionid | Where-Object {$_.netconnectionstatus -eq "2"}
$connection = $conn.netconnectionid

If ($buildType -eq "SRV"){
    
    $backoffice = "WPAF$Store-X1"

    If (Test-Connection -ComputerName $backoffice -Count 1){

    $backofficeIP = (Test-Connection -ComputerName $backoffice -Count 1).IPV4Address.IPAddressToString 
    $lastOctet = ([ipaddress]$backofficeIP).GetAddressBytes()[3]
    $gatewayOctet = $lastOctet + 10 
    $defaultGateway = $backofficeIP.Remove($backofficeIP.LastIndexOf('.')) + "." + $gatewayOctet
    $buildIP = $backofficeIP.Remove($backofficeIP.LastIndexOf('.')) + "." + ($gatewayOctet - 1)
    }
    Else{
    Write-host Back office computer is not online. Unable to get the IP address
    Sleep 15
    Exit 
    }
}

Else{

    $srv = "WPAF$Store-SRV"

    If (Test-Connection -ComputerName $srv -Count 1){

    $serverIP = (Test-Connection -ComputerName $srv -Count 1).IPV4Address.IPAddressToString
    $lastOctet = ([ipaddress]$serverIP).GetAddressBytes()[3]
    $gateway = $lastOctet + 1
    $defaultGateway = $serverIP.Remove($serverIP.LastIndexOf('.')) + "." + $gateway

    #X1 Computer
    if ($buildType -eq "X1"){
    Write-host "Build is a back office computer"
    $x1 = $gateway - 10
    $buildIP = $serverIP.Remove($serverIP.LastIndexOf('.')) + "." + $x1 
    }

    #Terminal Build
    If (($buildType -ne "x1") -and ($buildType -ne "SRV")){
    $terminal = $gateway - 9 - $buildType
    $buildIP = $serverIP.Remove($serverIP.LastIndexOf('.')) + "." + $terminal
    }

    }
    Else{
    Write-host Server computer is not online. Unable to get the IP address
        Sleep 15
    Exit 
    }
}
   
netsh int ip set address $connection static $buildIP 255.255.255.224 $defaultGateway 1
netsh int ip set dns $connection static 10.49.201.163 primary
netsh int ip add dns $connection 10.59.1.16 INDEX=2