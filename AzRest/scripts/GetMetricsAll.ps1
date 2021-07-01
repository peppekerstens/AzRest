#requires -Version 7
#voor 6 PS sessies tegelijk
remove-module AzRest -ErrorAction SilentlyContinue
$path = resolve-path -path 'c:\temp\metrics'
$days = 5
$limit = 1
#get metrics data
#import-Module AzRest
$subs = Get-AzRestSubscription
$subpart = [math]::Round($subs.count/$limit)
$subpartstart = $subpart*$part-$subPart
$subPartEnd = $subpart*$part
for ($i=$subpartstart; $i -le $subPartEnd; $i++){
    $sub = $subs[$i]
    Get-MetricsParallel -sub $sub -path $Path -days $days  
}
