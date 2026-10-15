import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Menue "Datenfelder": die 6 Felder und darunter der automatische Seitenwechsel.
function openFieldMenu() as Void {
    var menu = new WatchUi.Menu2({:title => "Datenfelder"});
    for (var i = 0; i < Fields.SLOT_COUNT; i += 1) {
        menu.addItem(slotItem(i));
    }
    menu.addItem(intervalItem());
    WatchUi.pushView(menu, new FieldSlotDelegate(menu), WatchUi.SLIDE_LEFT);
}

function slotItem(slot as Number) as WatchUi.MenuItem {
    var where = (slot < 2) ? "Seite 1" : "Seite 2";
    return new WatchUi.MenuItem(
        "Feld " + (slot + 1).format("%d") + " (" + where + ")",
        Fields.label(Fields.getSlot(slot)),
        slot,
        {}
    );
}

// Eintrag unter Feld 6: Sekunden fuer den automatischen Seitenwechsel (0 = manuell)
function intervalItem() as WatchUi.MenuItem {
    return new WatchUi.MenuItem(
        "Seitenwechsel",
        Fields.pageSecText(getModel().pageSec),
        :interval,
        {}
    );
}

class FieldSlotDelegate extends WatchUi.Menu2InputDelegate {

    var menu as WatchUi.Menu2;

    function initialize(m as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        menu = m;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id instanceof Number) {
            var slot = id as Number;
            var pick = new WatchUi.Menu2({:title => "Feld " + (slot + 1).format("%d")});
            for (var f = 0; f < Fields.count(); f += 1) {
                pick.addItem(new WatchUi.MenuItem(Fields.label(f), null, f, {}));
            }
            WatchUi.pushView(pick, new FieldPickDelegate(menu, slot), WatchUi.SLIDE_LEFT);
        } else {
            // Seitenwechsel: Sekunden mit dem Picker einstellen
            var current = getModel().pageSec;
            if (current > Fields.PAGE_SEC_MAX) {
                current = Fields.PAGE_SEC_MAX;
            }
            var picker = new WatchUi.Picker({
                :title => new WatchUi.Text({
                    :text => "Sekunden (0 = manuell)",
                    :color => Graphics.COLOR_WHITE,
                    :font => Graphics.FONT_XTINY,
                    :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                    :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
                }),
                :pattern => [new SecondsFactory()],
                :defaults => [current]
            });
            WatchUi.pushView(picker, new IntervalDelegate(menu), WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class FieldPickDelegate extends WatchUi.Menu2InputDelegate {

    var parent as WatchUi.Menu2;
    var slot as Number;

    function initialize(p as WatchUi.Menu2, s as Number) {
        Menu2InputDelegate.initialize();
        parent = p;
        slot = s;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        Fields.setSlot(slot, item.getId() as Number);
        parent.updateItem(slotItem(slot), slot);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// Auswahlrad 0 bis 120 Sekunden
class SecondsFactory extends WatchUi.PickerFactory {

    function initialize() {
        PickerFactory.initialize();
    }

    function getSize() as Number {
        return Fields.PAGE_SEC_MAX + 1;
    }

    function getValue(index as Number) as Object? {
        return index;
    }

    function getDrawable(index as Number, isSelected as Boolean) as WatchUi.Drawable? {
        var text = (index == 0) ? "0 = manuell" : (index.format("%d") + " s");
        return new WatchUi.Text({
            :text => text,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}

class IntervalDelegate extends WatchUi.PickerDelegate {

    var parent as WatchUi.Menu2;

    function initialize(p as WatchUi.Menu2) {
        PickerDelegate.initialize();
        parent = p;
    }

    function onAccept(values as Array) as Boolean {
        getModel().setPageSec(values[0] as Number);
        parent.updateItem(intervalItem(), Fields.SLOT_COUNT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
