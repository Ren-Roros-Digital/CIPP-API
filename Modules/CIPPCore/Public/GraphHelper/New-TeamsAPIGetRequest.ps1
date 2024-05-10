function New-TeamsAPIGetRequest {
    <#
    .FUNCTIONALITY
    Internal
    #>
    Param (
        $Uri,
        $tenantID,
        $Method = 'GET',
        $Resource = '48ac35b8-9aa8-4d74-927d-1f4a14a0b239',
        $ContentType = 'application/json'
    )

    $APIName = $TriggerMetadata.FunctionName
    Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APIName -message 'Accessed this API' -Sev 'Debug'

    if ((Get-AuthorisedRequest -Uri $uri -TenantID $tenantid)) {
        $token = Get-ClassicAPIToken -Tenant $tenantid -Resource $Resource

        $NextURL = $Uri
        $ReturnedData = do {
            try {
                $Data = Invoke-RestMethod -ContentType "$ContentType;charset=UTF-8" -Uri $NextURL -Method $Method -Headers @{
                    Authorization            = "Bearer $($token.access_token)"
                    'x-ms-client-request-id' = [guid]::NewGuid().ToString()
                    'x-ms-client-session-id' = [guid]::NewGuid().ToString()
                    'x-ms-correlation-id'    = [guid]::NewGuid()
                    'X-Requested-With'       = 'XMLHttpRequest'
                    'x-ms-tnm-applicationid' = '045268c0-445e-4ac1-9157-d58f67b167d9'

                }
                $Data
                if ($noPagination) { $nextURL = $null } else { $nextURL = $data.NextLink }
                Write-LogMessage -API $APIName -Tenant $tenantID -message "Teams API Get Request successed" -sev Info
            } catch {
                Write-LogMessage -API $APIName -Tenant $tenantID -message "Teams API Get Request failed. Error: $_" -sev Error
                throw "Failed to make Teams API Get Request $_"
            }
        } until ($null -eq $NextURL)
        return $ReturnedData
    } else {
        Write-LogMessage -API $APIName -Tenant $tenantID -message "Not allowed. You cannot manage your own tenant or tenants not under your scope" -sev Error
        Write-Error 'Not allowed. You cannot manage your own tenant or tenants not under your scope'
    }
}