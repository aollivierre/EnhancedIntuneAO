function Remove-TaskSchedulerEntriesAndTasks {
    <#
    .SYNOPSIS
    Removes scheduled tasks and their folders related to a specific Enrollment GUID.

    .DESCRIPTION
    The Remove-TaskSchedulerEntriesAndTasks function finds and removes all scheduled tasks under the Enterprise Management path that match the specified Enrollment GUID. It also removes the corresponding task folders if they exist.

    .PARAMETER EnrollmentGUID
    The GUID of the enrollment entries related to the tasks to be removed.

    .EXAMPLE
    Remove-TaskSchedulerEntriesAndTasks -EnrollmentGUID "YourGUIDHere"
    Removes all scheduled tasks and folders under Enterprise Management that match the given GUID.

    .NOTES
    Uses Write-EnhancedLog for logging steps and outcomes.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the Enrollment GUID for the tasks and folders to be removed.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnrollmentGUID
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-TaskSchedulerEntriesAndTasks for GUID: $EnrollmentGUID" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        try {
            Write-EnhancedLog -Message "Connecting to Task Scheduler service." -Level "INFO"
            $taskScheduler = New-Object -ComObject Schedule.Service
            $taskScheduler.Connect()
        }
        catch {
            Write-EnhancedLog -Message "Failed to connect to Task Scheduler service. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            return
        }

        # Initialize an array to store unregistered tasks information
        $unregisteredTasks = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    Process {
        try {
            Write-EnhancedLog -Message "Removing scheduled tasks for GUID: $EnrollmentGUID" -Level "INFO"

            # Search for tasks matching the Enrollment GUID and unregister them
            $tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -match $EnrollmentGUID }
            foreach ($task in $tasks) {
                try {
                    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                    Write-EnhancedLog -Message "Unregistered task: $($task.TaskName)" -Level "INFO"

                    # Add unregistered task details to the list
                    $unregisteredTasks.Add([PSCustomObject]@{
                        TaskName = $task.TaskName
                        TaskPath = $task.TaskPath
                    })
                }
                catch {
                    Write-EnhancedLog -Message "Failed to unregister task: $($task.TaskName). Error: $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                }
            }

            # Paths to task folders for removal
            $taskFolders = @(
                "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmt\$EnrollmentGUID",
                "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmtNoncritical\$EnrollmentGUID"
            )

            # Remove the task folders
            foreach ($folderPath in $taskFolders) {
                if (Test-Path $folderPath) {
                    try {
                        Remove-Item -Path $folderPath -Force -ErrorAction Stop
                        Write-EnhancedLog -Message "Removed task folder at path: $folderPath" -Level "INFO"
                    }
                    catch {
                        Write-EnhancedLog -Message "Failed to remove task folder at path: $folderPath. Error: $($_.Exception.Message)" -Level "ERROR"
                        Handle-Error -ErrorRecord $_
                    }
                }
                else {
                    Write-EnhancedLog -Message "Task folder not found at path: $folderPath" -Level "WARNING"
                }
            }

            # Remove parent folder from Task Scheduler
            try {
                $rootFolder = $taskScheduler.GetFolder("\")
                $rootFolder.DeleteFolder("\Microsoft\Windows\EnterpriseMgmt\$EnrollmentGUID", 0)
                Write-EnhancedLog -Message "Parent task folder for GUID - $EnrollmentGUID removed successfully" -Level "INFO"
            }
            catch {
                Write-EnhancedLog -Message "Failed to remove parent task folder for GUID - $EnrollmentGUID. Error: $($_.Exception.Message)" -Level "ERROR"
                Handle-Error -ErrorRecord $_
            }
        }
        catch {
            Write-EnhancedLog -Message "Error during task and folder cleanup: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        # Display unregistered tasks
        if ($unregisteredTasks.Count -gt 0) {
            Write-EnhancedLog -Message "Unregistered tasks for GUID: $EnrollmentGUID" -Level "INFO"
            $unregisteredTasks | Format-Table -AutoSize
        }
        else {
            Write-EnhancedLog -Message "No tasks were found or unregistered for GUID: $EnrollmentGUID" -Level "WARNING"
        }

        Write-EnhancedLog -Message "Cleanup process for GUID: $EnrollmentGUID completed." -Level "Notice"
    }
}
