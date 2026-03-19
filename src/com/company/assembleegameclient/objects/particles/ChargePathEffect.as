package com.company.assembleegameclient.objects.particles
{
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.util.RandomUtil;
   import com.company.util.GraphicsUtil;
   import flash.display.GraphicsPath;
   import flash.display.GraphicsPathCommand;
   import flash.display.GraphicsSolidFill;
   import flash.display.IGraphicsData;
   import flash.geom.Point;

   public class ChargePathEffect extends ParticleEffect
   {

      public var start_:Point;
      public var end_:Point;
      public var pathWidth_:Number;
      public var rectColor_:uint;
      public var duration_:int;
      public var timeLeft_:int;
      public var angle_:Number;
      public var length_:Number;

      // 4 corners in world space
      private var c0x_:Number;
      private var c0y_:Number;
      private var c1x_:Number;
      private var c1y_:Number;
      private var c2x_:Number;
      private var c2y_:Number;
      private var c3x_:Number;
      private var c3y_:Number;

      private var fill_:GraphicsSolidFill;
      private var path_:GraphicsPath;
      private var worldVerts_:Vector.<Number>;
      private var screenVerts_:Vector.<Number>;

      private var edgeSpawnTimer_:int;

      public function ChargePathEffect(startX:Number, startY:Number, endX:Number, endY:Number, width:Number, color:int, duration:int)
      {
         super();
         this.start_ = new Point(startX, startY);
         this.end_ = new Point(endX, endY);
         this.pathWidth_ = width;
         this.rectColor_ = color & 0xFFFFFF;
         this.duration_ = duration;
         this.timeLeft_ = duration;
         this.angle_ = Math.atan2(endY - startY, endX - startX);
         this.length_ = Point.distance(this.start_, this.end_);

         // Compute 4 corners of the rectangle in world coordinates
         var halfW:Number = width / 2;
         var perpAngle:Number = this.angle_ + Math.PI / 2;
         var cosP:Number = Math.cos(perpAngle);
         var sinP:Number = Math.sin(perpAngle);

         // Corner 0: start - half width (left side of start)
         this.c0x_ = startX + cosP * halfW;
         this.c0y_ = startY + sinP * halfW;
         // Corner 1: start + half width (right side of start)
         this.c1x_ = startX - cosP * halfW;
         this.c1y_ = startY - sinP * halfW;
         // Corner 2: end + half width (right side of end)
         this.c2x_ = endX - cosP * halfW;
         this.c2y_ = endY - sinP * halfW;
         // Corner 3: end - half width (left side of end)
         this.c3x_ = endX + cosP * halfW;
         this.c3y_ = endY + sinP * halfW;

         // 70% opacity red fill
         this.fill_ = new GraphicsSolidFill(this.rectColor_, 0.7);

         // Path with 4 vertices (MoveTo + 3 LineTo)
         this.path_ = new GraphicsPath(
            new Vector.<int>(),
            new Vector.<Number>()
         );
         this.path_.commands = new <int>[
            GraphicsPathCommand.MOVE_TO,
            GraphicsPathCommand.LINE_TO,
            GraphicsPathCommand.LINE_TO,
            GraphicsPathCommand.LINE_TO
         ];

         // World vertices: 4 corners at z=0 (ground plane)
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

         x_ = this.start_.x;
         y_ = this.start_.y;

         // Spawn edge particles periodically for a glowing border effect
         this.edgeSpawnTimer_ += dt;
         if (this.edgeSpawnTimer_ >= 80 && map_ != null)
         {
            this.edgeSpawnTimer_ = 0;
            spawnEdgeParticles();
         }

         return true;
      }

      private function spawnEdgeParticles() : void
      {
         var numEdge:int = 12;
         for (var i:int = 0; i < numEdge; i++)
         {
            var t:Number = Math.random();
            var side:int = int(Math.random() * 4);
            var px:Number;
            var py:Number;

            switch(side)
            {
               case 0: // top edge (c0 to c3)
                  px = c0x_ + (c3x_ - c0x_) * t;
                  py = c0y_ + (c3y_ - c0y_) * t;
                  break;
               case 1: // bottom edge (c1 to c2)
                  px = c1x_ + (c2x_ - c1x_) * t;
                  py = c1y_ + (c2y_ - c1y_) * t;
                  break;
               case 2: // left edge (c0 to c1)
                  px = c0x_ + (c1x_ - c0x_) * t;
                  py = c0y_ + (c1y_ - c0y_) * t;
                  break;
               case 3: // right edge (c3 to c2)
                  px = c3x_ + (c2x_ - c3x_) * t;
                  py = c3y_ + (c2y_ - c3y_) * t;
                  break;
            }

            var part:SparkParticle = new SparkParticle(
               80, this.rectColor_, 400, 0.5,
               RandomUtil.plusMinus(0.3),
               RandomUtil.plusMinus(0.3)
            );
            map_.addObj(part, px, py);
         }
      }

      override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : void
      {
         // Transform 4 corners from world to screen space
         this.worldVerts_.length = 0;
         this.worldVerts_.push(
            c0x_, c0y_, 0,
            c1x_, c1y_, 0,
            c2x_, c2y_, 0,
            c3x_, c3y_, 0
         );

         this.screenVerts_.length = 0;
         camera.wToS_.transformVectors(this.worldVerts_, this.screenVerts_);

         // Update path data with screen coordinates
         this.path_.data = new <Number>[
            screenVerts_[0], screenVerts_[1],
            screenVerts_[3], screenVerts_[4],
            screenVerts_[6], screenVerts_[7],
            screenVerts_[9], screenVerts_[10]
         ];

         // Pulsing opacity based on time remaining
         var pulse:Number = 0.5 + 0.2 * Math.sin(time * 0.008);
         this.fill_.alpha = pulse;

         graphicsData.push(this.fill_);
         graphicsData.push(this.path_);
         graphicsData.push(GraphicsUtil.END_FILL);
      }
   }
}
