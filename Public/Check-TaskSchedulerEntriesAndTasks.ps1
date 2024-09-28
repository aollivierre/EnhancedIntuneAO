function Check-TaskSchedulerEntriesAndTasks {
    <#
    .SYNOPSIS
    Checks for scheduled tasks and their folders related to a specific Enrollment GUID.

    .DESCRIPTION
    The Check-TaskSchedulerEntriesAndTasks function lists all scheduled tasks under the Enterprise Management path that match the specified Enrollment GUID. It also checks for the existence of corresponding task folders.

    .PARAMETER EnrollmentGUID
    The GUID of the enrollment entries related to the tasks to be checked.

    .EXAMPLE
    Check-TaskSchedulerEntriesAndTasks -EnrollmentGUID "YourGUIDHere"
    Lists all scheduled tasks and checks folders under Enterprise Management that match the given GUID.

    .NOTES
    Uses Write-EnhancedLog for logging information.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the Enrollment GUID.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnrollmentGUID
    )

    Begin {
        Write-EnhancedLog -Message "Starting Check-TaskSchedulerEntriesAndTasks for GUID: $EnrollmentGUID" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize Task Scheduler connection
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
    }

    Process {
        Write-EnhancedLog -Message "Searching for scheduled tasks matching GUID: $EnrollmentGUID" -Level "INFO"

        # Search for tasks under the Task Scheduler
        try {
            $tasksFound = Get-ScheduledTask | Where-Object { $_.TaskPath -match $EnrollmentGUID }
            if ($tasksFound.Count -gt 0) {
                foreach ($task in $tasksFound) {
                    Write-EnhancedLog -Message "Found task: $($task.TaskName)" -Level "INFO"
                }
            }
            else {
                Write-EnhancedLog -Message "No tasks found for GUID: $EnrollmentGUID" -Level "WARNING"
            }
        }
        catch {
            Write-EnhancedLog -Message "Error while searching for tasks: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            return
        }

        # Check for the existence of task folders
        $taskFolders = @(
            "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmt\$EnrollmentGUID",
            "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmtNoncritical\$EnrollmentGUID"
        )

        foreach ($taskFolder in $taskFolders) {
            if (Test-Path $taskFolder) {
                Write-EnhancedLog -Message "Found task folder at path: $taskFolder" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "No task folder found at path: $taskFolder" -Level "WARNING"
            }
        }
    }

    End {
        Write-EnhancedLog -Message "Task Scheduler entry and folder check for GUID: $EnrollmentGUID completed." -Level "Notice"
    }
}
