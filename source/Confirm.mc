import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Bestaetigung: obere Taste (gruenes Dreieck) = Ja, untere Taste (roter Kreis) = Nein.
// Antippen tut nichts. Jede Tasteneingabe vibriert kurz.
class ConfirmView extends WatchUi.View {

    var text as String;
    var yesColor as Number;

    function initialize(t as String, color as Number) {
        View.initialize();
        text = t;
        yesColor = color;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_MEDIUM, text, c);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(Fmt.px(0.79, w), Fmt.px(0.26, h), Graphics.FONT_XTINY, "Ja", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(Fmt.px(0.79, w), Fmt.px(0.74, h), Graphics.FONT_XTINY, "Nein", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Tasten-Symbole am Gehaeuse: oben gruenes Dreieck = Ja, unten roter Kreis = Nein
        drawKeyHints(dc, true, true);
    }
}

// Tasten-Symbole am Gehaeuserand: oben gruenes Dreieck (obere Taste),
// unten roter Kreis (untere Taste)
function drawKeyHints(dc as Dc, upper as Boolean, lower as Boolean) as Void {
    var bx = Fmt.px(0.86, dc.getWidth());
    if (upper) {
        var y1 = Fmt.px(0.26, dc.getHeight());
        dc.setColor(0x33DD99, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[bx - 12, y1 - 15], [bx + 14, y1], [bx - 12, y1 + 15]]);
    }
    if (lower) {
        dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(bx, Fmt.px(0.74, dc.getHeight()), 12);
    }
}

function buzz() as Void {
    if ((Toybox has :Attention) && (Attention has :vibrate)) {
        try {
            Attention.vibrate([new Attention.VibeProfile(60, 150)]);
        } catch (ex) {
            // Vibration nicht verfuegbar
        }
    }
}

class ConfirmDelegate extends WatchUi.InputDelegate {

    var action as Symbol;

    // action = :save oder :discard, wird bei "Ja" ausgefuehrt; "Nein" geht eine Ebene zurueck.
    function initialize(a as Symbol) {
        InputDelegate.initialize();
        action = a;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_ENTER) {
            buzz();
            if (action == :save) {
                doSave();
            } else {
                doDiscard();
            }
            return true;
        } else if (k == WatchUi.KEY_ESC) {
            buzz();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }
}
