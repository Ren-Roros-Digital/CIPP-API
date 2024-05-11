using namespace System.Net

Function Invoke-AddRoom {
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

    try {
        $params = @{
            tenantid = $RequestBody.tenantid
            uri = 'https://graph.microsoft.com/beta/places/microsoft.graph.room'
            AsApp = $true
            Type = 'PATCH'
            ContentType = 'application/json'
            Body = ConvertTo-Json @{
                "@odata.type"           = 'microsoft.graph.room'
                emailAddress            = $RequestBody.emailAddress
                displayName             = $RequestBody.displayName
                geoCoordinates          = $RequestBody.geoCoordinates
                phone                   = $RequestBody.phone
                placeId                 = $RequestBody.placeId
                nickname                = $RequestBody.nickname
                building                = $RequestBody.building
                floorNumber             = $RequestBody.floorNumber
                floorLabel              = $RequestBody.floorLabel
                label                   = $RequestBody.label
                capacity                = $RequestBody.capacity
                bookingType             = $RequestBody.bookingType
                audioDeviceName         = $RequestBody.audioDeviceName
                videoDeviceName         = $RequestBody.videoDeviceName
                displayDeviceName       = $RequestBody.displayDeviceName
                isWheelChairAccessible  = [bool]$RequestBody.isWheelChairAccessible
                tags                    = [string[]]$RequestBody.tags
                address = @{
                    type                = $RequestBody.address.type
                    postOfficeBox       = $RequestBody.address.postOfficeBox
                    street              = $RequestBody.address.street
                    city                = $RequestBody.address.city
                    state               = $RequestBody.address.state
                    countryOrRegion     = $RequestBody.address.countryOrRegion
                    postalCode          = $RequestBody.address.postalCode
                }
            }
        }
        $GraphRequest = New-GraphPostRequest @params

        $StatusCode = [HttpStatusCode]::OK
        $result = "Successfully created room $($RequestBody.displayName)"
        Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APIName -tenant $RequestBody.tenantid -message $result -Sev 'Info'
    } catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        $StatusCode = [HttpStatusCode]::Forbidden
        $GraphRequest = $ErrorMessage
        $result = "Failed to create room. $ErrorMessage"
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
