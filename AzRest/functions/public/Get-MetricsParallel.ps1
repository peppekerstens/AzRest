#requires -Version 7
function Get-MetricsParallel{
    [CmdletBinding()]
    param($sub,$path,$days)
    $vms = Get-AzRestVM -SubscriptionId $sub.subscriptionId
    
    Write-Verbose -Message "Processing subscription $($sub.displayname) "
    $subPath = Join-Path -Path $path -ChildPath $sub.DisplayName
    If (!(Test-Path -Path $subPath)){
        New-Item -Path $subPath -ItemType 'Directory'
    }
    If (($sub.DisplayName).length -gt 20){
        $customer = "$($sub.DisplayName)".SubString(0,20)
    } Else {
        $customer = $sub.DisplayName
    }

    $token = Get-AzRestToken
    #$newDayMetrics = @()
    #$newOfficeMetrics= @()
    $vms | ForEach-Object -ThrottleLimit 20 -Parallel {
        import-module AzRest
        $customer = $using:customer
        $basepath = $using:subpath
        $days = $using:days
        $token = $using:token
        $filename = "$($customer)-$($_.name)-daymetrics-$((Get-Date).ToString('yyyyMMddHHmm')).json"
        $path = Join-Path -Path $basepath -ChildPath $filename
        #write-verbose -message "$($_.name): Loading existing metrics" -verbose
        #Try{
        #    $Metrics = Get-Content $path -ErrorAction Stop | convertfrom-json
        #}
        #Catch{
        $Metrics = @()
        #}
        write-verbose -message "$($_.name): Getting day metrics" -verbose
        $Metrics += Invoke-AzRestVmMetricsReport -vm $_ -days $days -token $token
        write-verbose -message "$($_.name): Writing result to $($filename)" -verbose
        $Metrics | ConvertTo-Json -depth 7 | Out-File -Path $path -Force
        #write-verbose -message "adding to $($file)" -verbose
        #$newDayMetrics | ConvertTo-Json -depth 7 | Out-File -Path (Join-Path -Path $datapath -ChildPath "$($customer)-$($_.vmname)-daymetrics.json") -append
        
        $filename = "$($customer)-$($_.name)-officemetrics-$((Get-Date).ToString('yyyyMMddHHmm')).json"
        $path = Join-Path -Path $basepath -ChildPath $filename
        #write-verbose -message "$($_.name): Loading existing metrics" -verbose
        #Try{
        #    $Metrics = Get-Content $path -ErrorAction Stop | convertfrom-json
        #}
        #Catch{
        $Metrics = @()
        write-verbose -message "$($_.name): Getting officehours metrics" -verbose
        $Metrics += Invoke-AzRestVmMetricsReport -vm $_ -days $days -OfficeHours -token $token
        write-verbose -message "$($_.name): Writing result to $($filename)" -verbose
        $Metrics | ConvertTo-Json -depth 7 | Out-File -Path $path -Force
    }
}