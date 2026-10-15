import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Farben der Pulsbereiche 0 (unter Zone 1) bis 5, wie bei Garmin:
// grau, blau, gruen, orange, rot
const ZONE_COLORS = [0x777777, 0x999999, 0x33AAFF, 0x33DD66, 0xFF9922, 0xFF3333];

class WorkoutView extends WatchUi.View {

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

        var hr = m.currentHr;
        var zone = m.hrZone(hr);
        var zoneColor = ZONE_COLORS[zone] as Number;

        // Ring in Pulsbereichsfarbe (gelb waehrend Pause)
        dc.setPenWidth(8);
        dc.setColor(m.paused ? 0xFFDD00 : zoneColor, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(w / 2, h / 2, (w / 2) - 5);

        // Gesamtzeit oben
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.14, h), Graphics.FONT_MEDIUM, Fmt.clock(m.totalMs), c);
        if (m.paused) {
            dc.setColor(0xFFDD00, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, Fmt.px(0.24, h), Graphics.FONT_XTINY, "PAUSE", c);
        }

        if (m.page == 0) {
            drawMainPage(dc, m, w, h, hr, zone, zoneColor);
        } else {
            drawFieldsPage(dc, m, w, h, hr, zone, zoneColor);
        }

        // Seitenanzeige: zwei Punkte, aktuelle Seite gefuellt
        for (var i = 0; i < 2; i += 1) {
            var x = w / 2 + (i == 0 ? -9 : 9);
            var y = Fmt.px(0.955, h);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            if (i == m.page) {
                dc.fillCircle(x, y, 4);
            } else {
                dc.setPenWidth(2);
                dc.drawCircle(x, y, 4);
            }
        }
    }

    // Seite 1: grosser Puls, Pulsbereich, Felder 1 und 2
    function drawMainPage(dc as Dc, m as WorkoutModel, w as Number, h as Number,
                          hr as Number?, zone as Number, zoneColor as Number) as Void {
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(zoneColor, Graphics.COLOR_TRANSPARENT);
        if (hr != null) {
            dc.drawText(w / 2, Fmt.px(0.42, h), Graphics.FONT_NUMBER_HOT, hr.format("%d"), c);
        } else {
            dc.drawText(w / 2, Fmt.px(0.42, h), Graphics.FONT_LARGE, "--", c);
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var zoneText = (zone > 0) ? ("Zone " + zone.format("%d")) : "unter Zone 1";
        dc.drawText(w / 2, Fmt.px(0.60, h), Graphics.FONT_XTINY, "bpm  -  " + zoneText, c);

        drawZoneBar(dc, w, h, zone);

        drawField(dc, m, 0, Fmt.px(0.32, w), Fmt.px(0.79, h), Graphics.FONT_MEDIUM);
        drawField(dc, m, 1, Fmt.px(0.68, w), Fmt.px(0.79, h), Graphics.FONT_MEDIUM);
    }

    // Seite 2: Puls klein, darunter Felder 3 bis 6 im 2x2-Raster
    function drawFieldsPage(dc as Dc, m as WorkoutModel, w as Number, h as Number,
                            hr as Number?, zone as Number, zoneColor as Number) as Void {
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(zoneColor, Graphics.COLOR_TRANSPARENT);
        var hrText = (hr != null) ? hr.format("%d") : "--";
        dc.drawText(w / 2, Fmt.px(0.31, h), Graphics.FONT_LARGE, hrText + " bpm", c);

        drawField(dc, m, 2, Fmt.px(0.30, w), Fmt.px(0.50, h), Graphics.FONT_MEDIUM);
        drawField(dc, m, 3, Fmt.px(0.70, w), Fmt.px(0.50, h), Graphics.FONT_MEDIUM);
        drawField(dc, m, 4, Fmt.px(0.30, w), Fmt.px(0.74, h), Graphics.FONT_MEDIUM);
        drawField(dc, m, 5, Fmt.px(0.70, w), Fmt.px(0.74, h), Graphics.FONT_MEDIUM);
    }

    // Ein Datenfeld: Wert gross, Bezeichnung klein darunter
    function drawField(dc as Dc, m as WorkoutModel, slot as Number, x as Number, y as Number,
                       font as Graphics.FontType) as Void {
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var id = Fields.getSlot(slot);

        var color = Graphics.COLOR_WHITE;
        // veralteter SpO2-Wert wird grau, frischer blau
        if (id == 0) {
            color = (m.spo2 != null && m.spo2IsFresh()) ? 0x33CCFF : Graphics.COLOR_DK_GRAY;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, Fields.value(id, m), c);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + Fmt.px(0.085, dc.getHeight()), Graphics.FONT_XTINY, Fields.label(id), c);
    }

    function drawZoneBar(dc as Dc, w as Number, h as Number, zone as Number) as Void {
        var barW = Fmt.px(0.50, w);
        var gap = 4;
        var segW = (barW - 4 * gap) / 5;
        var x0 = (w - barW) / 2;
        var y = Fmt.px(0.67, h);
        var segH = 12;

        for (var i = 1; i <= 5; i += 1) {
            var x = x0 + (i - 1) * (segW + gap);
            var color = ZONE_COLORS[i] as Number;
            if (i == zone) {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x, y - 3, segW, segH + 6);
            } else {
                // gedimmt: jeder Farbkanal halbiert
                var dim = (((color & 0xFF0000) >> 17) << 16)
                        | (((color & 0x00FF00) >> 9) << 8)
                        | ((color & 0x0000FF) >> 1);
                dc.setColor(dim, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x, y, segW, segH);
            }
        }
    }
}

class WorkoutDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // START/STOP-Taste, BACK-Taste oder Menue = Menue (Pause / Datenfelder / Speichern / Verwerfen)
    function onSelect() as Boolean {
        openWorkoutMenu();
        return true;
    }

    function onMenu() as Boolean {
        openWorkoutMenu();
        return true;
    }

    function onBack() as Boolean {
        openWorkoutMenu();
        return true;
    }

    // Display antippen, nach oben/unten wischen oder Auf/Ab-Taste = andere Seite
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        getModel().togglePage();
        return true;
    }

    function onNextPage() as Boolean {
        getModel().togglePage();
        return true;
    }

    function onPreviousPage() as Boolean {
        getModel().togglePage();
        return true;
    }
}
