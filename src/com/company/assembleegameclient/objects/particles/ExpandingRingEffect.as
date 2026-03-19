package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.util.RandomUtil;
   import com.company.util.GraphicsUtil;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsPathCommand;
   import flash.display.GraphicsSolidFill;
   import flash.display.GraphicsStroke;
   import flash.display.IGraphicsData;
   import flash.display.LineScaleMode;
   import flash.display.CapsStyle;
   import flash.display.JointStyle;

   public class ExpandingRingEffect extends ParticleEffect
   {
      private static const NUM_SEGMENTS:int = 48;

      public var centerX_:Number;
      public var centerY_:Number;
      public var maxRadius_:Number;
      public var ringThickness_:Number;
      public var ringColor_:uint;
      public var duration_:int;
      public var timeLeft_:int;

      private var outerFill_:GraphicsSolidFill;
      private var innerFill_:GraphicsSolidFill;
      private var outerPath_:GraphicsPath;
      private var innerPath_:GraphicsPath;
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

         this.outerFill_ = new GraphicsSolidFill(this.ringColor_, 0.6);
         // Inner fill matches the ring color but we'll use it for the "hole" cutout
         // We'll draw the ring as an outer circle + inner circle path (donut shape)
         this.innerFill_ = new GraphicsSolidFill(0x000000, 0.0);

         this.outerPath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());
         this.innerPath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());

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
         var progress:Number = 1.0 - (this.timeLeft_ / Number(this.duration_));
         var currentRadius:Number = progress * this.maxRadius_;
         if (currentRadius < 0.5) return;

         var numParticles:int = 8;
         for (var i:int = 0; i < numParticles; i++)
         {
            var angle:Number = Math.random() * Math.PI * 2;
            var r:Number = currentRadius + (Math.random() - 0.5) * this.ringThickness_;
            var px:Number = this.centerX_ + Math.cos(angle) * r;
            var py:Number = this.centerY_ + Math.sin(angle) * r;

            var part:SparkParticle = new SparkParticle(
               60, this.ringColor_, 300, 0.4,
               RandomUtil.plusMinus(0.2),
               RandomUtil.plusMinus(0.2)
            );
            map_.addObj(part, px, py);
         }
      }

      override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : void
      {
         var progress:Number = 1.0 - (this.timeLeft_ / Number(this.duration_));
         var currentRadius:Number = progress * this.maxRadius_;
         if (currentRadius < 0.1) return;

         var outerR:Number = currentRadius + this.ringThickness_ / 2;
         var innerR:Number = currentRadius - this.ringThickness_ / 2;
         if (innerR < 0) innerR = 0;

         // Build donut shape: outer circle CW, then inner circle CCW (creates a ring)
         this.outerPath_.commands.length = 0;
         this.outerPath_.data.length = 0;

         var i:int;
         var angle:Number;
         var step:Number = (Math.PI * 2) / NUM_SEGMENTS;

         // Convert world coords to screen for outer circle
         this.worldVerts_.length = 0;
         for (i = 0; i <= NUM_SEGMENTS; i++)
         {
            angle = i * step;
            this.worldVerts_.push(
               this.centerX_ + Math.cos(angle) * outerR,
               this.centerY_ + Math.sin(angle) * outerR,
               0
            );
         }
         // Inner circle (reversed for cutout)
         for (i = NUM_SEGMENTS; i >= 0; i--)
         {
            angle = i * step;
            this.worldVerts_.push(
               this.centerX_ + Math.cos(angle) * innerR,
               this.centerY_ + Math.sin(angle) * innerR,
               0
            );
         }

         this.screenVerts_.length = 0;
         camera.wToS_.transformVectors(this.worldVerts_, this.screenVerts_);

         // Build path commands: outer ring MoveTo+LineTo, then inner ring MoveTo+LineTo
         var totalPoints:int = (NUM_SEGMENTS + 1) * 2;
         this.outerPath_.commands.length = 0;
         this.outerPath_.data.length = 0;

         // Outer circle
         this.outerPath_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.outerPath_.data.push(screenVerts_[0], screenVerts_[1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            this.outerPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.outerPath_.data.push(screenVerts_[i * 3], screenVerts_[i * 3 + 1]);
         }

         // Inner circle (reversed winding = cutout)
         var offset:int = (NUM_SEGMENTS + 1) * 3;
         this.outerPath_.commands.push(GraphicsPathCommand.MOVE_TO);
         this.outerPath_.data.push(screenVerts_[offset], screenVerts_[offset + 1]);
         for (i = 1; i <= NUM_SEGMENTS; i++)
         {
            this.outerPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.outerPath_.data.push(screenVerts_[offset + i * 3], screenVerts_[offset + i * 3 + 1]);
         }

         // Pulsing opacity
         var pulse:Number = 0.45 + 0.15 * Math.sin(time * 0.01);
         this.outerFill_.alpha = pulse;

         graphicsData.push(this.outerFill_);
         graphicsData.push(this.outerPath_);
         graphicsData.push(GraphicsUtil.END_FILL);
      }
   }
}
