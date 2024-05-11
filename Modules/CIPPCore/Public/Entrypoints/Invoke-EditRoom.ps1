using namespace System.Net

Function Invoke-EditRoom {
    <#
    .FUNCTIONALITY
    Entrypoint
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $TriggerMetadata.FunctionName
    Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APINAME -message 'Accessed this API' -Sev 'Debug'

    # Write to the Azure Functions log stream.
    Write-Host 'PowerShell HTTP trigger function processed a request.'

    # Interact with query parameters or the body of the request.
    $RequestBody = $Request.Body

    $Body = ([pscustomobject]$Request.body | Select-Object id, emailAddress, displayName, geoCoordinates, phone, placeId, nickname, building, floorNumber, floorLabel, label, capacity, bookingType, audioDeviceName, videoDeviceName, displayDeviceName, isWheelChairAccessible, tags, @{Name='address'; Expression={
        [pscustomobject]@{
            type                = [string] $_.address.type
            postOfficeBox       = [string] $_.address.postOfficeBox
            street              = [string] $_.address.street
            city                = [string] $_.address.city
            state               = [string] $_.address.state
            countryOrRegion     = [string] $_.address.countryOrRegion
            postalCode          = [string] $_.address.postalCode
        }
    }}) | ForEach-Object {
        $NonEmptyProperties = $_.psobject.Properties | Where-Object { $null -ne $_.Value } | Select-Object -ExpandProperty Name
        $_ | Select-Object -Property $NonEmptyProperties 
    }

    try {
        $params = @{
            tenantid = $RequestBody.tenantid
            uri = "https://graph.microsoft.com/beta/places/$($RequestBody.id)"
            AsApp = $false
            Type = 'PATCH'
            ContentType = 'application/json'
            Body = $Body | ConvertTo-Json -Compress
        }
        $GraphRequest = New-GraphPostRequest @params

        $StatusCode = [HttpStatusCode]::OK
        $result = "Successfully updated room $($RequestBody.displayName)"
        Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APIName -tenant $RequestBody.tenantid -message $result -Sev 'Info'
    } catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        $StatusCode = [HttpStatusCode]::Forbidden
        $GraphRequest = $ErrorMessage
        $result = "Failed to update room. $ErrorMessage"
        Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APIName -tenant $RequestBody.tenantid -message $result -Sev 'Error'
    }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @{
                'Results'       = $result
                'GraphRequest'  = $GraphRequest
                'Request'       = $params
            }
        })
}
