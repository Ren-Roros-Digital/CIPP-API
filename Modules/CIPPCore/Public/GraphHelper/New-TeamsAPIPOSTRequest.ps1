function New-TeamsAPIPOSTRequest {
    <#
    .FUNCTIONALITY
    Internal
    #>
    Param (
        $Uri,
        $tenantID,
        $Method = 'PUT',
        $Resource = '48ac35b8-9aa8-4d74-927d-1f4a14a0b239',
        $ContentType = 'application/json; charset=utf-8',
        $body
    )

    $APIName = $TriggerMetadata.FunctionName
    Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APIName -message 'Accessed this API' -Sev 'Debug'

    if ((Get-AuthorisedRequest -Uri $uri -TenantID $tenantid)) {
        $token = Get-ClassicAPIToken -Tenant $tenantid -Resource $Resource

        $headers = @{
            Authorization            = "Bearer $($token.access_token)"
            'x-ms-client-request-id' = [guid]::NewGuid().ToString()
            'x-ms-client-session-id' = [guid]::NewGuid().ToString()
            'x-ms-correlation-id'    = [guid]::NewGuid()
            'X-Requested-With'       = 'XMLHttpRequest'
            'x-ms-tnm-applicationid' = '045268c0-445e-4ac1-9157-d58f67b167d9'
        }

        try {
            $Data = Invoke-RestMethod -Uri $uri -Method $Method -Body $body -ContentType $ContentType -Headers $headers
        } catch [System.Net.WebException] {
            Write-LogMessage -API 'Standards' -Tenant $tenant -message "Teams API Post Request failed. Error: $($_.exception.message)" -sev Error

            $Message = if ($_.ErrorDetails.Message) {
                Get-NormalizedError -Message $_.ErrorDetails.Message
            } else {
                $_.Exception.message
            }
            Write-LogMessage -API $APIName -Tenant $tenantID -message "Teams API PUT Request failed. Error: $Message" -sev Error
            throw $Message
        }
        return $Data
    } else {
        Write-LogMessage -API $APIName -Tenant $tenantID -message "Not allowed. You cannot manage your own tenant or tenants not under your scope" -sev Error
        Write-Error 'Not allowed. You cannot manage your own tenant or tenants not under your scope'
    }
}
