import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Eigene Auswahl fuer "Datenfelder" mit Tasten-Symbolen:
//   blaues Feld antippen           = Werteliste oeffnen
//   obere Taste (gruenes Dreieck)  = OK: speichern und zurueck
//   untere Taste (roter Kreis)     = verwerfen und zurueck
//   nach oben/unten wischen oder oben/unten antippen = Eintrag markieren

// Moegliche Sekunden fuer den automatischen Seitenwechsel (0 = manuell)
const SEC_STEPS = [0, 3, 5, 8, 10, 15, 20, 30, 45, 60, 90, 120];

function openFieldMenu() as Void {
    var v = new ListView(:menu, 0, 0, null);
    WatchUi.pushView(v, new ListDelegate(v), WatchUi.SLIDE_LEFT);
}

class ListView extends WatchUi.View {

    var kind as Symbol;
    var slot as Number;
    var idx as Number;

    // nur in der Uebersicht (:menu): noch nicht gespeicherte Auswahl
    // (6 Felder + Sekunden fuer den Seitenwechsel). Untermenues melden an "parent".
    var pend as Array<Number> = [];
    var parent as ListView?;

    function initialize(k as Symbol, s as Number, start as Number, p as ListView?) {
        View.initialize();
        kind = k;
        slot = s;
        idx = start;
        parent = p;
        if (k == :menu) {
            for (var i = 0; i < Fields.SLOT_COUNT; i += 1) {
                pend.add(Fields.getSlot(i));
            }
            pend.add(getModel().pageSec);
        }
    }

    function size() as Number {
        if (kind == :menu) {
            return Fields.SLOT_COUNT + 1;
        } else if (kind == :field) {
            return Fields.count();
        }
        return SEC_STEPS.size();
    }

    function wrap(i as Number) as Number {
        var n = size();
        return ((i % n) + n) % n;
    }

    function title() as String {
        if (kind == :menu) {
            return "Datenfelder";
        } else if (kind == :field) {
            return "Feld " + (slot + 1).format("%d");
        }
        return "Seitenwechsel (s)";
    }

    function rowText(i as Number) as String {
        if (kind == :menu) {
            if (i < Fields.SLOT_COUNT) {
                return "Feld " + (i + 1).format("%d") + " (Seite " + ((i < 2) ? "1" : "2") + ")";
            }
            return "Seitenwechsel";
        } else if (kind == :field) {
            return Fields.label(i);
        }
        var sec = SEC_STEPS[i] as Number;
        return (sec == 0) ? "0 = manuell" : (sec.format("%d") + " s");
    }

    function rowSub(i as Number) as String? {
        if (kind == :menu) {
            if (i < Fields.SLOT_COUNT) {
                return Fields.label(pend[i]);
            }
            return Fields.pageSecText(pend[Fields.SLOT_COUNT]);
        }
        return null;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.10, h), Graphics.FONT_XTINY, title(), c);

        // Eintrag davor und danach (gedimmt)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.27, h), Graphics.FONT_XTINY, rowText(wrap(idx - 1)), c);
        dc.drawText(w / 2, Fmt.px(0.78, h), Graphics.FONT_XTINY, rowText(wrap(idx + 1)), c);

        // aktueller Eintrag, hervorgehoben
        dc.setColor(0x1E4FC0, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(Fmt.px(0.06, w), Fmt.px(0.38, h), Fmt.px(0.88, w), Fmt.px(0.26, h), 16);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var sub = rowSub(idx);
        if (sub != null) {
            dc.drawText(w / 2, Fmt.px(0.46, h), Graphics.FONT_SMALL, rowText(idx), c);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, Fmt.px(0.565, h), Graphics.FONT_XTINY, sub, c);
        } else {
            dc.drawText(w / 2, Fmt.px(0.51, h), Graphics.FONT_SMALL, rowText(idx), c);
        }

        drawKeyHints(dc, true, true);
    }
}

// InputDelegate statt BehaviorDelegate: Antippen wird nie zu "Auswahl" umgedeutet.
class ListDelegate extends WatchUi.InputDelegate {

    var view as ListView;

    function initialize(v as ListView) {
        InputDelegate.initialize();
        view = v;
    }

    function move(d as Number) as Void {
        view.idx = view.wrap(view.idx + d);
        WatchUi.requestUpdate();
    }

    // Oeffnet die Werteliste des markierten Eintrags (Antippen des blauen Felds)
    function openEntry() as Void {
        if (view.idx < Fields.SLOT_COUNT) {
            var v = new ListView(:field, view.idx, view.pend[view.idx], view);
            WatchUi.pushView(v, new ListDelegate(v), WatchUi.SLIDE_LEFT);
        } else {
            var cur = view.pend[Fields.SLOT_COUNT];
            var start = 0;
            for (var i = 0; i < SEC_STEPS.size(); i += 1) {
                if ((SEC_STEPS[i] as Number) <= cur) {
                    start = i;
                }
            }
            var v = new ListView(:interval, 0, start, view);
            WatchUi.pushView(v, new ListDelegate(v), WatchUi.SLIDE_LEFT);
        }
    }

    // Gruene Taste = OK
    //   Uebersicht: alles speichern und zurueck
    //   Werteliste: Wert uebernehmen und zurueck zur Uebersicht
    function choose() as Void {
        var k = view.kind;
        if (k == :menu) {
            for (var i = 0; i < Fields.SLOT_COUNT; i += 1) {
                Fields.setSlot(i, view.pend[i]);
            }
            getModel().setPageSec(view.pend[Fields.SLOT_COUNT]);
        } else if (k == :field) {
            var p1 = view.parent as ListView;
            p1.pend[view.slot] = view.idx;
        } else {
            var p2 = view.parent as ListView;
            p2.pend[Fields.SLOT_COUNT] = SEC_STEPS[view.idx] as Number;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_ENTER) {
            choose();
            return true;
        } else if (k == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var d = evt.getDirection();
        if (d == WatchUi.SWIPE_UP) {
            move(1);
        } else if (d == WatchUi.SWIPE_DOWN) {
            move(-1);
        } else if (d == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var y = evt.getCoordinates()[1];
        var h = System.getDeviceSettings().screenHeight;
        if (y < h * 38 / 100) {
            move(-1);
        } else if (y > h * 64 / 100) {
            move(1);
        } else if (view.kind == :menu) {
            openEntry();
        }
        // In den Wertelisten waehlt Antippen nur aus (oben/unten); gespeichert wird erst mit
        // der gruenen oberen Taste, abgebrochen mit der roten unteren Taste.
        return true;
    }
}
