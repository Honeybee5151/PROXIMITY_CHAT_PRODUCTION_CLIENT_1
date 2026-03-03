package com.company.assembleegameclient.map
{
import flash.display.Shape;

//editor8182381 — Progressive darkness overlay for out-of-bounds zones
public class DarknessOverlay extends Shape
{
    public function DarknessOverlay()
    {
        super();
        graphics.beginFill(0x000000);
        graphics.drawRect(-4000, -4000, 8000, 8000);
        graphics.endFill();
        visible = false;
    }
}
}
