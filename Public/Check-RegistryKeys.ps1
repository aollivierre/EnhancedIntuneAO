function Check-RegistryKeys {
    <#
    .SYNOPSIS
    Checks for specific registry keys under given GUIDs and outputs their subkeys and values.

    .DESCRIPTION
    The Check-RegistryKeys function searches the registry under "HKLM:\SOFTWARE\Microsoft\Enrollments" for specified GUIDs, checks for specific subkeys (DeviceEnroller, DMClient, Poll, Push), and lists all items within these subkeys as a table of key name and value pairs.

    .PARAMETER EnrollmentGUIDs
    The GUIDs under which to search for specific registry subkeys.

    .EXAMPLE
    Check-RegistryKeys -EnrollmentGUIDs @("GUID1", "GUID2")
    Searches for and lists details of specific registry subkeys under the specified GUIDs.

    .NOTES
    Ensure the 'Write-EnhancedLog' function is defined in your environment for logging.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the Enrollment GUIDs to search for.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$EnrollmentGUIDs
    )

    Begin {
        Write-EnhancedLog -Message "Starting registry key check for specified GUIDs." -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Base registry path
        $BaseKey = "HKLM:\SOFTWARE\Microsoft\Enrollments"
        Write-EnhancedLog -Message "Checking registry base path: $BaseKey" -Level "INFO"

        # Initialize an array to store the properties of found subkeys
        $allProperties = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    Process {
        foreach ($GUID in $EnrollmentGUIDs) {
            $GUIDPath = Join-Path -Path $BaseKey -ChildPath $GUID
            Write-EnhancedLog -Message "Processing GUID: $GUID" -Level "INFO"

            if (Test-Path -Path $GUIDPath) {
                Write-EnhancedLog -Message "Found registry path: $GUIDPath" -Level "INFO"
                
                try {
                    $SubKeys = Get-ChildItem -Path $GUIDPath -ErrorAction Stop

                    foreach ($SubKey in $SubKeys) {
                        if ($SubKey.Name -match "DeviceEnroller|DMClient|Poll|Push") {
                            $SubKeyProperties = Get-ItemProperty -Path $SubKey.PSPath

                            foreach ($Property in $SubKeyProperties.PSObject.Properties) {
                                # Add each property to the list as a custom object
                                $allProperties.Add([PSCustomObject]@{
                                    SubKeyName    = $SubKey.PSChildName
                                    PropertyName  = $Property.Name
                                    PropertyValue = $Property.Value
                                })
                            }
                        }
                        else {
                            Write-EnhancedLog -Message "No relevant subkeys (DeviceEnroller, DMClient, Poll, Push) found under $GUIDPath." -Level "WARNING"
                        }
                    }
                }
                catch {
                    Write-EnhancedLog -Message "Error retrieving subkeys for GUID $GUID. Error: $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                }
            }
            else {
                Write-EnhancedLog -Message "GUID $GUID not found under $BaseKey." -Level "WARNING"
            }
        }
    }

    End {
        # Output all collected properties in a table
        if ($allProperties.Count -gt 0) {
            Write-EnhancedLog -Message "Displaying properties found in relevant subkeys." -Level "INFO"
            $allProperties | Format-Table -AutoSize
        }
        else {
            Write-EnhancedLog -Message "No relevant properties found under the specified GUIDs." -Level "WARNING"
        }

        Write-EnhancedLog -Message "Completed registry key check for specified GUIDs." -Level "Notice"
    }
}
