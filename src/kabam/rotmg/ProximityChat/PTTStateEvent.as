package kabam.rotmg.ProximityChat {
import flash.events.Event;

public class PTTStateEvent extends Event {
    public var pressed:Boolean;

    public function PTTStateEvent(type:String, pressed:Boolean) {
        super(type);
        this.pressed = pressed;
    }
}
}