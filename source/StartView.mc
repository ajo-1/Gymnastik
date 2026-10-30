import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Startbildschirm im Stil der Garmin-Aktivitaeten (wie "Yoga"):
// Uhrzeit oben, Symbol und Name, gruener Start-Pfeil an der oberen Taste,
// unten der Eintrag "Einstellungen".
class StartView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var m = getModel();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, 0x050B24);
        dc.clear();

        // Uhrzeit oben
        dc.setColor(0x5599FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.09, h), Graphics.FONT_XTINY, Fmt.timeOfDay(), c);

        // Symbol: sitzende Figur
        var cx = w / 2;
        var top = Fmt.px(0.20, h);
        var r = Fmt.px(0.045, w);
        dc.setColor(0x3366FF, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, top + r, r);
        dc.fillPolygon([
            [cx - r, top + 2 * r + 3],
            [cx + r, top + 2 * r + 3],
            [cx + 3 * r, top + 5 * r],
            [cx - 3 * r, top + 5 * r]
        ]);

        // Name
        dc.setColor(0x5599FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.50, h), Graphics.FONT_MEDIUM, "Gymnastik", c);

        // Live-Puls schon vor dem Start (Sensor-Check)
        dc.setColor(0xFF4444, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.63, h), Graphics.FONT_SMALL,
            Fmt.num(m.sensorHr) + " bpm", c);

        // Start-Pfeil an der oberen Taste (rechts oben)
        var ax = Fmt.px(0.86, w);
        var ay = Fmt.px(0.26, h);
        dc.setColor(0x33DD99, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[ax - 12, ay - 15], [ax + 14, ay], [ax - 12, ay + 15]]);

        // Eintrag unten: Einstellungen (Antippen, Wischen oder Menue)
        dc.setColor(0x1E4FC0, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(Fmt.px(0.18, w), Fmt.px(0.78, h), Fmt.px(0.64, w), Fmt.px(0.13, h), 14);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.845, h), Graphics.FONT_XTINY, "Einstellungen", c);
    }
}

// InputDelegate statt BehaviorDelegate: so wird Antippen nie zu "Auswahl" (onSelect) umgedeutet.
// Starten kann nur die echte obere Taste.
class StartDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_ENTER) {
            getModel().beginWorkout();
            WatchUi.switchToView(new WorkoutView(), new WorkoutDelegate(), WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (k == WatchUi.KEY_MENU) {
            openFieldMenu();
            return true;
        }
        return false;   // Zurueck-Taste beendet die App wie gewohnt
    }

    // Antippen: nur der untere Eintrag "Einstellungen" reagiert
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var y = evt.getCoordinates()[1];
        if (y > System.getDeviceSettings().screenHeight * 7 / 10) {
            openFieldMenu();
        }
        return true;
    }

    // Nach oben wischen = Einstellungen
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        if (evt.getDirection() == WatchUi.SWIPE_UP) {
            openFieldMenu();
        }
        return true;
    }
}
