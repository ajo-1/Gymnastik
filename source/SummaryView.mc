import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {

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

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.14, h), Graphics.FONT_MEDIUM, "Gespeichert", c);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.30, h), Graphics.FONT_LARGE, Fmt.clock(m.sumTimeMs), c);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.45, h), Graphics.FONT_SMALL,
            "Ø Puls " + m.sumAvgHr.format("%d") + "  Max " + m.sumMaxHr.format("%d"), c);
        dc.drawText(w / 2, Fmt.px(0.56, h), Graphics.FONT_SMALL,
            m.sumKcal.format("%d") + " kcal", c);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, Fmt.px(0.84, h), Graphics.FONT_XTINY, "Taste drücken = Beenden", c);
    }
}

class SummaryDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        System.exit();
        return true;
    }

    function onBack() as Boolean {
        System.exit();
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        System.exit();
        return true;
    }
}
