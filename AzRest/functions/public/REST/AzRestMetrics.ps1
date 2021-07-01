function Get-AzRestMetrics {
    <#
    .SYNOPSIS
    Gets metrics information for a certain resource
    
    .DESCRIPTION
    REST based function which gets  metrics information for a certain resource. Output is a hashtable based PS object.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials

    .NOTES
    Metric                              Metric Display Name                             Unit             Aggregation Type   Description
    Percentage CPU                      Percentage CPU                                  Percent          Average            The percentage of allocated compute units that are currently in use by the Virtual Machine(s)
    Network In                          Network In Billable (Deprecated)                Bytes            Total              The number of billable bytes received on all network interfaces by the Virtual Machine(s) (Incoming Traffic)
    Network Out                         Network Out Billable (Deprecated)               Bytes            Total              The number of billable bytes out on all network interfaces by the Virtual Machine(s) (Outgoing Traffic) (Dep
    Disk Read Bytes                     Disk Read Bytes                                 Bytes            Total              Bytes read from disk during monitoring period
    Disk Write Bytes                    Disk Write Bytes                                Bytes            Total              Bytes written to disk during monitoring period
    Disk Read Operations/Sec            Disk Read Operations/Sec                        CountPerSecond   Average            Disk Read IOPS
    Disk Write Operations/Sec           Disk Write Operations/Sec                       CountPerSecond   Average            Disk Write IOPS
    CPU Credits Remaining               CPU Credits Remaining                           Count            Average            Total number of credits available to burst
    CPU Credits Consumed                CPU Credits Consumed                            Count            Average            Total number of credits consumed by the Virtual Machine
    Per Disk Read Bytes/sec             Data Disk Read Bytes/Sec (Deprecated)           CountPerSecond   Average            Bytes/Sec read from a single disk during monitoring period
    Per Disk Write Bytes/sec            Data Disk Write Bytes/Sec (Deprecated)          CountPerSecond   Average            Bytes/Sec written to a single disk during monitoring period
    Per Disk Read Operations/Sec        Data Disk Read Operations/Sec (Deprecated)      CountPerSecond   Average            Read IOPS from a single disk during monitoring period
    Per Disk Write Operations/Sec       Data Disk Write Operations/Sec (Deprecated)     CountPerSecond   Average            Write IOPS from a single disk during monitoring period
    Per Disk QD                         Data Disk QD (Deprecated)                       Count            Average            Data Disk Queue Depth(or Queue Length)
    OS Per Disk Read Bytes/sec          OS Disk Read Bytes/Sec (Deprecated)             CountPerSecond   Average            Bytes/Sec read from a single disk during monitoring period for OS disk
    OS Per Disk Write Bytes/sec         OS Disk Write Bytes/Sec (Deprecated)            CountPerSecond   Average            Bytes/Sec written to a single disk during monitoring period for OS disk
    OS Per Disk Read Operations/Sec     OS Disk Read Operations/Sec (Deprecated)        CountPerSecond   Average            Read IOPS from a single disk during monitoring period for OS disk
    OS Per Disk Write Operations/Sec    OS Disk Write Operations/Sec (Deprecated)       CountPerSecond   Average            Write IOPS from a single disk during monitoring period for OS disk
    OS Per Disk QD                      OS Disk QD (Deprecated)                         Count            Average            OS Disk Queue Depth(or Queue Length)
    Data Disk Read Bytes/sec            Data Disk Read Bytes/Sec (Preview)              CountPerSecond   Average            Bytes/Sec read from a single disk during monitoring period
    Data Disk Write Bytes/sec           Data Disk Write Bytes/Sec (Preview)             CountPerSecond   Average            Bytes/Sec written to a single disk during monitoring period
    Data Disk Read Operations/Sec       Data Disk Read Operations/Sec (Preview)         CountPerSecond   Average            Read IOPS from a single disk during monitoring period
    Data Disk Write Operations/Sec      Data Disk Write Operations/Sec (Preview)        CountPerSecond   Average            Write IOPS from a single disk during monitoring period
    Data Disk Queue Depth               Data Disk Queue Depth (Preview)                 Count            Average            Data Disk Queue Depth(or Queue Length)
    OS Disk Read Bytes/sec              OS Disk Read Bytes/Sec (Preview)                CountPerSecond   Average            Bytes/Sec read from a single disk during monitoring period for OS disk
    OS Disk Write Bytes/sec             OS Disk Write Bytes/Sec (Preview)               CountPerSecond   Average            Bytes/Sec written to a single disk during monitoring period for OS disk
    OS Disk Read Operations/Sec         OS Disk Read Operations/Sec (Preview)           CountPerSecond   Average            Read IOPS from a single disk during monitoring period for OS disk
    OS Disk Write Operations/Sec        OS Disk Write Operations/Sec (Preview)          CountPerSecond   Average            Write IOPS from a single disk during monitoring period for OS disk
    OS Disk Queue Depth                 OS Disk Queue Depth (Preview)                   Count            Average            OS Disk Queue Depth(or Queue Length)
    Inbound Flows                       Inbound Flows                                   Count            Average            Inbound Flows are number of current flows in the inbound direction (traffic going into the VM)
    Outbound Flows                      Outbound Flows                                  Count            Average            Outbound Flows are number of current flows in the outbound direction (traffic going out of the VM)
    Inbound Flows Maximum Creation Rate Inbound Flows Maximum Creation Rate (Preview)   CountPerSecond   Average            The maximum creation rate of inbound flows (traffic going into the VM)
    Outbound Flows Maximum Creation RateOutbound Flows Maximum Creation Rate (Preview)  CountPerSecond   Average            The maximum creation rate of outbound flows (traffic going out of the VM)
    Premium Data Disk Cache Read Hit    Premium Data Disk Cache Read Hit (Preview)      Percent          Average            Premium Data Disk Cache Read Hit
    Premium Data Disk Cache Read Miss   Premium Data Disk Cache Read Miss (Preview)     Percent          Average            Premium Data Disk Cache Read Miss
    Premium OS Disk Cache Read Hit      Premium OS Disk Cache Read Hit (Preview)        Percent          Average            Premium OS Disk Cache Read Hit
    Premium OS Disk Cache Read Miss     Premium OS Disk Cache Read Miss (Preview)       Percent          Average            Premium OS Disk Cache Read Miss
    Network In Total                    Network In Total                                Bytes            Total              The number of bytes received on all network interfaces by the Virtual Machine(s) (Incoming Traffic)
    Network Out Total                   Network Out Total                               Bytes            Total              The number of bytes out on all network interfaces by the Virtual Machine(s) (Outgoing Traffic)
    
    .LINK
    https://docs.microsoft.com/en-us/rest/api/monitor/metrics/list
    https://docs.microsoft.com/en-us/azure/azure-monitor/platform/metrics-supported#microsoftcomputevirtualmachines
    #>
    
    param(
        [string]$ResourceUri
        ,
        [string]$Name
        ,
        [string]$timespan
        ,
        [PSObject]$token
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    if (-not($timespan)){
        #code to create timespan
        $yesterday = ((Get-Date).ToUniversalTime().AddDays(-1)).ToString('yyyy-MM-dd')
        $timespan = "&timespan=$($yesterday)T00:00:01Z/$($yesterday)T23:59:59Z"
    }

    Invoke-AzRestMethod -Uri "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnames=$name$($timespan)" @splatToken
    #ToDo figure out getting the 'maximum' agregationtype
    #based on https://docs.microsoft.com/en-us/azure/azure-monitor/platform/rest-api-walkthrough, other agregationtypes should be available, but this does not work:
    #Invoke-AzRestMethod -Uri "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnames=$name$($timespan)&aggregation='maximum'" @splatToken
}