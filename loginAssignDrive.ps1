# v1.0 Kevin Yu (25/09/25)
# This logon script is designed to assign specific network drives to users
# based on their Organisational Unit (OU)

Import-Module ActiveDirectory

# OU Hierarchy and mappings
$DriveMappings = @(
    @{ OUPath = "Academic"; Drive = "U:"; Path = "\\10.1.10.8\Academic"},
    @{ OUPath = "Accreditation"; Drive = "Z:"; Path = "\\10.1.10.8\Accreditation"},
    @{ OUPath = "Admissions"; Drive = "N:"; Path = "\\10.1.10.8\Admissions"},
    @{ OUPath = "Finance"; Drive = "I:"; Path = "\\10.1.10.8\Finance"},
    @{ OUPath = "ICT"; Drive = "X:"; Path = "\\10.5.10.8\ICT"},
    @{ OUPath = "HOP_LearningSkillsCentre"; Drive = "Y:"; Path = "\\10.1.10.8\Learning Skills Centre"},
    @{ OUPath = "Library"; Drive = "L:"; Path = "\\10.1.10.8\Library"},
    @{ OUPath = "Management"; Drive = "M:"; Path = "\\10.1.10.8\Management"},
    @{ OUPath = "Marketing"; Drive = "K:"; Path = "\\10.1.10.8\Marketing"},
    @{ OUPath = "StudentServices"; Drive = "V:"; Path = "\\10.1.10.8\Student Services"},
    @{ OUPath = "HOP_TeachingLearning"; Drive = "T:"; Path = "\\10.1.10.8\Teaching_Learning"}
)

$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$username = $user.Split("\")[1]

# Distinguished Name
$dn = (Get-ADUser - Identity $username).DistinguishedName

# Extract Organisational Units
$ouList = ($dn -split ",") -match "^OU=" -replace "^OU=",""

# Assign drives to user
# Always map public folder
$publicDrive = "P:"
$publicPath  = "\\10.5.10.8\Public folder"

# Remove if already mapped incorrectly
if (Test-Path $publicDrive) {
    $currentTarget = (Get-PSDrive -Name $publicDrive.TrimEnd(":")).Root
    if ($currentTarget -ne $publicPath) {
        net use $publicDrive /delete /y | Out-Null
        New-PSDrive -Name $publicDrive.TrimEnd(":") -PSProvider FileSystem -Root $publicPath -Persist
    }
} else {
    # Map if not already present
    New-PSDrive -Name $publicDrive.TrimEnd(":") -PSProvider FileSystem -Root $publicPath -Persist
}

foreach ($map in $DriveMappings) {
    if ($ouList -contains $map.OUpath) {
        # if drive already exists, remove it
        if (Test-Path $map.Drive) {
            net use $($map.Drive) /delete /y | Out-Null
        }

        # assign the drive
        New-PSDrive -Name $map.Drive.TrimEnd(":") -PSProvider FileSystem -Root $map.Path -Persist -Scope Global
    }
}

# display a message
#todo