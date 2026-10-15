import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class StartView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var m = getModel();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.20, h), Graphics.FONT_LARGE, "Gymnastik", c);

        // Live-Puls schon vor dem Start (zum Warmwerden / Sensor-Check)
        dc.setColor(0xFF4444, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.45, h), Graphics.FONT_LARGE, Fmt.num(m.sensorHr), c);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.57, h), Graphics.FONT_XTINY, "Puls (bpm)", c);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.74, h), Graphics.FONT_SMALL, "START drücken", c);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.84, h), Graphics.FONT_XTINY, "oder Display antippen", c);
    }
}

class StartDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function startWorkout() as Boolean {
        getModel().beginWorkout();
        WatchUi.switchToView(new WorkoutView(), new WorkoutDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onSelect() as Boolean {
        return startWorkout();
    }

    // Menue-Taste / Display halten: Datenfelder vor dem Start einstellen
    function onMenu() as Boolean {
        openFieldMenu();
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return startWorkout();
    }
}
