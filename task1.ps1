param(
    [parameter(Mandatory=$true)][ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')][ipaddress]$ip_address_1,
    [parameter(Mandatory=$true)][ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')][ipaddress]$ip_address_2,
    [parameter(Mandatory=$true)][ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$|^\d{1,2}$')][string]$network_mask
)

# Validates network-mask and converts to [ipadress]
function Test-NetworkMask([string] $mask) {
    if ($mask -match '^\d{1,2}$') {
        # If mask is a CIDR prefix, convert to subnet mask
        $bits = [math]::Pow(2, [int]$mask) - 1
        $bits = $bits * [math]::Pow(2, (32 - [int]$mask))
        $subnet = [ipaddress](([uint32]$bits -shl (32 - [int]$mask)))
    }
    elseif ($mask -match '^(\d{1,3}\.){3}\d{1,3}$') {
        # If mask is already in IP address format
        $subnet = [ipaddress]$mask
    }
    else {
        Throw "Invalid network mask"
    }
    return $subnet
}

# Check if two ip addresses share the network
function Test-SameNetwork([ipaddress] $ip1, [ipaddress] $ip2, [ipaddress] $subnet) {
    $subnetBytes = $subnet.GetAddressBytes()
    $ip1Bytes = $ip1.GetAddressBytes()
    $ip2Bytes = $ip2.GetAddressBytes()

    for ($i = 0; $i -lt 4; $i++) {
        if (($ip1Bytes[$i] -band $subnetBytes[$i]) -ne ($ip2Bytes[$i] -band $subnetBytes[$i])) {
            return $false
        }
    }
    return $true
}

$subnet = Test-NetworkMask -mask $network_mask

if (Test-SameNetwork -ip1 $ip_address_1 -ip2 $ip_address_2 -subnet $subnet) {
    Write-Output "yes"
} else {
    Write-Output "no"
}


