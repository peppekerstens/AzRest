function Get-AzRestVmInstanceView {
    param(
        [parameter(Mandatory=$true)]
        [string]$vmAzResourceId
        ,
        [PSObject]$token
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    #https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{vmName}/instanceView?api-version=2019-03-01       
    Invoke-AzRestMethod -Uri "https://management.azure.com/$($vmAzResourceId)/instanceView?api-version=2019-03-01" @splatToken -raw
}