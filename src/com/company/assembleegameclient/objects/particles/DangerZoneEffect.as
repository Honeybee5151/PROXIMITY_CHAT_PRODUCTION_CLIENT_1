package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.map.Square;
   import com.company.assembleegameclient.objects.GameObject;
   import com.company.assembleegameclient.objects.Player;
   import com.company.assembleegameclient.util.ConditionEffect;
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

      private static const DAMAGE_TICK_MS:int = 1000;  // damage every 1s
      private static const DAMAGE_AMOUNT:int = 100;
      private static const SLOW_DURATION_MS:int = 1500;

      // Dedup: only one DangerZoneEffect per target object
      private static var activeEffects_:Dictionary = new Dictionary();

      public static function hasActiveEffect(targetObjectId:int):Boolean
      {
         var fx:DangerZoneEffect = activeEffects_[targetObjectId] as DangerZoneEffect;
         if (fx == null) return false;
         if (fx.map_ == null)
         {
            delete activeEffects_[targetObjectId];
            return false;
         }
         return true;
      }

      public static function refreshEffect(targetObjectId:int, durationMs:int):void
      {
         var fx:DangerZoneEffect = activeEffects_[targetObjectId] as DangerZoneEffect;
         if (fx != null && fx.map_ != null)
         {
            fx.timeLeft_ = durationMs;
         }
      }

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
      private var damageTimer_:int;
      private var slowTimer_:int;

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
         this.damageTimer_ = 0;

         activeEffects_[targetObjectId] = this;
      }

      override public function removeFromMap():void
      {
         // Clear slow if we applied it
         if (this.slowTimer_ > 0 && map_ != null && map_.player_ != null)
         {
            map_.player_.condition_[ConditionEffect.CE_FIRST_BATCH] &= ~ConditionEffect.SLOWED_BIT;
            this.slowTimer_ = 0;
         }
         delete activeEffects_[this.targetObjectId_];
         super.removeFromMap();
      }

      override public function update(time:int, dt:int) : Boolean
      {
         this.timeLeft_ -= dt;
         if (this.timeLeft_ <= 0)
         {
            if (this.slowTimer_ > 0 && map_ != null && map_.player_ != null)
            {
               map_.player_.condition_[ConditionEffect.CE_FIRST_BATCH] &= ~ConditionEffect.SLOWED_BIT;
            }
            delete activeEffects_[this.targetObjectId_];
            return false;
         }

         if (map_ == null) return true;

         // Tick down slow timer and clear slow when expired
         if (this.slowTimer_ > 0 && map_.player_ != null)
         {
            this.slowTimer_ -= dt;
            if (this.slowTimer_ <= 0)
            {
               this.slowTimer_ = 0;
               map_.player_.condition_[ConditionEffect.CE_FIRST_BATCH] &= ~ConditionEffect.SLOWED_BIT;
            }
         }

         // Pin square_ to player so effect is always drawn
         if (map_.player_ != null)
         {
            var playerSq:Square = map_.getSquare(map_.player_.x_, map_.player_.y_);
            if (playerSq != null)
               square_ = playerSq;
         }

         var targetObj:GameObject = map_.goDict_[this.targetObjectId_] as GameObject;
         if (targetObj == null)
         {
            // Boss gone — keep rendering at last known position, still do damage
            checkDamage(time, dt);
            return true;
         }

         // Track our position to the target
         x_ = targetObj.x_;
         y_ = targetObj.y_;

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

         // Spawn edge particles
         this.edgeSpawnTimer_ += dt;
         if (this.edgeSpawnTimer_ >= 100 && this.hasDirection_)
         {
            this.edgeSpawnTimer_ = 0;
            spawnConeEdgeParticles();
         }

         // Client-side damage
         checkDamage(time, dt);

         return true;
      }

      private function checkDamage(time:int, dt:int) : void
      {
         if (map_ == null || map_.player_ == null) return;
         if (!this.hasDirection_) return;

         this.damageTimer_ += dt;
         if (this.damageTimer_ < DAMAGE_TICK_MS) return;
         this.damageTimer_ -= DAMAGE_TICK_MS;

         var player:Player = map_.player_;

         // Skip if invincible/invulnerable
         if (player.isInvincible() || player.isInvulnerable()) return;
         if (player.hp_ <= 0) return;

         // Check distance from boss
         var pdx:Number = player.x_ - x_;
         var pdy:Number = player.y_ - y_;
         var dist:Number = Math.sqrt(pdx * pdx + pdy * pdy);
         if (dist > this.zoneRadius_) return; // Outside zone entirely

         // Check if player is in safe cone
         var effectiveHalf:Number = effectiveHalfAngle(dist);
         var angleToPlayer:Number = Math.atan2(pdy, pdx);
         var diff:Number = angleToPlayer - this.smoothedAngle_;
         while (diff > Math.PI) diff -= Math.PI * 2;
         while (diff < -Math.PI) diff += Math.PI * 2;

         if (Math.abs(diff) <= effectiveHalf) return; // In safe cone

         // Player is outside safe cone — damage them (same as ground damage)
         var kill:Boolean = player.hp_ <= DAMAGE_AMOUNT;
         player.damage(DAMAGE_AMOUNT, null, kill, null, true);
         map_.gs_.gsc_.groundDamage(time, player.x_, player.y_);

         // Apply slow effect
         if (!player.isSlowedImmune())
         {
            player.condition_[ConditionEffect.CE_FIRST_BATCH] |= ConditionEffect.SLOWED_BIT;
            this.slowTimer_ = SLOW_DURATION_MS;
         }
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

            this.worldVerts_.push(cx, cy, 0);

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

            this.worldVerts_.push(cx, cy, 0);
         }

         this.screenVerts_.length = 0;
         camera.wToS_.transformVectors(this.worldVerts_, this.screenVerts_);

         this.path_.commands.length = 0;
         this.path_.data.length = 0;

         this.path_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.path_.data.push(this.screenVerts_[0], this.screenVerts_[1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            this.path_.commands.push(GraphicsPathCommand.LINE_TO);
            this.path_.data.push(this.screenVerts_[i * 3], this.screenVerts_[i * 3 + 1]);
         }

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
