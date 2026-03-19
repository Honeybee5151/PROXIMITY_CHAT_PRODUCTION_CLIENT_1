package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.map.Square;
   import com.company.assembleegameclient.objects.GameObject;
   import com.company.assembleegameclient.util.RandomUtil;
   import com.company.util.GraphicsUtil;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsPathCommand;
   import flash.display.GraphicsSolidFill;
   import flash.display.IGraphicsData;
   import flash.utils.Dictionary;

   public class DangerZoneEffect extends ParticleEffect
   {
      private static const NUM_SEGMENTS:int = 48;
      private static const EDGE_SEGMENTS:int = 16;
      private static const ARC_SEGMENTS:int = 24;
      private static const CONE_TAPER:Number = 0.4;

      // Dedup: only one DangerZoneEffect per target object
      private static var activeEffects_:Dictionary = new Dictionary();

      public static function hasActiveEffect(targetObjectId:int):Boolean
      {
         var fx:DangerZoneEffect = activeEffects_[targetObjectId] as DangerZoneEffect;
         if (fx == null) return false;
         // Stale check: if the effect was removed from map, clean up
         if (fx.map_ == null)
         {
            delete activeEffects_[targetObjectId];
            return false;
         }
         return true;
      }

      /** Refresh the timer of an existing effect (called on server re-broadcast) */
      public static function refreshEffect(targetObjectId:int, durationMs:int):void
      {
         var fx:DangerZoneEffect = activeEffects_[targetObjectId] as DangerZoneEffect;
         if (fx != null && fx.map_ != null)
         {
            fx.timeLeft_ = durationMs;
         }
      }

      /** Clear all active effects — call on map/instance change */
      public static function clearAll():void
      {
         activeEffects_ = new Dictionary();
      }

      public var targetObjectId_:int;
      public var coneHalfAngle_:Number;
      public var zoneRadius_:Number;
      public var zoneColor_:uint;
      public var duration_:int;
      public var timeLeft_:int;

      // Direction tracking
      private var lastTargetX_:Number;
      private var lastTargetY_:Number;
      private var smoothedAngle_:Number;
      private var hasDirection_:Boolean;

      // Rendering
      private var fill_:GraphicsSolidFill;
      private var path_:GraphicsPath;
      private var worldVerts_:Vector.<Number>;
      private var screenVerts_:Vector.<Number>;

      private var edgeSpawnTimer_:int;

      public function DangerZoneEffect(targetObjectId:int, coneHalfAngle:Number, radius:Number, color:int, durationMs:int)
      {
         super();
         this.targetObjectId_ = targetObjectId;
         this.coneHalfAngle_ = coneHalfAngle;
         this.zoneRadius_ = radius;
         this.zoneColor_ = color & 0xFFFFFF;
         this.duration_ = durationMs;
         this.timeLeft_ = durationMs;

         this.lastTargetX_ = NaN;
         this.lastTargetY_ = NaN;
         this.smoothedAngle_ = 0;
         this.hasDirection_ = false;

         this.fill_ = new GraphicsSolidFill(this.zoneColor_, 0.28);
         this.path_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());
         this.worldVerts_ = new Vector.<Number>();
         this.screenVerts_ = new Vector.<Number>();
         this.edgeSpawnTimer_ = 999;

         activeEffects_[targetObjectId] = this;
      }

      override public function removeFromMap():void
      {
         delete activeEffects_[this.targetObjectId_];
         super.removeFromMap();
      }

      override public function update(time:int, dt:int) : Boolean
      {
         this.timeLeft_ -= dt;
         if (this.timeLeft_ <= 0)
         {
            delete activeEffects_[this.targetObjectId_];
            return false;
         }

         if (map_ == null) return true;

         var targetObj:GameObject = map_.goDict_[this.targetObjectId_] as GameObject;
         if (targetObj == null)
         {
            // Boss gone — keep rendering at last known position, pin to player square
            if (map_ != null && map_.player_ != null)
            {
               var pSq:Square = map_.getSquare(map_.player_.x_, map_.player_.y_);
               if (pSq != null)
                  square_ = pSq;
            }
            return true;
         }

         // Track our position to the target
         x_ = targetObj.x_;
         y_ = targetObj.y_;

         // Pin square_ to player position so the effect is ALWAYS drawn
         if (map_ != null && map_.player_ != null)
         {
            var playerSq:Square = map_.getSquare(map_.player_.x_, map_.player_.y_);
            if (playerSq != null)
               square_ = playerSq;
         }

         // Compute movement direction from position delta
         var TURN_SPEED_RAD:Number = 30.0 * Math.PI / 180.0;
         if (!isNaN(this.lastTargetX_))
         {
            var dx:Number = targetObj.x_ - this.lastTargetX_;
            var dy:Number = targetObj.y_ - this.lastTargetY_;

            if (dx * dx + dy * dy > 0.001)
            {
               var rawAngle:Number = Math.atan2(dy, dx);

               if (!this.hasDirection_)
               {
                  this.smoothedAngle_ = rawAngle;
                  this.hasDirection_ = true;
               }
               else
               {
                  var angleDiff:Number = rawAngle - this.smoothedAngle_;
                  while (angleDiff > Math.PI) angleDiff -= Math.PI * 2;
                  while (angleDiff < -Math.PI) angleDiff += Math.PI * 2;
                  var maxRotation:Number = TURN_SPEED_RAD * (dt / 1000.0);
                  if (Math.abs(angleDiff) <= maxRotation)
                     this.smoothedAngle_ = rawAngle;
                  else
                     this.smoothedAngle_ += (angleDiff > 0 ? 1 : -1) * maxRotation;
               }
            }
         }
         this.lastTargetX_ = targetObj.x_;
         this.lastTargetY_ = targetObj.y_;

         // Spawn edge particles along the curved cone boundary
         this.edgeSpawnTimer_ += dt;
         if (this.edgeSpawnTimer_ >= 100 && map_ != null && this.hasDirection_)
         {
            this.edgeSpawnTimer_ = 0;
            spawnConeEdgeParticles();
         }

         return true;
      }

      private function effectiveHalfAngle(dist:Number) : Number
      {
         var t:Number = dist / this.zoneRadius_;
         if (t > 1) t = 1;
         if (t < 0) t = 0;
         return this.coneHalfAngle_ * (1.0 - CONE_TAPER * t);
      }

      private function spawnConeEdgeParticles() : void
      {
         var numParticles:int = 4;
         for (var i:int = 0; i < numParticles; i++)
         {
            var side:Number = (i < numParticles / 2) ? 1 : -1;
            var dist:Number = 2 + Math.random() * (this.zoneRadius_ - 2);
            var edgeAngle:Number = this.smoothedAngle_ + side * effectiveHalfAngle(dist);
            var px:Number = x_ + Math.cos(edgeAngle) * dist;
            var py:Number = y_ + Math.sin(edgeAngle) * dist;

            var part:SparkParticle = new SparkParticle(
               60, this.zoneColor_, 250, 0.4,
               RandomUtil.plusMinus(0.15),
               RandomUtil.plusMinus(0.15)
            );
            map_.addObj(part, px, py);
         }
      }

      override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : void
      {
         var cx:Number = x_;
         var cy:Number = y_;
         var r:Number = this.zoneRadius_;

         this.path_.commands.length = 0;
         this.path_.data.length = 0;
         this.worldVerts_.length = 0;

         var i:int;
         var angle:Number;
         var step:Number;
         var d:Number;
         var ha:Number;

         // --- Outer circle (clockwise) ---
         step = (Math.PI * 2) / NUM_SEGMENTS;
         for (i = 0; i <= NUM_SEGMENTS; i++)
         {
            angle = i * step;
            this.worldVerts_.push(
               cx + Math.cos(angle) * r,
               cy + Math.sin(angle) * r,
               0
            );
         }

         // --- Curved cone cutout (only if we have a direction) ---
         if (this.hasDirection_)
         {
            var coneR:Number = r * 1.15;

            // Start at boss center
            this.worldVerts_.push(cx, cy, 0);

            // Positive edge: center → tip
            for (i = 1; i <= EDGE_SEGMENTS; i++)
            {
               d = (i / Number(EDGE_SEGMENTS)) * coneR;
               ha = effectiveHalfAngle(d);
               angle = this.smoothedAngle_ + ha;
               this.worldVerts_.push(
                  cx + Math.cos(angle) * d,
                  cy + Math.sin(angle) * d,
                  0
               );
            }

            // Arc across the tip
            var tipHalfAngle:Number = effectiveHalfAngle(coneR);
            var arcStartAngle:Number = this.smoothedAngle_ + tipHalfAngle;
            var arcEndAngle:Number = this.smoothedAngle_ - tipHalfAngle;
            var arcStep:Number = (arcStartAngle - arcEndAngle) / ARC_SEGMENTS;
            for (i = 0; i <= ARC_SEGMENTS; i++)
            {
               angle = arcStartAngle - i * arcStep;
               this.worldVerts_.push(
                  cx + Math.cos(angle) * coneR,
                  cy + Math.sin(angle) * coneR,
                  0
               );
            }

            // Negative edge: tip → center
            for (i = EDGE_SEGMENTS - 1; i >= 1; i--)
            {
               d = (i / Number(EDGE_SEGMENTS)) * coneR;
               ha = effectiveHalfAngle(d);
               angle = this.smoothedAngle_ - ha;
               this.worldVerts_.push(
                  cx + Math.cos(angle) * d,
                  cy + Math.sin(angle) * d,
                  0
               );
            }

            // Back to center
            this.worldVerts_.push(cx, cy, 0);
         }

         // Transform all to screen
         this.screenVerts_.length = 0;
         camera.wToS_.transformVectors(this.worldVerts_, this.screenVerts_);

         // --- Build path commands ---
         this.path_.commands.length = 0;
         this.path_.data.length = 0;

         // Outer circle path
         this.path_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.path_.data.push(this.screenVerts_[0], this.screenVerts_[1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            this.path_.commands.push(GraphicsPathCommand.LINE_TO);
            this.path_.data.push(this.screenVerts_[i * 3], this.screenVerts_[i * 3 + 1]);
         }

         // Curved cone cutout path
         if (this.hasDirection_)
         {
            var idx:int = (NUM_SEGMENTS + 1) * 3;

            this.path_.commands.push(GraphicsPathCommand.MOVE_TO);
            this.path_.data.push(this.screenVerts_[idx], this.screenVerts_[idx + 1]);
            idx += 3;

            for (i = 0; i < EDGE_SEGMENTS; i++)
            {
               this.path_.commands.push(GraphicsPathCommand.LINE_TO);
               this.path_.data.push(this.screenVerts_[idx], this.screenVerts_[idx + 1]);
               idx += 3;
            }

            for (i = 0; i <= ARC_SEGMENTS; i++)
            {
               this.path_.commands.push(GraphicsPathCommand.LINE_TO);
               this.path_.data.push(this.screenVerts_[idx], this.screenVerts_[idx + 1]);
               idx += 3;
            }

            var negEdgeCount:int = EDGE_SEGMENTS - 1;
            for (i = 0; i < negEdgeCount; i++)
            {
               this.path_.commands.push(GraphicsPathCommand.LINE_TO);
               this.path_.data.push(this.screenVerts_[idx], this.screenVerts_[idx + 1]);
               idx += 3;
            }

            this.path_.commands.push(GraphicsPathCommand.LINE_TO);
            this.path_.data.push(this.screenVerts_[idx], this.screenVerts_[idx + 1]);
         }

         this.fill_.alpha = 0.45;

         graphicsData.push(this.fill_);
         graphicsData.push(this.path_);
         graphicsData.push(GraphicsUtil.END_FILL);
      }
   }
}
