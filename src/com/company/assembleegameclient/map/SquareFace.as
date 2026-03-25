package com.company.assembleegameclient.map
{
import com.company.assembleegameclient.engine3d.Face3D;
import com.company.assembleegameclient.parameters.Parameters;
import flash.display.BitmapData;
import flash.display.IGraphicsData;
import kabam.rotmg.stage3D.GraphicsFillExtra;

public class SquareFace
{


   public var animate_:int;

   public var face_:Face3D;

   public var xOffset_:Number = 0;

   public var yOffset_:Number = 0;

   public var animateDx_:Number = 0;

   public var animateDy_:Number = 0;

   public function SquareFace(texture:BitmapData, vin:Vector.<Number>, xOffset:Number, yOffset:Number, animate:int, animateDx:Number, animateDy:Number)
   {
      super();
      this.face_ = new Face3D(texture,vin,Square.UVT.concat());
      this.xOffset_ = xOffset;
      this.yOffset_ = yOffset;
      if(this.xOffset_ != 0 || this.yOffset_ != 0)
      {
         this.face_.bitmapFill_.repeat = true;
      }
      this.animate_ = animate;
      if(this.animate_ != AnimateProperties.NO_ANIMATE)
      {
         this.face_.bitmapFill_.repeat = true;
      }
      this.animateDx_ = animateDx;
      this.animateDy_ = animateDy;
   }

   public function dispose() : void
   {
      this.face_.dispose();
      this.face_ = null;
   }

   public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : Boolean
   {
      var xOffset:Number = NaN;
      var yOffset:Number = NaN;
      if(this.animate_ != AnimateProperties.NO_ANIMATE)
      {
         switch(this.animate_)
         {
            case AnimateProperties.WAVE_ANIMATE:
               xOffset = this.xOffset_ + Math.sin(this.animateDx_ * time / 1000);
               yOffset = this.yOffset_ + Math.sin(this.animateDy_ * time / 1000);
               break;
            case AnimateProperties.FLOW_ANIMATE:
               xOffset = this.xOffset_ + this.animateDx_ * time / 1000;
               yOffset = this.yOffset_ + this.animateDy_ * time / 1000;
               // Keep UV offset in [0,1) range — texture repeats so visual is identical,
               // but prevents floating-point precision loss in the bitmap fill matrix
               // when time grows large (causes pixel-sampling artifacts on small textures)
               xOffset = xOffset - Math.floor(xOffset);
               yOffset = yOffset - Math.floor(yOffset);
         }
      }
      else
      {
         xOffset = this.xOffset_;
         yOffset = this.yOffset_;
      }
      if(Parameters.isGpuRender())
      {
         GraphicsFillExtra.setOffsetUV(this.face_.bitmapFill_,xOffset,yOffset);
         xOffset = yOffset = 0;
      }
      // Direct index assignment avoids Vector shrink/grow cycle (length=0 + push)
      // which can corrupt internal buffer after prolonged play with flow animation.
      // Also explicitly resets t-values (indices 2,5,8,11) that Utils3D.projectVectors modifies.
      var uvt:Vector.<Number> = this.face_.uvt_;
      uvt[0] = xOffset;
      uvt[1] = yOffset;
      uvt[2] = 0;
      uvt[3] = 1 + xOffset;
      uvt[4] = yOffset;
      uvt[5] = 0;
      uvt[6] = 1 + xOffset;
      uvt[7] = 1 + yOffset;
      uvt[8] = 0;
      uvt[9] = xOffset;
      uvt[10] = 1 + yOffset;
      uvt[11] = 0;
      this.face_.setUVT(uvt);
      return this.face_.draw(graphicsData,camera);
   }
}
}
