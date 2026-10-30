import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.UserProfile;
import Toybox.WatchUi;

// Haelt den kompletten Zustand: Sensoren, Aufzeichnung, Live-Werte.
class WorkoutModel {

    // SpO2-Werte aelter als so viele Sekunden werden grau (veraltet) angezeigt
    const SPO2_MAX_AGE_S = 120;

    // --- Zustand ---
    var recording as Boolean = false;
    var paused as Boolean = false;

    // --- Live-Werte ---
    var sensorHr as Number? = null;
    var currentHr as Number? = null;
    var spo2 as Number? = null;
    var spo2When as Time.Moment? = null;
    var totalMs as Number = 0;
    var kcal as Number = 0;
    var avgHr as Number = 0;
    var maxHr as Number = 0;

    // true, solange die Uhr im Energiesparmodus (gedimmtes Display) ist
    var sleeping as Boolean = false;

    // Anzeigeseite im Training: 0 = Hauptseite, 1 = Datenfelder-Seite
    var page as Number = 0;

    // Automatischer Seitenwechsel in Sekunden (0 = manuell) und Sekundenzaehler dafuer
    var pageSec as Number = 0;
    var pageTick as Number = 0;

    // Selten aktualisierte Werte aus der Sensor-Historie (Stress, Body Battery, Temperatur)
    var slow as Dictionary = {};

    // --- Zusammenfassung (Schnappschuss beim Beenden) ---
    var sumTimeMs as Number = 0;
    var sumKcal as Number = 0;
    var sumAvgHr as Number = 0;
    var sumMaxHr as Number = 0;

    // --- intern ---
    var session as ActivityRecording.Session? = null;
    var spo2Field as FitContributor.Field? = null;
    var vo2Field as FitContributor.Field? = null;
    var timer as Timer.Timer? = null;
    var tickCount as Number = 0;
    var zones as Array<Number>? = null;

    function initialize() {
        loadZones();
        pageSec = Fields.getPageSec();
    }

    function setPageSec(sec as Number) as Void {
        pageSec = sec;
        pageTick = 0;
        Fields.setPageSec(sec);
    }

    // Pulsbereiche so, wie sie in den Uhren-Einstellungen eingestellt sind
    function loadZones() as Void {
        zones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
    }

    // ------------------------------------------------------------------
    // Sensoren
    // ------------------------------------------------------------------

    function startSensors() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
        timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
    }

    // Puls-Oximeter nur waehrend des Trainings einschalten (Akku)
    function enableWorkoutSensors() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_PULSE_OXIMETRY]);
    }

    function disableWorkoutSensors() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
    }

    function onSensor(info as Sensor.Info) as Void {
        if (info.heartRate != null) {
            sensorHr = info.heartRate;
        }
        if ((info has :oxygenSaturation) && info.oxygenSaturation != null && info.oxygenSaturation > 0) {
            spo2 = info.oxygenSaturation;
            spo2When = Time.now();
        }
    }

    // Fallback: letzter von der Uhr gemessener SpO2-Wert aus der Historie
    function refreshSpo2FromHistory() as Void {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getOxygenSaturationHistory)) {
            return;
        }
        var it = SensorHistory.getOxygenSaturationHistory({
            :period => 1,
            :order => SensorHistory.ORDER_NEWEST_FIRST
        });
        var sample = it.next();
        if (sample != null && sample.data != null && sample.when != null) {
            if (spo2When == null || sample.when.greaterThan(spo2When)) {
                spo2 = sample.data.toNumber();
                spo2When = sample.when;
            }
        }
    }

    // Neuester Messwert aus den letzten 5 Historien-Eintraegen (Eintraege ohne Wert werden uebersprungen)
    function latestSample(it as SensorHistory.SensorHistoryIterator?) as Numeric? {
        if (it == null) {
            return null;
        }
        for (var i = 0; i < 5; i += 1) {
            var s = it.next();
            if (s == null) {
                return null;
            }
            if (s.data != null) {
                return s.data;
            }
        }
        return null;
    }

    // Stress, Atmung, Body Battery und Temperatur. Die Uhr misst Stress und Atmung
    // in Bewegung kaum, deshalb merken wir uns den letzten bekannten Wert.
    function refreshSlow() as Void {
        var info = ActivityMonitor.getInfo();
        if ((info has :respirationRate) && info.respirationRate != null) {
            slow["resp"] = info.respirationRate;
        }
        if ((info has :stressScore) && info.stressScore != null) {
            slow["stress"] = info.stressScore;
        }

        if (!(Toybox has :SensorHistory)) {
            return;
        }
        var opt = {:period => 5, :order => SensorHistory.ORDER_NEWEST_FIRST};
        if (SensorHistory has :getStressHistory) {
            var v = latestSample(SensorHistory.getStressHistory(opt));
            if (v != null) {
                slow["stress"] = v;
            }
        }
        if (SensorHistory has :getBodyBatteryHistory) {
            var v = latestSample(SensorHistory.getBodyBatteryHistory(opt));
            if (v != null) {
                slow["bodyBattery"] = v;
            }
        }
        if (SensorHistory has :getTemperatureHistory) {
            var v = latestSample(SensorHistory.getTemperatureHistory(opt));
            if (v != null) {
                slow["temp"] = v;
            }
        }
    }

    // Alter des SpO2-Werts in Sekunden, null wenn es noch keinen gibt
    function spo2Age() as Number? {
        if (spo2 == null || spo2When == null) {
            return null;
        }
        return Time.now().subtract(spo2When).value();
    }

    function spo2IsFresh() as Boolean {
        var age = spo2Age();
        return age != null && age <= SPO2_MAX_AGE_S;
    }

    // ------------------------------------------------------------------
    // Sekundentakt
    // ------------------------------------------------------------------

    function onTick() as Void {
        tickCount += 1;

        var hr = sensorHr;
        if (recording) {
            var ai = Activity.getActivityInfo();
            if (ai != null) {
                if (ai.currentHeartRate != null) {
                    hr = ai.currentHeartRate;
                }
                // SpO2 ebenfalls ueber Activity statt ueber einen Sensor-Listener
                if ((ai has :currentOxygenSaturation) && ai.currentOxygenSaturation != null
                        && ai.currentOxygenSaturation > 0) {
                    spo2 = ai.currentOxygenSaturation;
                    spo2When = Time.now();
                }
                if (ai.timerTime != null) {
                    totalMs = ai.timerTime;
                }
                if (ai.calories != null) {
                    kcal = ai.calories;
                }
                if (ai.averageHeartRate != null) {
                    avgHr = ai.averageHeartRate;
                }
                if (ai.maxHeartRate != null) {
                    maxHr = ai.maxHeartRate;
                }
            }
        }
        currentHr = hr;

        // Stress/Atmung/Body Battery/Temperatur alle 30 s auffrischen (auch vor dem Start)
        if (tickCount % 30 == 1) {
            refreshSlow();
        }

        if (recording) {
            keepScreenOn();
        }

        if (recording && !paused) {
            if (pageSec > 0) {
                pageTick += 1;
                if (pageTick >= pageSec) {
                    togglePage();
                }
            }
            if (tickCount % 30 == 0) {
                refreshSpo2FromHistory();
            }
            if (spo2Field != null && spo2IsFresh()) {
                spo2Field.setData(spo2);
            }
            // Atmung und Stress zeichnet die Uhr beim Typ Yoga selbst auf; hier nur VO2max zusaetzlich
            var vo = Fields.vo2max();
            if (vo2Field != null && vo != null) {
                vo2Field.setData(vo.toNumber());
            }
        }
        WatchUi.requestUpdate();
    }

    // Pulsbereich 0 (unter Zone 1) bis 5
    function hrZone(hr as Number?) as Number {
        if (hr == null || zones == null) {
            return 0;
        }
        var z = 0;
        for (var i = 0; i < 5 && i < zones.size(); i += 1) {
            if (hr >= zones[i]) {
                z = i + 1;
            }
        }
        return z;
    }

    // ------------------------------------------------------------------
    // Training steuern
    // ------------------------------------------------------------------

    // Display moeglichst hell halten. Auf AMOLED-Uhren begrenzt das System das
    // (Einbrennschutz): dann wirft die Uhr eine Ausnahme, die wir ignorieren.
    function keepScreenOn() as Void {
        if ((Toybox has :Attention) && (Attention has :backlight)) {
            try {
                Attention.backlight(true);
            } catch (ex) {
                // Einbrennschutz greift: Display darf kurz dunkler werden
            }
        }
    }

    function beginWorkout() as Void {
        // Wichtig: Waehrend der Aufzeichnung KEINEN Sensor-Listener verwenden.
        // Auf der Venu 4 (Firmware 18.30/18.32) fuehrt das laut Garmin-Forum zu
        // Neustarts der Uhr. Puls und SpO2 kommen stattdessen aus Activity.getActivityInfo().
        Sensor.enableSensorEvents(null);
        enableWorkoutSensors();
        refreshSpo2FromHistory();
        loadZones();

        var s = ActivityRecording.createSession({
            :name => "Gymnastik",
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_YOGA
        });
        spo2Field = s.createField("SpO2", 0, FitContributor.DATA_TYPE_UINT8, {
            :mesgType => FitContributor.MESG_TYPE_RECORD,
            :units => "%"
        });
        vo2Field = s.createField("VO2max", 3, FitContributor.DATA_TYPE_UINT8, {
            :mesgType => FitContributor.MESG_TYPE_RECORD,
            :units => ""
        });
        session = s;
        s.start();

        recording = true;
        paused = false;
        totalMs = 0;
        kcal = 0;
        avgHr = 0;
        maxHr = 0;
        page = 0;
        pageTick = 0;
        refreshSlow();
    }

    function togglePage() as Void {
        page = (page + 1) % 2;
        pageTick = 0;
        WatchUi.requestUpdate();
    }

    function togglePause() as Void {
        if (!recording || session == null) {
            return;
        }
        if (paused) {
            session.start();
            paused = false;
        } else {
            session.stop();
            paused = true;
        }
    }

    function endWorkout(save as Boolean) as Void {
        if (!recording || session == null) {
            return;
        }
        var ai = Activity.getActivityInfo();
        if (ai != null) {
            sumTimeMs = (ai.timerTime != null) ? ai.timerTime : totalMs;
            sumKcal = (ai.calories != null) ? ai.calories : kcal;
            sumAvgHr = (ai.averageHeartRate != null) ? ai.averageHeartRate : 0;
            sumMaxHr = (ai.maxHeartRate != null) ? ai.maxHeartRate : 0;
        }

        if (session.isRecording()) {
            session.stop();
        }
        if (save) {
            session.save();
        } else {
            session.discard();
        }

        session = null;
        spo2Field = null;
        vo2Field = null;
        recording = false;
        paused = false;
        disableWorkoutSensors();
    }

    // Beim Schliessen der App: laufendes Training sichern, Sensoren aus
    function shutdown() as Void {
        if (recording) {
            endWorkout(true);
        }
        if (timer != null) {
            timer.stop();
            timer = null;
        }
        Sensor.enableSensorEvents(null);
        Sensor.setEnabledSensors([]);
    }
}
