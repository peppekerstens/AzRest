function Get-AzRestWadMetrics {
    <#
    trying to get 'Guest (classic)' metrics from virtual machine - does not work. 
    result from https://docs.microsoft.com/en-us/azure/azure-monitor/platform/rest-api-walkthrough
    "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metricDefinitions?api-version=2018-01-01"
    does not show any entries
    probable method:
    - detect WAD extension and settings
    - dive into tables of WAD, stored in the storage account connected to WAD
    - get the values
    - base tables will be:
        - SchemasTable
        - WADDiagnosticInfrastructureLogsTable
        - WADMetrics*
        - WADPerfomanceCountersTable
        - WADWindowsEventlogsTable
    #https://docs.microsoft.com/en-us/rest/api/monitor/metricnamespaces/list
    #https://docs.microsoft.com/en-us/azure/azure-monitor/platform/collect-custom-metrics-guestos-resource-manager-vm
    #>
    param(
        [string]$ResourceUri
        ,
        [PSObject]$token
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    #Invoke-AzRestMethod -Uri "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metricNamespaces?api-version=2017-12-01-preview" @splatToken
    Invoke-AzRestMethod -Uri "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metrics?metricnames='Memory\Available Bytes'&api-version=2018-01-01&metricnamespace='Guest'" @splatToken
    #Invoke-AzRestMethod -Uri "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metrics?timespan={timespan}&interval={interval}&metricnames={metricnames}&aggregation={aggregation}&top={top}&orderby={orderby}&$filter={$filter}&resultType={resultType}&api-version=2018-01-01&metricnamespace={metricnamespace}"
}