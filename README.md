# Backup
 

## Beschreibung
Script zum Sichern von Dateistrukturen in Zielordner mittels Robocopy. Es werden unterschiedliche Modis bereit-
gestellt, um volle oder differentielle Sicherungen zu erstellen.
Alle Quellen und Ziele werden aus den Config-Dateien gezogen. Ausser im manuellen Modus. Hier kann das Ziel per
Parameter bestimmt werden.

## Syntax

    BACKUP [/M[[:]Modus]] [/N[[:]Backupname]] [/J[:]Job]] [/A] [/U] [/V] [Quelllaufwerk:[Quellpfad]] [Ziellaufwerk:[Zielpfad]]


/M     Modus des Backups [Std.: full]
* full  vollstaendige Spiegelung
* diff  differentielle Sicherung (alle seit der letzten vollen Sicherung veraenderten Dateien werden gespiegelt)
        
/N     Name des Backups (Nur in Kombination mit /M:full!) [Std.: entspricht dem Modus]  	

/J     Name des Jobs - wird dieses Argument gesetzt, dann wird der Job - falls vorhanden - aus der Jobkonfi guration geladen. Manuelle Pfadangaben sind dann ungueltig.

/A     Attribute werden korrigiert (versteckt und system wird entfernt)

/U     Es werden keine Sicherheitsrückfragen 

/V     ausführliche Ausgaben

## Beispiele
Bsp. fuer eine manuelle Sicherung auf eine Festplatte:

    BACKUP E:\Dateien F:
     
Bsp. fuer ein volles Backup anhand eines vorkonfigurierten Jobs: 

    BACKUP /J:monatssicherung /A /U
     
Bsp. fuer ein differentielles Backup: 

    BACKUP /M:diff /J:monatssicherung /A
