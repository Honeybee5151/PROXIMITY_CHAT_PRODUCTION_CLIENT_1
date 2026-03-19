package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.objects.GameObject;
   import com.company.assembleegameclient.util.RandomUtil;
   import com.company.util.GraphicsUtil;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsPathCommand;
   import flash.display.GraphicsSolidFill;
   import flash.display.IGraphicsData;

   public class DangerZoneEffect extends ParticleEffect
   {
      private static const NUM_SEGMENTS:int = 48;
      private static const CONE_SEGMENTS:int = 24;

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
      }

      override public function update(time:int, dt:int) : Boolean
      {
         this.timeLeft_ -= dt;
         if (this.timeLeft_ <= 0)
         {
            return false;
         }

         // Look up the target object each frame
         if (map_ == null) return true;

         var targetObj:GameObject = map_.goDict_[this.targetObjectId_] as GameObject;
         if (targetObj == null)
         {
            return false; // Target dead
         }

         // Track our position to the target
         x_ = targetObj.x_;
         y_ = targetObj.y_;

         // Compute movement direction from position delta
         // Cone rotates at ~30 deg/sec to match server turn speed
         var TURN_SPEED_RAD:Number = 30.0 * Math.PI / 180.0; // 30 deg/sec in radians
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
                  // Clamped rotation — max turn per frame matches server
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

         // Spawn edge particles along the cone boundary
         this.edgeSpawnTimer_ += dt;
         if (this.edgeSpawnTimer_ >= 100 && map_ != null && this.hasDirection_)
         {
            this.edgeSpawnTimer_ = 0;
            spawnConeEdgeParticles();
         }

         return true;
      }

      private function spawnConeEdgeParticles() : void
      {
         var numParticles:int = 4;
         for (var i:int = 0; i < numParticles; i++)
         {
            // Spawn particles along the two edges of the safe cone
            var side:Number = (i < numParticles / 2) ? 1 : -1;
            var edgeAngle:Number = this.smoothedAngle_ + side * this.coneHalfAngle_;
            var dist:Number = 2 + Math.random() * (this.zoneRadius_ - 2);
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
         if (!this.hasDirection_) return;

         var cx:Number = x_;
         var cy:Number = y_;
         var r:Number = this.zoneRadius_;

         // Build path: large circle (CW) + cone cutout (CCW) = danger zone with safe cone hole

         this.path_.commands.length = 0;
         this.path_.data.length = 0;
         this.worldVerts_.length = 0;

         var i:int;
         var angle:Number;
         var step:Number;

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

         // --- Cone cutout (counter-clockwise = hole) ---
         // Start at boss center
         this.worldVerts_.push(cx, cy, 0);

         // Arc from +halfAngle to -halfAngle (CCW = going from positive to negative)
         var coneStartAngle:Number = this.smoothedAngle_ + this.coneHalfAngle_;
         var coneEndAngle:Number = this.smoothedAngle_ - this.coneHalfAngle_;
         var coneStep:Number = (coneStartAngle - coneEndAngle) / CONE_SEGMENTS;

         for (i = 0; i <= CONE_SEGMENTS; i++)
         {
            angle = coneStartAngle - i * coneStep;
            this.worldVerts_.push(
               cx + Math.cos(angle) * r,
               cy + Math.sin(angle) * r,
               0
            );
         }

         // Back to center
         this.worldVerts_.push(cx, cy, 0);

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

         // Cone cutout path (starts after circle vertices)
         var coneOffset:int = (NUM_SEGMENTS + 1) * 3; // center point
         this.path_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.path_.data.push(this.screenVerts_[coneOffset], this.screenVerts_[coneOffset + 1]);

         // Arc points
         var arcStart:int = coneOffset + 3; // first arc point
         for (i = 0; i <= CONE_SEGMENTS; i++)
         {
            this.path_.commands.push(GraphicsPathCommand.LINE_TO);
            this.path_.data.push(
               this.screenVerts_[arcStart + i * 3],
               this.screenVerts_[arcStart + i * 3 + 1]
            );
         }

         // Back to center
         var backIdx:int = arcStart + (CONE_SEGMENTS + 1) * 3;
         this.path_.commands.push(GraphicsPathCommand.LINE_TO);
         this.path_.data.push(this.screenVerts_[backIdx], this.screenVerts_[backIdx + 1]);

         this.fill_.alpha = 0.25;

         graphicsData.push(this.fill_);
         graphicsData.push(this.path_);
         graphicsData.push(GraphicsUtil.END_FILL);
      }
   }
}
