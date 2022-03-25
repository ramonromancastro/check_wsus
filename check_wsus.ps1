# check_wsus Nagios plugin para servidores WSUS.
# Copyright (C) 2022  Ramón Román Castro <ramonromancastro@gmail.com>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#requires -version 2

#Version history:
#
#Version 1.0 (4 Abril 2017)
#* Versión inicial
#
#Version 1.1 (17 May 2017)
#* Pequeños cambios. Añandido ComputerTargetsNeedingUpdatesCount
#
#Version 1.2 (18 May 2017)
#* Eliminados todos los campos obligatorios.
#* ComputerTargetsNeedingUpdatesCount, ComputersNotContacted y ComputersWithUpdateErrors tratan Warning y Critical como porcentajes sobre el total
#
#Version 1.3 (23 May 2017)
#* ComputerTargetsNeedingUpdatesCount siempre devuelve WARNING si existe algún equipo que cumpla los requisitos
#* ComputersNotContacted siempre devuelve WARNING si existe algún equipo que cumpla los requisitos
#* ComputersWithUpdateErrors siempre devuelve CRITICAL si existe algún equipo que cumpla los requisitos
#
#Version 1.4 (23 Mar 2022)
#* Añadido el parámetro UpdateSources para filtrar NotApprovedUpdates
<#
.SYNOPSIS
Check WSUS Server Status

.DESCRIPTION
Check WSUS Server Status

.EXAMPLE
C:\PS> check_wsus.ps1 -ComputerName 'server' -UseSSL $False -Port 8530 -Check NotApprovedUpdates -Warning 1 -Critical 10

.INPUTS

.OUTPUTS
check-wsus.ps1 returns information in Nagios Plugin Output format
WSUS (OK|WARNING|CRITICAL|UNKNOWN): Plugin result
Perf result

.NOTES

.LINK
http://www.rrc2software.com
#>
Param(
    [Parameter(Mandatory=$False)][String]$ComputerName=$env:computername,
    [Parameter(Mandatory=$False)][Boolean]$UseSSL=$False,
    [Parameter(Mandatory=$False)][Int32]$Port=8530,
	[Parameter(Mandatory=$False)][Int32]$Warning=10,
	[Parameter(Mandatory=$False)][Int32]$Critical=20,
	[Parameter(Mandatory=$False)][Int32]$DaysBefore=30,
	[Parameter(Mandatory=$False)][String][ValidateSet("ComputersNotAssigned","ComputersNotContacted","ComputerTargetsNeedingUpdatesCount","ComputersWithUpdateErrors","NotApprovedUpdates","Info")] $Check="Info",
	[Parameter(Mandatory=$False)][String][ValidateSet('All','MicrosoftUpdate','Other')]$UpdateSources='MicrosoftUpdate'
)

$Nagios_OK=0
$Nagios_WARNING=1
$Nagios_CRITICAL=2
$Nagios_UNKNOWN=3

$ExitCode=$Nagios_UNKNOWN

Write-Verbose "Loading WSUS API interface"
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
Write-Verbose "Attempting to connect to $ComputerName"
$UpdateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($ComputerName,$UseSSL,$Port)
Write-Verbose "Retrieving server status"
$UpdateStatus = $UpdateServer.GetStatus()

$ComputerTargetCount = $UpdateStatus.ComputerTargetCount
$UpdateCount = $UpdateStatus.UpdateCount

Switch -Case ($Check) {
	"ComputerTargetsNeedingUpdatesCount" {
			#$Warning = [math]::floor(($ComputerTargetCount * $Warning) / 100)
			#$Critical = [math]::floor(($ComputerTargetCount * $Critical) / 100)
			$Value = $UpdateStatus.ComputerTargetsNeedingUpdatesCount
			$Output = "$Value computer(s) with updates that are no yet installed"
			$Status = "OK"
			$ExitCode = $Nagios_OK
			if ($Value) {
				$Status = "WARNING"
				$ExitCode = $Nagios_WARNING
			}
			# if ($Value -gt $Warning) {
				# $Status = "WARNING"
				# $ExitCode = $Nagios_WARNING
				# if ($Value -gt $Critical) {
					# $Status = "CRITICAL"
					# $ExitCode = $Nagios_CRITICAL
				# }
			# }
			# $PerfData = '|' + "'ComputerTargetsNeedingUpdatesCount'=$Value;$Warning;$Critical;0;$ComputerTargetCount"
			$PerfData = '|' + "'ComputerTargetsNeedingUpdatesCount'=$Value;1;1;0;$ComputerTargetCount"
	}
	"ComputersWithUpdateErrors" {
			# $Warning = [math]::floor(($ComputerTargetCount * $Warning) / 100)
			# $Critical = [math]::floor(($ComputerTargetCount * $Critical) / 100)
			$Value = $UpdateStatus.ComputerTargetsWithUpdateErrorsCount
			$Output = "$Value computer(s) with errors"
			$Status = "OK"
			$ExitCode = $Nagios_OK
			if ($Value) {
				$Status = "CRITICAL"
				$ExitCode = $Nagios_CRITICAL
			}
			# if ($Value -gt $Warning) {
				# $Status = "WARNING"
				# $ExitCode = $Nagios_WARNING
				# if ($Value -gt $Critical) {
					# $Status = "CRITICAL"
					# $ExitCode = $Nagios_CRITICAL
				# }
			# }
			# $PerfData = '|' + "'ComputerTargetsWithUpdateErrors'=$Value;$Warning;$Critical;0;$ComputerTargetCount"
			$PerfData = '|' + "'ComputerTargetsWithUpdateErrors'=$Value;1;1;0;$ComputerTargetCount"
	}
	"NotApprovedUpdates" {
		
			$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
			$UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved
			$UpdateScope.UpdateSources = $UpdateSources
			$UpdateCollection=$UpdateServer.GetUpdates($UpdateScope)
		
			$Value = $UpdateCollection.Count
			$Output = "$Value update(s) not approved"
			$Status = "OK"
			$ExitCode = $Nagios_OK
			if ($Value -gt $Warning) {
				$Status = "WARNING"
				$ExitCode = $Nagios_WARNING
				if ($Value -gt $Critical) {
					$Status = "CRITICAL"
					$ExitCode = $Nagios_CRITICAL
				}
			}
			$PerfData = '|' + "'NotApprovedUpdates'=$Value;$Warning;$Critical;0;$UpdateCount"
	}
	"ComputersNotAssigned" {
			$TargetScope = new-object Microsoft.UpdateServices.Administration.ComputerTargetScope
			$Value = $UpdateServer.GetComputerTargetGroup([Microsoft.UpdateServices.Administration.ComputerTargetGroupId]::UnassignedComputers).GetComputerTargets().Count
			$Output = "$Value computer(s) not assigned to WSUS"
			$Status = "OK"
			$ExitCode = $Nagios_OK
			if ($Value -gt $Warning) {
				$Status = "WARNING"
				$ExitCode = $Nagios_WARNING
				if ($Value -gt $Critical) {
					$Status = "CRITICAL"
					$ExitCode = $Nagios_CRITICAL
				}
			}
			$PerfData = '|' + "'ComputersNotAssigned'=$Value;$Warning;$Critical;0;$ComputerTargetCount"
	}
	"ComputersNotContacted" {
			# $Warning = [math]::floor(($ComputerTargetCount * $Warning) / 100)
			# $Critical = [math]::floor(($ComputerTargetCount * $Critical) / 100)
			$TimeSpan = new-object TimeSpan($DaysBefore, 0, 0, 0)
			$Value = $UpdateServer.GetComputersNotContactedSinceCount([DateTime]::UtcNow.Subtract($TimeSpan))
			$Output = "$Value computer(s) not contacted within $DaysBefore days"
			$Status = "OK"
			$ExitCode = $Nagios_OK
			if ($Value) {
				$Status = "WARNING"
				$ExitCode = $Nagios_WARNING
			}
			# if ($Value -gt $Warning) {
				# $Status = "WARNING"
				# $ExitCode = $Nagios_WARNING
				# if ($Value -gt $Critical) {
					# $Status = "CRITICAL"
					# $ExitCode = $Nagios_CRITICAL
				# }
			# }
			# $PerfData = '|' + "'ComputersNotContacted'=$Value;$Warning;$Critical;0;$ComputerTargetCount"
			$PerfData = '|' + "'ComputersNotContacted'=$Value;1;1;0;$ComputerTargetCount"
	}
	"Info" {
			$Output = "Version $($UpdateServer.Version)"
			$Status = "OK"
			$ExitCode = $Nagios_OK
			$PerfData = ""
	}
}

write-host "WSUS",$Status,"-",$Output
$PerfData
Exit $ExitCode

trap {
	write-host "WSUS","UNKNOWN","-",$_.Exception.Message
	Exit $Nagios_UNKNOWN
}
