Function Get-OS_Arch() {
    $arch = $(Get-WmiObject Win32_OperatingSystem).OSArchitecture

    if ($arch -Like "*64*") {
        $arch = 64
    } elseif ($arch -Like "*32*") {
        $arch = 32
    }

    $arch
}

$python = Get-WmiObject Win32_product | where-object {$_.Name -Like "Python*"}

if ($python) {
    Write-Host "Python is already installed on your host! Skip installation"
} else {
    Write-Host "Installing python 2.7..."

    $arch = Get-OS_Arch
    if ($arch -eq 32) {
        .\msi\python-2.7.6.msi /passive
    } elseif ($arch -eq 64) {
        .\msi\python-2.7.6.amd64.msi /passive
    } else {
        Write-Host "Unknown OS architecture:" $arch
        return
     }
}
