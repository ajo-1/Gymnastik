import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function openWorkoutMenu() as Void {
    var m = getModel();
    var menu = new WatchUi.Menu2({:title => "Gymnastik"});
    menu.addItem(new WatchUi.MenuItem(m.paused ? "Fortsetzen" : "Pause", null, :pause, {}));
    menu.addItem(new WatchUi.MenuItem("Speichern", "und beenden", :save, {}));
    menu.addItem(new WatchUi.MenuItem("Verwerfen", null, :discard, {}));
    menu.addItem(new WatchUi.MenuItem("Datenfelder", "ändern", :fields, {}));
    WatchUi.pushView(menu, new WorkoutMenuDelegate(), WatchUi.SLIDE_UP);
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
            m.endWorkout(true);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.switchToView(new SummaryView(), new SummaryDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :discard) {
            WatchUi.pushView(
                new WatchUi.Confirmation("Aufzeichnung verwerfen?"),
                new DiscardDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

class DiscardDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getModel().endWorkout(false);
            System.exit();
        }
        return true;
    }
}
