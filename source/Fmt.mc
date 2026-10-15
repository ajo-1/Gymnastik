import Toybox.Lang;

module Fmt {

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
