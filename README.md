# Gymnastik – Connect-IQ-Watch-App für die Garmin Venu 4

Zeichnet ein Gymnastik-Training als Garmin-Aktivität auf (erscheint in Garmin Connect)
und zeigt live an: Puls (in der Farbe des Pulsbereichs), SpO2, Zeit und Kalorien.

## Bedienung

Auf dem Startbildschirm START drücken (oder Display antippen): die Aufzeichnung beginnt.
Im Training zeigt die App Gesamtzeit, Puls, Pulsbereich, SpO2 und Kalorien.
Der Puls, der Ring und der Balken sind in der Farbe des aktuellen Pulsbereichs
(grau, blau, grün, orange, rot). Die Bereichsgrenzen stammen aus den Uhren-Einstellungen.

Display antippen (oder nach oben/unten wischen) wechselt zwischen Seite 1 (großer Puls, Feld 1-2)
und Seite 2 (Puls klein, Feld 3-6).

START/STOP- oder BACK-Taste öffnet das Menü: Pause, Speichern und beenden, Verwerfen, Datenfelder ändern.

### Datenfelder wählen

Im Menü *Datenfelder* ein Feld wählen und dann die Größe aus der Liste: SpO2, Kalorien, Ø Puls,
Max Puls, Puls %Max, Schritte, Atmung, Stress, Body Battery, Temperatur, Training-Effekt,
Uhrzeit, Akku, Höhe, Erholung. Die Auswahl bleibt auf der Uhr gespeichert.

Unter Feld 6 steht **Seitenwechsel**: dort stellst du in Sekunden ein (0 bis 120), wie oft die Seiten 1 und 2
automatisch wechseln. **0 = nur manuell** (Antippen/Wischen). Der Wechsel läuft nur während der laufenden
Aufzeichnung, nicht in der Pause.
Auch vor dem Start einstellbar (Menü-Taste/Display halten auf dem Startbildschirm).

Eigene Felder ergänzen: in `source/DataFields.mc` Bezeichnung an `LABELS` anhängen und in
`value()` einen Zweig mit der neuen Nummer schreiben.

**Grenze:** Auf der Uhr installierte Datenfelder anderer Entwickler (Connect-IQ-Store) kann
eine App nicht einbinden, Connect IQ erlaubt das nicht. Die Felder oben sind die Werte, die die
Uhr einer App direkt liefert.
Die Aktivität (Puls, Kalorien, SpO2-Kurve) erscheint danach in Garmin Connect.

## Bauen und auf die Uhr bringen

1. Ordner `Gymnastik` in VS Code öffnen (Monkey C-Erweiterung und SDK wie bei FhemGWidget).
2. Developer-Key wie bei den anderen Projekten verwenden (nicht ins Repository einchecken).
3. Ziel: Venu 4 (41 mm oder 45 mm), siehe `manifest.xml`.
4. Testen im Simulator: `Run > Start Debugging`. Im Simulator lassen sich Puls und SpO2 über
   *Simulation > Set Sensor Data* vorgeben.
5. Für die Uhr: `Monkey C: Build for Device` → erzeugt eine `.prg`-Datei. Uhr per USB anschließen
   und die Datei nach `GARMIN/Apps/` kopieren.

Für den Connect-IQ-Store (Entwickler-Dashboard) wird statt der `.prg` ein `.iq`-Paket
(`Monkey C: Export Project`) hochgeladen. Für den Eigengebrauch ist das nicht nötig.

## Hinweise

- **SpO2 während der Bewegung** ist bei Garmin-Uhren unzuverlässig; Bewegung stört die Messung,
  und manche Firmware-Stände liefern während Aktivitäten keine neuen Werte (bekannter Fehler
  im Garmin-Forum). Die App zeigt dann den letzten Wert der Uhr, grau markiert, wenn er älter
  als 2 Minuten ist. In den Uhren-Einstellungen muss das Pulsoximeter aktiviert sein.
- Der Code wurde ohne Compiler geschrieben und noch nicht auf einer Uhr getestet. Falls der Build
  eine Meldung ausgibt, bitte hier melden. Mögliche Stellschrauben: `resources/data/fitcontributions.xml`
  löschen (nur für die SpO2-Kurve in Garmin Connect) oder die Produkt-ID korrigieren.

## Bekannte Probleme der Venu 4

- **Neustart der Uhr im Training:** Auf der Venu 4 mit Firmware 18.30/18.32 melden Entwickler im Garmin-Forum
  zufällige Neustarts bei Connect-IQ-Apps, die den Puls über den Sensor-Listener lesen. Deshalb liest die App
  Puls und SpO2 während der Aufzeichnung nur über `Activity.getActivityInfo()`. Ein Listener läuft nur auf dem
  Startbildschirm. Ob Garmin das Problem bestätigt oder behoben hat, ist offen.
- **Display wird dunkler:** Die App ruft jede Sekunde `Attention.backlight(true)` auf. Auf AMOLED-Uhren begrenzt der
  Einbrennschutz das, die App kann den Energiesparmodus nicht dauerhaft verhindern. Im Energiesparmodus zeigt die
  App nur Puls (Zonenfarbe) und Zeit. Die Dauer stellst du in den Uhren-Einstellungen (Anzeige) ein.
