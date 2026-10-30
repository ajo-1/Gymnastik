import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Obere Taste im Training: Pause / Speichern / Verwerfen / Datenfelder.
// Untere Taste (Zurueck) schliesst das Menue wieder.
function openWorkoutMenu() as Void {
    var m = getModel();
    var menu = new WatchUi.Menu2({:title => "Gymnastik"});
    menu.addItem(new WatchUi.MenuItem(m.paused ? "Fortsetzen" : "Pause", null, :pause, {}));
    menu.addItem(new WatchUi.MenuItem("Speichern", "und beenden", :save, {}));
    menu.addItem(new WatchUi.MenuItem("Verwerfen", null, :discard, {}));
    menu.addItem(new WatchUi.MenuItem("Datenfelder", "ändern", :fields, {}));
    WatchUi.pushView(menu, new WorkoutMenuDelegate(), WatchUi.SLIDE_UP);
}

// "Ja" bei Speichern: Aufzeichnung sichern, Zusammenfassung zeigen
function doSave() as Void {
    getModel().endWorkout(true);
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);   // Bestaetigung
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);   // Menue
    WatchUi.switchToView(new SummaryView(), new SummaryDelegate(), WatchUi.SLIDE_IMMEDIATE);
}

// "Ja" bei Verwerfen: Aufzeichnung loeschen, App beenden
function doDiscard() as Void {
    getModel().endWorkout(false);
    System.exit();
}

class WorkoutMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var m = getModel();

        if (id == :pause) {
            m.togglePause();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :fields) {
            openFieldMenu();
        } else if (id == :save) {
            WatchUi.pushView(
                new ConfirmView("Speichern?", 0x33DD66),
                new ConfirmDelegate(:save),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id == :discard) {
            WatchUi.pushView(
                new ConfirmView("Verwerfen?", 0xFF3333),
                new ConfirmDelegate(:discard),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}
