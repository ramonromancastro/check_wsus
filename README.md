# check_wsus
check_wsus - Nagios plugin para servidores WSUS

## Descripción

Este plugin extrae información sobre el estado de los equipos y las actulizaciones disponibles en una instalación de Windows Server Update Service.

## Parámetros

```
ComputerName   Nombre del servidor WSUS ($env:computername)
UseSSL         Utilizar una conexión SSL ($False)
Port           Puerto de conexión (8530)
Warning        Límite inferior de aviso (10)
Warning        Límite inferior de alerta (20)
DaysBefore     Intervalo de días. Utilizado por ComputersNotContacted (30)
Check          Tipo de comprobación. Las opciones disponibles son:
                 - ComputersNotAssigned: Equipos sin grupo asignado
                 - ComputersNotContacted: Equipos sin contactar desde hace xx días
                 - ComputerTargetsNeedingUpdatesCount: Equipos con actualizaciones sin aplicar
                 - ComputersWithUpdateErrors: Equipos con errores
                 - NotApprovedUpdates: Actualizaciones no aprobadas
UpdateSources  Tipo de actualizaciones. Utilizado por NotApprovedUpdates (MicrosoftUpdate)
               Las opciones disponibles son:
                 - All: Todas las actualizaciones
                 - MicrosoftUpdate: Actualizaciones de Microsoft Update
                 - Other: Otras actualizaciones
```
