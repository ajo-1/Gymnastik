import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

// Auswaehlbare Datenfelder. Jedes der 6 Felder auf dem Display ("Slots")
// zeigt eines dieser Felder; die Auswahl wird auf der Uhr gespeichert.
//
// Neues Feld hinzufuegen:
//   1. Bezeichnung am ENDE von LABELS anhaengen
//   2. in value() einen Zweig mit der neuen Nummer ergaenzen
module Fields {

    const SLOT_COUNT = 6;

    // Obergrenze fuer den automatischen Seitenwechsel (Sekunden)
    const PAGE_SEC_MAX = 120;

    // Voreinstellung: Seite 1 = SpO2, Kalorien; Seite 2 = Ø Puls, Max Puls, Puls %Max, Stress
    // (Atmung (6) liefert die Venu 4 im Training nicht zuverlaessig, daher nicht voreingestellt)
    const DEFAULTS = [0, 1, 2, 3, 4, 7];

    const LABELS = [
        "SpO2",           // 0
        "Kalorien",       // 1
        "Ø Puls",         // 2
        "Max Puls",       // 3
        "Puls %Max",      // 4
        "Schritte",       // 5
        "Atmung",         // 6
        "Stress",         // 7
        "Body Battery",   // 8
        "Temperatur",     // 9
        "Training-Eff.",  // 10
        "Uhrzeit",        // 11
        "Akku",           // 12
        "Höhe",           // 13
        "Erholung",       // 14
        "VO2max"          // 15
    ];

    function count() as Number {
        return LABELS.size();
    }

    function label(id as Number) as String {
        return LABELS[id] as String;
    }

    // ------------------------------------------------------------------
    // Zuordnung Slot -> Feld (dauerhaft gespeichert)
    // ------------------------------------------------------------------

    function getSlot(slot as Number) as Number {
        var s = Application.Storage.getValue("slots");
        if (s instanceof Array && s.size() == SLOT_COUNT) {
            var v = s[slot];
            if (v instanceof Number && v >= 0 && v < LABELS.size()) {
                return v;
            }
        }
        return DEFAULTS[slot] as Number;
    }

    function setSlot(slot as Number, id as Number) as Void {
        var cur = [];
        for (var i = 0; i < SLOT_COUNT; i += 1) {
            cur.add(getSlot(i));
        }
        cur[slot] = id;
        Application.Storage.setValue("slots", cur);
    }

    // ------------------------------------------------------------------
    // Automatischer Seitenwechsel: Sekunden, 0 = nur manuell
    // ------------------------------------------------------------------

    function getPageSec() as Number {
        var v = Application.Storage.getValue("pageSec");
        return (v instanceof Number && v >= 0) ? v : 0;
    }

    function setPageSec(sec as Number) as Void {
        Application.Storage.setValue("pageSec", sec);
    }

    function pageSecText(sec as Number) as String {
        return (sec <= 0) ? "aus (manuell)" : ("alle " + sec.format("%d") + " s");
    }

    // ------------------------------------------------------------------
    // Werte
    // ------------------------------------------------------------------

    function numStr(v as Numeric?, fmt as String, suffix as String) as String {
        if (v == null) {
            return "--";
        }
        // Historienwerte koennen Float sein: fuer "%d" vorher in eine ganze Zahl wandeln
        if (fmt.equals("%d")) {
            return v.toNumber().format("%d") + suffix;
        }
        return v.format(fmt) + suffix;
    }

    function positive(v as Number?) as Number? {
        return (v != null && v > 0) ? v : null;
    }

    // Anzeigewert eines Feldes als fertiger Text
    function value(id as Number, m as WorkoutModel) as String {
        if (id == 0) {
            return numStr(m.spo2, "%d", "%");
        } else if (id == 1) {
            return numStr(m.kcal, "%d", "");
        } else if (id == 2) {
            return numStr(positive(m.avgHr), "%d", "");
        } else if (id == 3) {
            return numStr(positive(m.maxHr), "%d", "");
        } else if (id == 4) {
            var hr = m.currentHr;
            var z = m.zones;
            if (hr == null || z == null || z.size() < 6 || z[5] <= 0) {
                return "--";
            }
            return (hr * 100 / z[5]).format("%d") + "%";
        } else if (id == 5) {
            var info = ActivityMonitor.getInfo();
            return numStr(info.steps, "%d", "");
        } else if (id == 6) {
            return numStr(m.slow["resp"] as Numeric?, "%d", "");
        } else if (id == 7) {
            return numStr(m.slow["stress"] as Numeric?, "%d", "");
        } else if (id == 8) {
            return numStr(m.slow["bodyBattery"] as Numeric?, "%d", "");
        } else if (id == 9) {
            return numStr(m.slow["temp"] as Numeric?, "%.1f", "°");
        } else if (id == 10) {
            var ai = Activity.getActivityInfo();
            if (ai != null && (ai has :trainingEffect)) {
                return numStr(ai.trainingEffect, "%.1f", "");
            }
            return "--";
        } else if (id == 11) {
            var t = System.getClockTime();
            return t.hour.format("%02d") + ":" + t.min.format("%02d");
        } else if (id == 12) {
            return numStr(System.getSystemStats().battery, "%d", "%");
        } else if (id == 13) {
            var ai = Activity.getActivityInfo();
            return numStr((ai != null) ? ai.altitude : null, "%d", " m");
        } else if (id == 14) {
            var info = ActivityMonitor.getInfo();
            if (info has :timeToRecovery) {
                return numStr(info.timeToRecovery, "%d", " h");
            }
            return "--";
        } else if (id == 15) {
            return numStr(vo2max(), "%d", "");
        }
        return "--";
    }

    // VO2max aus dem Uhrenprofil (Laufen, sonst Radfahren); null wenn die Uhr keinen Wert hat
    function vo2max() as Number? {
        var p = UserProfile.getProfile();
        if ((p has :vo2maxRunning) && p.vo2maxRunning != null) {
            return p.vo2maxRunning;
        }
        if ((p has :vo2maxCycling) && p.vo2maxCycling != null) {
            return p.vo2maxCycling;
        }
        return null;
    }
}
