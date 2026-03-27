package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.util.RandomUtil;
   import com.company.util.GraphicsUtil;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsPathCommand;
   import flash.display.GraphicsPathWinding;
   import flash.display.GraphicsSolidFill;
   import flash.display.GraphicsStroke;
   import flash.display.IGraphicsData;
   import flash.display.LineScaleMode;
   import flash.display.CapsStyle;
   import flash.display.JointStyle;

   public class ExpandingRingEffect extends ParticleEffect
   {
      private static const NUM_SEGMENTS:int = 64;

      public var centerX_:Number;
      public var centerY_:Number;
      public var maxRadius_:Number;
      public var ringThickness_:Number;
      public var ringColor_:uint;
      public var duration_:int;
      public var timeLeft_:int;

      // Hitbox band (filled donut matching server damage area)
      private var bandFill_:GraphicsSolidFill;
      private var bandPath_:GraphicsPath;

      // Edge glow strokes (inner + outer edges of the band)
      private var glowStroke_:GraphicsStroke;
      private var glowFill_:GraphicsSolidFill;
      private var innerEdgePath_:GraphicsPath;
      private var outerEdgePath_:GraphicsPath;

      private var worldVerts_:Vector.<Number>;
      private var screenVerts_:Vector.<Number>;

      private var edgeSpawnTimer_:int;

      public function ExpandingRingEffect(cx:Number, cy:Number, maxRadius:Number, thickness:Number, color:int, durationMs:int)
      {
         super();
         this.centerX_ = cx;
         this.centerY_ = cy;
         this.maxRadius_ = maxRadius;
         this.ringThickness_ = thickness;
         this.ringColor_ = color & 0xFFFFFF;
         this.duration_ = durationMs;
         this.timeLeft_ = durationMs;

         // Filled band = the actual hitbox area
         this.bandFill_ = new GraphicsSolidFill(this.ringColor_, 0.35);
         this.bandPath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>(), GraphicsPathWinding.EVEN_ODD);

         // Edge glow on inner and outer edges of the band
         this.glowFill_ = new GraphicsSolidFill(this.ringColor_, 0.7);
         this.glowStroke_ = new GraphicsStroke(2, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
         this.glowStroke_.fill = this.glowFill_;
         this.innerEdgePath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());
         this.outerEdgePath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());

         this.worldVerts_ = new Vector.<Number>();
         this.screenVerts_ = new Vector.<Number>();
         this.edgeSpawnTimer_ = 999;
         this.alwaysDraw_ = true;
      }

      override public function update(time:int, dt:int) : Boolean
      {
         this.timeLeft_ -= dt;
         if (this.timeLeft_ <= 0)
         {
            return false;
         }

         x_ = this.centerX_;
         y_ = this.centerY_;

         // Spawn edge particles along the ring
         this.edgeSpawnTimer_ += dt;
         if (this.edgeSpawnTimer_ >= 60 && map_ != null)
         {
            this.edgeSpawnTimer_ = 0;
            spawnRingParticles();
         }

         return true;
      }

      private function spawnRingParticles() : void
      {
         // Match server: progress = elapsed / total
         var progress:Number = 1.0 - (this.timeLeft_ / Number(this.duration_));
         var currentRadius:Number = progress * this.maxRadius_;
         if (currentRadius < 0.5) return;

         var numParticles:int = 6;
         for (var i:int = 0; i < numParticles; i++)
         {
            var angle:Number = Math.random() * Math.PI * 2;
            // Particles on outer edge of the ring band
            var outerR:Number = currentRadius + this.ringThickness_ / 2;
            var r:Number = outerR + (Math.random() - 0.5) * 0.5;
            var px:Number = this.centerX_ + Math.cos(angle) * r;
            var py:Number = this.centerY_ + Math.sin(angle) * r;

            var part:SparkParticle = new SparkParticle(
               60, this.ringColor_, 250, 0.35,
               RandomUtil.plusMinus(0.15),
               RandomUtil.plusMinus(0.15)
            );
            map_.addObj(part, px, py);
         }
      }

      /**
       * Builds a circle path in screen coords at the given world-space radius.
       */
      private function buildCirclePath(path:GraphicsPath, radius:Number, camera:Camera) : void
      {
         this.worldVerts_.length = 0;
         var i:int;
         var angle:Number;
         var step:Number = (Math.PI * 2) / NUM_SEGMENTS;

         for (i = 0; i <= NUM_SEGMENTS; i++)
         {
            angle = i * step;
            this.worldVerts_.push(
               this.centerX_ + Math.cos(angle) * radius,
               this.centerY_ + Math.sin(angle) * radius,
               0
            );
         }

         this.screenVerts_.length = 0;
         camera.wToS_.transformVectors(this.worldVerts_, this.screenVerts_);

         path.commands.length = 0;
         path.data.length = 0;

         path.commands.push(GraphicsPathCommand.MOVE_TO);
         path.data.push(this.screenVerts_[0], this.screenVerts_[1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            path.commands.push(GraphicsPathCommand.LINE_TO);
            path.data.push(this.screenVerts_[i * 3], this.screenVerts_[i * 3 + 1]);
         }
      }

      override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : void
      {
         // Match server exactly: progress = elapsed / total
         var progress:Number = 1.0 - (this.timeLeft_ / Number(this.duration_));
         var currentRadius:Number = progress * this.maxRadius_;
         if (currentRadius < 0.1) return;

         // Server hitbox band: [ringInner, ringOuter]
         var ringInner:Number = currentRadius - this.ringThickness_ / 2;
         if (ringInner < 0) ringInner = 0;
         var ringOuter:Number = currentRadius + this.ringThickness_ / 2;

         // Fade out in the last 20% of duration
         var fadeMultiplier:Number = 1.0;
         if (progress > 0.8)
         {
            fadeMultiplier = (1.0 - progress) / 0.2;
         }

         // --- 1) Filled donut = the hitbox area ---
         // Build outer circle CW, then inner circle CCW in the same path
         // EVEN_ODD winding creates the donut cutout
         this.bandPath_.commands.length = 0;
         this.bandPath_.data.length = 0;

         var i:int;
         var angle:Number;
         var step:Number = (Math.PI * 2) / NUM_SEGMENTS;

         // Outer circle (CW)
         this.worldVerts_.length = 0;
         for (i = 0; i <= NUM_SEGMENTS; i++)
         {
            angle = i * step;
            this.worldVerts_.push(
               this.centerX_ + Math.cos(angle) * ringOuter,
               this.centerY_ + Math.sin(angle) * ringOuter,
               0
            );
         }
         // Inner circle (CCW — reversed)
         for (i = NUM_SEGMENTS; i >= 0; i--)
         {
            angle = i * step;
            this.worldVerts_.push(
               this.centerX_ + Math.cos(angle) * ringInner,
               this.centerY_ + Math.sin(angle) * ringInner,
               0
            );
         }

         this.screenVerts_.length = 0;
         camera.wToS_.transformVectors(this.worldVerts_, this.screenVerts_);

         // Outer circle path
         this.bandPath_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.bandPath_.data.push(this.screenVerts_[0], this.screenVerts_[1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            this.bandPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.bandPath_.data.push(this.screenVerts_[i * 3], this.screenVerts_[i * 3 + 1]);
         }

         // Inner circle path (offset by NUM_SEGMENTS+1 points)
         var offset:int = (NUM_SEGMENTS + 1) * 3;
         this.bandPath_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.bandPath_.data.push(this.screenVerts_[offset], this.screenVerts_[offset + 1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            this.bandPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.bandPath_.data.push(this.screenVerts_[offset + i * 3], this.screenVerts_[offset + i * 3 + 1]);
         }

         // Pulsing fill
         var pulse:Number = 0.25 + 0.1 * Math.sin(time * 0.008);
         this.bandFill_.alpha = pulse * fadeMultiplier;

         graphicsData.push(this.bandFill_);
         graphicsData.push(this.bandPath_);
         graphicsData.push(GraphicsUtil.END_FILL);

         // --- 2) Bright edge strokes on inner and outer edges ---
         var edgeAlpha:Number = (0.6 + 0.15 * Math.sin(time * 0.01)) * fadeMultiplier;
         this.glowFill_.alpha = edgeAlpha;
         this.glowStroke_.thickness = 2;

         // Outer edge
         buildCirclePath(this.outerEdgePath_, ringOuter, camera);
         graphicsData.push(this.glowStroke_);
         graphicsData.push(this.outerEdgePath_);
         graphicsData.push(GraphicsUtil.END_STROKE);

         // Inner edge (skip if radius is basically 0)
         if (ringInner > 0.1)
         {
            buildCirclePath(this.innerEdgePath_, ringInner, camera);
            graphicsData.push(this.glowStroke_);
            graphicsData.push(this.innerEdgePath_);
            graphicsData.push(GraphicsUtil.END_STROKE);
         }
      }
   }
}
