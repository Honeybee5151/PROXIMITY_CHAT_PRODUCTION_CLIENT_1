package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.objects.GameObject;
   import com.company.assembleegameclient.util.FreeList;

   public class SandstormEffect extends ParticleEffect
   {
      private static const SPAWN_PERIOD:int = 40;
      private static const SPAWN_RADIUS:Number = 3.0;

      public var go_:GameObject;
      public var lastUpdate_:int = -1;

      public function SandstormEffect(go:GameObject)
      {
         super();
         this.go_ = go;
      }

      override public function update(time:int, dt:int) : Boolean
      {
         if(this.go_.map_ == null)
         {
            return false;
         }
         if(this.lastUpdate_ < 0)
         {
            this.lastUpdate_ = Math.max(0, time - 400);
         }
         x_ = this.go_.x_;
         y_ = this.go_.y_;
         for(var i:int = int(this.lastUpdate_ / SPAWN_PERIOD); i < int(time / SPAWN_PERIOD); i++)
         {
            var t:int = i * SPAWN_PERIOD;
            var count:int = 2 + int(Math.random() * 2);
            for(var j:int = 0; j < count; j++)
            {
               var part:SandParticle = FreeList.newObject(SandParticle) as SandParticle;
               var angle:Number = Math.random() * 2 * Math.PI;
               var dist:Number = Math.random() * SPAWN_RADIUS;
               var spawnX:Number = x_ + Math.cos(angle) * dist;
               var spawnY:Number = y_ + Math.sin(angle) * dist;
               part.restart(t, time);
               map_.addObj(part, spawnX, spawnY);
            }
         }
         this.lastUpdate_ = time;
         return true;
      }
   }
}

import com.company.assembleegameclient.objects.particles.Particle;
import com.company.assembleegameclient.util.FreeList;

class SandParticle extends Particle
{
   private static const SAND_COLORS:Array = [0xC2A24D, 0xB8963E, 0xD4B85A, 0xA88B3A, 0xCFAE55];
   private static const MAX_LIFE:Number = 2.5;

   public var startTime_:int;
   private var moveAngle_:Number;
   private var speed_:Number;
   private var rotSpeed_:Number;
   private var life_:Number;
   private var initZ_:Number;

   function SandParticle()
   {
      var colorIndex:int = int(Math.random() * SAND_COLORS.length);
      super(SAND_COLORS[colorIndex], 0.3, 40 + int(Math.random() * 50));
   }

   public function restart(startTime:int, time:int) : void
   {
      this.startTime_ = startTime;
      this.moveAngle_ = Math.random() * 2 * Math.PI;
      this.speed_ = 1.5 + Math.random() * 1.5;
      this.rotSpeed_ = (Math.random() - 0.5) * 2.0;
      this.life_ = 1.5 + Math.random() * 1.0;
      this.initZ_ = 0.1 + Math.random() * 1.2;

      var colorIndex:int = int(Math.random() * SAND_COLORS.length);
      setColor(SAND_COLORS[colorIndex]);
      setSize(40 + int(Math.random() * 50));

      var elapsed:Number = (time - this.startTime_) / 1000;
      var curAngle:Number = this.moveAngle_ + this.rotSpeed_ * elapsed;
      x_ = x_ + Math.cos(curAngle) * this.speed_ * elapsed * 0.5;
      y_ = y_ + Math.sin(curAngle) * this.speed_ * elapsed * 0.5;
      z_ = this.initZ_ + Math.sin(elapsed * 3) * 0.3;
   }

   override public function removeFromMap() : void
   {
      super.removeFromMap();
      FreeList.deleteObject(this);
   }

   override public function update(time:int, dt:int) : Boolean
   {
      var elapsed:Number = (time - this.startTime_) / 1000;
      if(elapsed > this.life_)
      {
         return false;
      }
      var curAngle:Number = this.moveAngle_ + this.rotSpeed_ * elapsed;
      var dtSec:Number = dt / 1000;
      moveTo(x_ + Math.cos(curAngle) * this.speed_ * dtSec * 0.5, y_ + Math.sin(curAngle) * this.speed_ * dtSec * 0.5);
      z_ = this.initZ_ + Math.sin(elapsed * 3) * 0.3;
      return true;
   }
}
