package com.company.assembleegameclient.map.mapoverlay {

import com.company.assembleegameclient.map.Camera;
import com.company.assembleegameclient.objects.GameObject;

import flash.display.Sprite;
import flash.filters.GlowFilter;

//777592 - Speaker icon overlay for proximity voice chat
public class SpeakerIcon extends Sprite implements IMapOverlayElement {

    public var go_:GameObject;
    private var removed:Boolean = false;

    public function SpeakerIcon(go:GameObject) {
        this.go_ = go;
        drawIcon();
        visible = false;
    }

    private function drawIcon():void {
        // Small speaker icon ~12x12, white at 80% alpha, centered on x=0
        alpha = 0.8;

        // Icon spans roughly from -8 to +8 on x-axis (centered)
        var ox:Number = -7; // offset to center the whole icon

        // Speaker body (small rectangle + triangle)
        graphics.beginFill(0xFFFFFF);
        // Rectangle part of speaker
        graphics.drawRect(ox - 2, -3, 4, 6);
        // Triangle cone
        graphics.moveTo(ox + 2, -5);
        graphics.lineTo(ox + 6, -8);
        graphics.lineTo(ox + 6, 8);
        graphics.lineTo(ox + 2, 5);
        graphics.lineTo(ox + 2, -5);
        graphics.endFill();

        // Sound waves (arcs)
        graphics.lineStyle(1.5, 0xFFFFFF, 0.7);
        // First wave
        drawArc(ox + 8, 0, 4, -0.6, 0.6);
        // Second wave
        graphics.lineStyle(1.5, 0xFFFFFF, 0.5);
        drawArc(ox + 8, 0, 7, -0.5, 0.5);

        // Glow for visibility on all backgrounds
        filters = [new GlowFilter(0x000000, 0.8, 4, 4, 2, 1)];
    }

    private function drawArc(cx:Number, cy:Number, radius:Number, startAngle:Number, endAngle:Number):void {
        var steps:int = 8;
        var angleStep:Number = (endAngle - startAngle) / steps;
        graphics.moveTo(cx + Math.cos(startAngle) * radius, cy + Math.sin(startAngle) * radius);
        for (var i:int = 1; i <= steps; i++) {
            var angle:Number = startAngle + angleStep * i;
            graphics.lineTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
        }
    }

    public function draw(camera:Camera, time:int):Boolean {
        if (removed || go_ == null || go_.map_ == null) {
            return false;
        }
        if (!go_.drawn_) {
            visible = false;
            return true;
        }

        visible = true;
        x = int(go_.posS_[0]);
        // Recalculate Y every frame so icon tracks size changes
        y = int(go_.posS_[1] - go_.texture_.height * (go_.size_ / 100) * 5 - 35);
        return true;
    }

    public function remove():void {
        removed = true;
    }

    public function getGameObject():GameObject {
        return go_;
    }

    public function dispose():void {
        if (parent) {
            parent.removeChild(this);
        }
    }
}
}
