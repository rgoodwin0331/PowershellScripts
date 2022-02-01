Import-Module ActiveDirectory
 
# Get a list of all the OUs in the domain
 
# Below the list is sorted by CanonicalName in descending order intentionally. This was
# done so that child OUs are checked first to determine if they are empty. This information
# is then used when checking the parent OU so that empty child OUs are not counted when
# determining if a parent OU should be considered empty.
 
$ouList = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName |
    Sort-Object -Property CanonicalName -Descending
 
# Put together a list of all empty OUs in the domain
 
$report = @()
foreach ($ou in $ouList) {
 
    # The Where-Object line below is the logic that excludes any empty OUs underneath the
    # current OU for purposes of determining if this OU should be considered empty.
 
    # The Select-Object line is included here primarily to increase how quickly we process
    # through the OUs as we don't really care how many objects are underneath the OU only
    # that there are object (or not) underneath.
 
    $objectList = Get-ADObject -Filter * -SearchBase $ou.DistinguishedName -SearchScope OneLevel |
        Where-Object {$report.DistinguishedName -notcontains $_.DistinguishedName} |
        Select-Object -First 1
 
    # If we didn't find any objects underneath the OU, add it to the report
    
    if (-not $objectList) {
        $report += $ou
    }
}
 
# Export the report
 
$report | Sort-Object -Property CanonicalName | 
    Select-Object CanonicalName, Name, DistinguishedName |
    Export-Csv "C:\DomainReporting\EmptyOUs.csv" -NoTypeInformation