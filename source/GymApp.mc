import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GymApp extends Application.AppBase {

    var model as WorkoutModel?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        model = new WorkoutModel();
        model.startSensors();
    }

    // Wird die App beendet (oder vom System geschlossen), solange noch
    // aufgezeichnet wird, wird das Training gespeichert statt verworfen.
    function onStop(state as Dictionary?) as Void {
        if (model != null) {
            model.shutdown();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new StartView(), new StartDelegate()];
    }
}

function getModel() as WorkoutModel {
    return (Application.getApp() as GymApp).model as WorkoutModel;
}
