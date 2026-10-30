import Toybox.Lang;
import Toybox.System;

module Fmt {

    // Aktuelle Uhrzeit "hh:mm" (24 Stunden)
    function timeOfDay() as String {
        var t = System.getClockTime();
        return t.hour.format("%02d") + ":" + t.min.format("%02d");
    }

    // Millisekunden -> "mm:ss" bzw. "h:mm:ss"
    function clock(ms as Number) as String {
        var s = ms / 1000;
        var hh = s / 3600;
        var mm = (s % 3600) / 60;
        var ss = s % 60;
        if (hh > 0) {
            return hh.format("%d") + ":" + mm.format("%02d") + ":" + ss.format("%02d");
        }
        return mm.format("%02d") + ":" + ss.format("%02d");
    }

    function num(v as Number?) as String {
        if (v == null) {
            return "--";
        }
        return v.format("%d");
    }

    // Bruchteil einer Abmessung -> ganze Pixel
    function px(frac as Float, size as Number) as Number {
        return (size * frac).toNumber();
    }
}
