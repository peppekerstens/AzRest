$customer = $null
$datapath = resolve-path -path 'c:\temp\metrics'
$days = 30
#get metrics data
import-Module AzRest
$subs = Get-AzRestSubscription
if ($customer){
    $sub = $subs.where{$_.DisplayName -like "$($customer)*"}
    Get-MetricsParallel -sub $sub -customer $customer -path $datapath -days $days
} else {
    foreach ($sub in $subs){
        $subPath = Join-Path -Path $datapath -ChildPath $sub.DisplayName
        If (!(Test-Path -Path $subPath)){
            New-Item -Path $subPath -ItemType 'Directory'
        }
        If (($sub.DisplayName).length -gt 20){
            $cust = "$($sub.DisplayName)".SubString(0,20)
        } Else {
            $cust = $sub.DisplayName
        }
        Get-MetricsParallel -sub $sub -customer $cust -path $subPath -days $days   
    } 
}
