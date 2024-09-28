function Get-ManagementGUID {
    [CmdletBinding()]
    param (
        [string]$taskRoot = "\Microsoft\Windows\EnterpriseMgmt"
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-ManagementGUID function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize variables and objects
        try {
            Write-EnhancedLog -Message "Connecting to the Task Scheduler service." -Level "INFO"
            $taskScheduler = New-Object -ComObject Schedule.Service
            $taskScheduler.Connect()

            # Initialize a list to store collected GUIDs
            $EnrollmentGUIDs = [System.Collections.Generic.List[object]]::new()

            # Regular expression to validate GUID format
            $guidRegex = '^[{(]?[0-9A-Fa-f]{8}[-]?(?:[0-9A-Fa-f]{4}[-]?){3}[0-9A-Fa-f]{12}[)}]?$'
        }
        catch {
            Write-EnhancedLog -Message "Failed to connect to the Task Scheduler service. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            return
        }
    }

    Process {
        Write-EnhancedLog -Message "Checking if the task root exists: $taskRoot" -Level "INFO"
        try {
            $rootFolder = $taskScheduler.GetFolder($taskRoot)
            if ($null -eq $rootFolder) {
                Write-EnhancedLog -Message "Task root '$taskRoot' does not exist." -Level "WARNING"
                return
            }

            Write-EnhancedLog -Message "Task root exists. Retrieving subfolders from the task root: $taskRoot" -Level "INFO"
            $subfolders = $rootFolder.GetFolders(0)
        }
        catch {
            if ($_.Exception.HResult -eq -2147024894) { # HRESULT for "The system cannot find the file specified"
                Write-EnhancedLog -Message "The task root '$taskRoot' does not exist or cannot be found." -Level "WARNING"
            } else {
                Write-EnhancedLog -Message "Failed to retrieve subfolders from '$taskRoot'. Error: $($_.Exception.Message)" -Level "ERROR"
                Handle-Error -ErrorRecord $_
            }
            return
        }

        foreach ($folder in $subfolders) {
            if ($folder.Name -match $guidRegex) {
                Write-EnhancedLog -Message "Valid GUID found: $($folder.Name)" -Level "INFO"
                try {
                    $EnrollmentGUIDs.Add($folder.Name)
                }
                catch {
                    Write-EnhancedLog -Message "Failed to add GUID: $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                }
            }
            else {
                Write-EnhancedLog -Message "Skipping non-GUID folder: $($folder.Name)" -Level "INFO"
            }
        }
    }

    End {
        if ($EnrollmentGUIDs.Count -gt 0) {
            Write-EnhancedLog -Message "Successfully collected $($EnrollmentGUIDs.Count) GUID(s)." -Level "INFO"
            return $EnrollmentGUIDs
        }
        else {
            Write-EnhancedLog -Message "No GUIDs found in the task root '$taskRoot'." -Level "WARNING"
        }

        Write-EnhancedLog -Message "Completed Get-ManagementGUID function" -Level "Notice"
    }
}
