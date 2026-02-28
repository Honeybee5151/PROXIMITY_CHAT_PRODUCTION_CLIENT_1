package com.company.assembleegameclient.screens
{
   import flash.display.BitmapData;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.geom.Matrix;

   public class TitleIcons
   {
      // Color palette
      private static const BROWN:uint = 0x8B6914;
      private static const DARK_BROWN:uint = 0x5C4033;
      private static const BRONZE:uint = 0xCD7F32;
      private static const SILVER:uint = 0xC0C0C0;
      private static const DARK_SILVER:uint = 0x808890;
      private static const GOLD:uint = 0xDAA520;
      private static const BRIGHT_GOLD:uint = 0xFFD700;
      private static const ROYAL_PURPLE:uint = 0x7B2D8E;
      private static const CRIMSON:uint = 0xDC143C;
      private static const DARK_GREY:uint = 0x444444;
      private static const STEEL:uint = 0x71797E;

      public static function getIcon(rankIndex:int, size:int = 64) : BitmapData
      {
         var shape:Shape = new Shape();
         var g:Graphics = shape.graphics;

         switch(rankIndex)
         {
            case 0: drawKnecht(g, size); break;
            case 1: drawLandsknecht(g, size); break;
            case 2: drawRitter(g, size); break;
            case 3: drawEdler(g, size); break;
            case 4: drawFreiherr(g, size); break;
            case 5: drawReichsfreiherr(g, size); break;
            case 6: drawGraf(g, size); break;
            case 7: drawBurggraf(g, size); break;
            case 8: drawMarkgraf(g, size); break;
            case 9: drawPfalzgraf(g, size); break;
            case 10: drawLandgraf(g, size); break;
            case 11: drawHerzog(g, size); break;
            case 12: drawKurfurst(g, size); break;
            case 13: drawErzherzog(g, size); break;
            case 14: drawKonig(g, size); break;
            case 15: drawKaiser(g, size); break;
            default: drawKnecht(g, size); break;
         }

         var bd:BitmapData = new BitmapData(size, size, true, 0x00000000);
         bd.draw(shape);
         return bd;
      }

      // Rank 1: Knecht - Simple wooden shield (commoner)
      private static function drawKnecht(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.5;
         var h:Number = s * 0.6;

         // Shield body
         g.lineStyle(2, DARK_BROWN);
         g.beginFill(BROWN);
         g.moveTo(cx - w/2, cy - h/2 + 4);
         g.lineTo(cx + w/2, cy - h/2 + 4);
         g.lineTo(cx + w/2, cy + h/6);
         g.lineTo(cx, cy + h/2);
         g.lineTo(cx - w/2, cy + h/6);
         g.lineTo(cx - w/2, cy - h/2 + 4);
         g.endFill();

         // Horizontal plank line
         g.lineStyle(1, DARK_BROWN);
         g.moveTo(cx - w/2 + 2, cy);
         g.lineTo(cx + w/2 - 2, cy);

         // Vertical plank line
         g.moveTo(cx, cy - h/2 + 6);
         g.lineTo(cx, cy + h/2 - 4);
      }

      // Rank 2: Landsknecht - Shield with crossed pikes
      private static function drawLandsknecht(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;

         // Crossed pikes behind shield
         g.lineStyle(2, DARK_GREY);
         g.moveTo(cx - s*0.35, cy - s*0.35);
         g.lineTo(cx + s*0.35, cy + s*0.35);
         g.moveTo(cx + s*0.35, cy - s*0.35);
         g.lineTo(cx - s*0.35, cy + s*0.35);

         // Pike heads
         var phSize:Number = s * 0.06;
         g.lineStyle(1, STEEL);
         g.beginFill(STEEL);
         drawDiamond(g, cx - s*0.35, cy - s*0.35, phSize);
         drawDiamond(g, cx + s*0.35, cy - s*0.35, phSize);
         g.endFill();

         // Shield
         var w:Number = s * 0.4;
         var h:Number = s * 0.5;
         g.lineStyle(2, DARK_BROWN);
         g.beginFill(0x8B4513);
         g.moveTo(cx - w/2, cy - h/2 + 4);
         g.lineTo(cx + w/2, cy - h/2 + 4);
         g.lineTo(cx + w/2, cy + h/6);
         g.lineTo(cx, cy + h/2);
         g.lineTo(cx - w/2, cy + h/6);
         g.lineTo(cx - w/2, cy - h/2 + 4);
         g.endFill();

         // Cross on shield
         g.lineStyle(2, BRONZE);
         g.moveTo(cx, cy - h/4);
         g.lineTo(cx, cy + h/4);
         g.moveTo(cx - w/4, cy);
         g.lineTo(cx + w/4, cy);
      }

      // Rank 3: Ritter - Knight's shield with sword
      private static function drawRitter(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;

         // Sword behind shield
         g.lineStyle(2, SILVER);
         g.moveTo(cx, cy - s*0.4);
         g.lineTo(cx, cy + s*0.4);
         // Crossguard
         g.moveTo(cx - s*0.12, cy - s*0.12);
         g.lineTo(cx + s*0.12, cy - s*0.12);
         // Pommel
         g.lineStyle(0);
         g.beginFill(GOLD);
         g.drawCircle(cx, cy + s*0.4, s*0.03);
         g.endFill();

         // Shield
         var w:Number = s * 0.45;
         var h:Number = s * 0.55;
         g.lineStyle(2, DARK_SILVER);
         g.beginFill(STEEL);
         g.moveTo(cx - w/2, cy - h/2 + 6);
         g.lineTo(cx + w/2, cy - h/2 + 6);
         g.lineTo(cx + w/2, cy + h/6);
         g.lineTo(cx, cy + h/2);
         g.lineTo(cx - w/2, cy + h/6);
         g.lineTo(cx - w/2, cy - h/2 + 6);
         g.endFill();

         // Chevron on shield
         g.lineStyle(2, SILVER);
         g.moveTo(cx - w/3, cy);
         g.lineTo(cx, cy - h/5);
         g.lineTo(cx + w/3, cy);
      }

      // Rank 4: Edler - Simple 3-point coronet (bronze)
      private static function drawEdler(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         drawCoronet(g, cx, cy, s, 3, BRONZE, DARK_BROWN);
      }

      // Rank 5: Freiherr - 5-point coronet (bronze/silver)
      private static function drawFreiherr(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         drawCoronet(g, cx, cy, s, 5, BRONZE, DARK_BROWN);
         // Pearl accents on points
         drawPearls(g, cx, cy, s, 5);
      }

      // Rank 6: Reichsfreiherr - 5-point coronet with imperial cross
      private static function drawReichsfreiherr(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         drawCoronet(g, cx, cy, s, 5, SILVER, DARK_SILVER);
         drawPearls(g, cx, cy, s, 5);
         // Small cross on top center
         var crossY:Number = cy - s*0.22;
         g.lineStyle(2, GOLD);
         g.moveTo(cx, crossY - s*0.08);
         g.lineTo(cx, crossY + s*0.04);
         g.moveTo(cx - s*0.05, crossY - s*0.03);
         g.lineTo(cx + s*0.05, crossY - s*0.03);
      }

      // Rank 7: Graf - 7-point coronet (silver)
      private static function drawGraf(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         drawCoronet(g, cx, cy, s, 7, SILVER, DARK_SILVER);
         drawPearls(g, cx, cy, s, 7);
      }

      // Rank 8: Burggraf - Castle tower crown
      private static function drawBurggraf(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.6;
         var h:Number = s * 0.35;
         var baseY:Number = cy + h/4;
         var topY:Number = cy - h/2;

         // Crown band
         g.lineStyle(2, DARK_SILVER);
         g.beginFill(SILVER);
         g.drawRect(cx - w/2, baseY - h/3, w, h/3);
         g.endFill();

         // Three towers (castle battlement style)
         var towerW:Number = w * 0.2;
         var towerH:Number = h * 0.8;
         // Left tower
         g.beginFill(SILVER);
         g.drawRect(cx - w/2 + w*0.05, topY, towerW, towerH);
         g.endFill();
         // Center tower (taller)
         g.beginFill(SILVER);
         g.drawRect(cx - towerW/2, topY - h*0.2, towerW, towerH + h*0.2);
         g.endFill();
         // Right tower
         g.beginFill(SILVER);
         g.drawRect(cx + w/2 - w*0.05 - towerW, topY, towerW, towerH);
         g.endFill();

         // Merlon details on towers
         g.lineStyle(1, DARK_SILVER);
         var mSize:Number = towerW * 0.35;
         // Center tower merlons
         g.beginFill(DARK_SILVER);
         g.drawRect(cx - mSize/2, topY - h*0.2, mSize, mSize);
         g.endFill();

         // Jewel on band
         g.lineStyle(0);
         g.beginFill(GOLD);
         g.drawCircle(cx, baseY - h/6, s*0.03);
         g.endFill();
      }

      // Rank 9: Markgraf - Crown with pointed peaks (gold)
      private static function drawMarkgraf(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         drawCoronet(g, cx, cy, s, 5, GOLD, BRONZE);
         drawPearls(g, cx, cy, s, 5);

         // Extra leaf/fleur details between points
         g.lineStyle(1, BRIGHT_GOLD);
         g.beginFill(BRIGHT_GOLD);
         var bandY:Number = cy + s*0.04;
         g.drawRect(cx - s*0.28, bandY, s*0.56, s*0.04);
         g.endFill();
      }

      // Rank 10: Pfalzgraf - Pointed arch crown (gold)
      private static function drawPfalzgraf(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.6;
         var h:Number = s * 0.4;
         var baseY:Number = cy + h/3;

         // Crown band
         g.lineStyle(2, BRONZE);
         g.beginFill(GOLD);
         g.drawRect(cx - w/2, baseY - h/4, w, h/4);
         g.endFill();

         // Three pointed arches
         g.lineStyle(2, BRONZE);
         g.beginFill(GOLD);
         g.moveTo(cx - w/2, baseY - h/4);
         g.lineTo(cx - w/3, cy - h/2);
         g.lineTo(cx - w/6, baseY - h/4);
         g.lineTo(cx, cy - h/2 - s*0.06);
         g.lineTo(cx + w/6, baseY - h/4);
         g.lineTo(cx + w/3, cy - h/2);
         g.lineTo(cx + w/2, baseY - h/4);
         g.endFill();

         // Pearls on arch tips
         g.lineStyle(0);
         g.beginFill(0xFFFFFF);
         g.drawCircle(cx - w/3, cy - h/2, s*0.025);
         g.drawCircle(cx, cy - h/2 - s*0.06, s*0.03);
         g.drawCircle(cx + w/3, cy - h/2, s*0.025);
         g.endFill();
      }

      // Rank 11: Landgraf - Crown with strawberry leaves
      private static function drawLandgraf(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.6;
         var h:Number = s * 0.35;
         var baseY:Number = cy + h/3;

         // Crown band with gems
         g.lineStyle(2, BRONZE);
         g.beginFill(GOLD);
         g.drawRect(cx - w/2, baseY - h/4, w, h/4);
         g.endFill();

         // Gem band
         g.lineStyle(0);
         g.beginFill(CRIMSON);
         g.drawRect(cx - w/2 + 3, baseY - h/6, w - 6, h/8);
         g.endFill();

         // Strawberry leaves (3 rounded triangles)
         g.lineStyle(1, BRONZE);
         g.beginFill(GOLD);
         drawLeaf(g, cx - w/3, baseY - h/4, cy - h/2, s*0.08);
         drawLeaf(g, cx, baseY - h/4, cy - h/2 - s*0.06, s*0.09);
         drawLeaf(g, cx + w/3, baseY - h/4, cy - h/2, s*0.08);
         g.endFill();
      }

      // Rank 12: Herzog - Ducal crown (gold with ermine)
      private static function drawHerzog(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.6;
         var h:Number = s * 0.4;
         var baseY:Number = cy + h/3;

         // Ermine cap (white dome)
         g.lineStyle(0);
         g.beginFill(0xF0E8D0);
         g.drawEllipse(cx - w*0.35, cy - h*0.3, w*0.7, h*0.6);
         g.endFill();

         // Crown band
         g.lineStyle(2, BRONZE);
         g.beginFill(GOLD);
         g.drawRect(cx - w/2, baseY - h/4, w, h/3);
         g.endFill();

         // Gem settings
         g.lineStyle(0);
         g.beginFill(CRIMSON);
         g.drawCircle(cx - w/4, baseY - h/8, s*0.03);
         g.drawCircle(cx, baseY - h/8, s*0.035);
         g.drawCircle(cx + w/4, baseY - h/8, s*0.03);
         g.endFill();

         // Leaf points on top
         g.lineStyle(1, BRONZE);
         g.beginFill(GOLD);
         drawLeaf(g, cx - w/3, baseY - h/4, cy - h/3, s*0.07);
         drawLeaf(g, cx - w/6, baseY - h/4, cy - h/3 - s*0.04, s*0.07);
         drawLeaf(g, cx, baseY - h/4, cy - h/3 - s*0.06, s*0.08);
         drawLeaf(g, cx + w/6, baseY - h/4, cy - h/3 - s*0.04, s*0.07);
         drawLeaf(g, cx + w/3, baseY - h/4, cy - h/3, s*0.07);
         g.endFill();
      }

      // Rank 13: Kurfurst - Electoral bonnet (crimson cap with ermine)
      private static function drawKurfurst(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.55;
         var h:Number = s * 0.45;
         var baseY:Number = cy + h/3;

         // Ermine band (white with black spots)
         g.lineStyle(1, DARK_GREY);
         g.beginFill(0xF5F5F0);
         g.drawRect(cx - w/2, baseY - h/5, w, h/4);
         g.endFill();
         // Ermine spots
         g.lineStyle(0);
         g.beginFill(0x111111);
         g.drawCircle(cx - w/3, baseY - h/10, s*0.015);
         g.drawCircle(cx - w/6, baseY - h/10, s*0.015);
         g.drawCircle(cx, baseY - h/10, s*0.015);
         g.drawCircle(cx + w/6, baseY - h/10, s*0.015);
         g.drawCircle(cx + w/3, baseY - h/10, s*0.015);
         g.endFill();

         // Crimson cap
         g.lineStyle(1, 0x8B0000);
         g.beginFill(CRIMSON);
         g.moveTo(cx - w/2, baseY - h/5);
         g.curveTo(cx - w/2, cy - h/2, cx, cy - h/2 - s*0.05);
         g.curveTo(cx + w/2, cy - h/2, cx + w/2, baseY - h/5);
         g.endFill();

         // Gold orb on top
         g.lineStyle(1, BRONZE);
         g.beginFill(BRIGHT_GOLD);
         g.drawCircle(cx, cy - h/2 - s*0.05, s*0.04);
         g.endFill();

         // Gold cross on orb
         g.lineStyle(1.5, GOLD);
         var orbY:Number = cy - h/2 - s*0.05;
         g.moveTo(cx, orbY - s*0.07);
         g.lineTo(cx, orbY - s*0.02);
         g.moveTo(cx - s*0.025, orbY - s*0.05);
         g.lineTo(cx + s*0.025, orbY - s*0.05);
      }

      // Rank 14: Erzherzog - Arched crown (single arch)
      private static function drawErzherzog(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.6;
         var h:Number = s * 0.4;
         var baseY:Number = cy + h/3;

         // Crown band
         g.lineStyle(2, BRONZE);
         g.beginFill(GOLD);
         g.drawRect(cx - w/2, baseY - h/4, w, h/3);
         g.endFill();

         // Gem band
         g.lineStyle(0);
         g.beginFill(ROYAL_PURPLE);
         g.drawRect(cx - w/2 + 3, baseY - h/6, w - 6, h/8);
         g.endFill();

         // Fleur points
         g.lineStyle(1, BRONZE);
         g.beginFill(GOLD);
         drawLeaf(g, cx - w/3, baseY - h/4, cy - h/3, s*0.06);
         drawLeaf(g, cx, baseY - h/4, cy - h/3 - s*0.02, s*0.07);
         drawLeaf(g, cx + w/3, baseY - h/4, cy - h/3, s*0.06);
         g.endFill();

         // Single arch
         g.lineStyle(2.5, GOLD);
         g.moveTo(cx - w/2 + 2, baseY - h/4);
         g.curveTo(cx, cy - h/2 - s*0.15, cx + w/2 - 2, baseY - h/4);

         // Orb and cross on top of arch
         var archTopY:Number = cy - h/2 - s*0.08;
         g.lineStyle(1, BRONZE);
         g.beginFill(BRIGHT_GOLD);
         g.drawCircle(cx, archTopY, s*0.035);
         g.endFill();
         g.lineStyle(1.5, GOLD);
         g.moveTo(cx, archTopY - s*0.065);
         g.lineTo(cx, archTopY - s*0.02);
         g.moveTo(cx - s*0.02, archTopY - s*0.045);
         g.lineTo(cx + s*0.02, archTopY - s*0.045);
      }

      // Rank 15: Konig - Royal crown (two crossing arches)
      private static function drawKonig(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2;
         var w:Number = s * 0.6;
         var h:Number = s * 0.4;
         var baseY:Number = cy + h/3;

         // Crown band
         g.lineStyle(2, BRONZE);
         g.beginFill(GOLD);
         g.drawRect(cx - w/2, baseY - h/4, w, h/3);
         g.endFill();

         // Gem band
         g.lineStyle(0);
         g.beginFill(ROYAL_PURPLE);
         g.drawRect(cx - w/2 + 3, baseY - h/6, w - 6, h/8);
         g.endFill();

         // Fleur points
         g.lineStyle(1, BRONZE);
         g.beginFill(GOLD);
         drawLeaf(g, cx - w*0.4, baseY - h/4, cy - h/3, s*0.06);
         drawLeaf(g, cx - w*0.15, baseY - h/4, cy - h/3 - s*0.03, s*0.06);
         drawLeaf(g, cx + w*0.15, baseY - h/4, cy - h/3 - s*0.03, s*0.06);
         drawLeaf(g, cx + w*0.4, baseY - h/4, cy - h/3, s*0.06);
         g.endFill();

         // Two crossing arches
         g.lineStyle(2.5, BRIGHT_GOLD);
         g.moveTo(cx - w/2 + 2, baseY - h/4);
         g.curveTo(cx, cy - h/2 - s*0.18, cx + w/2 - 2, baseY - h/4);
         g.moveTo(cx - w/4, baseY - h/4);
         g.curveTo(cx, cy - h/2 - s*0.15, cx + w/4, baseY - h/4);

         // Orb and cross
         var archTopY:Number = cy - h/2 - s*0.1;
         g.lineStyle(1, BRONZE);
         g.beginFill(BRIGHT_GOLD);
         g.drawCircle(cx, archTopY, s*0.04);
         g.endFill();
         g.lineStyle(2, BRIGHT_GOLD);
         g.moveTo(cx, archTopY - s*0.075);
         g.lineTo(cx, archTopY - s*0.02);
         g.moveTo(cx - s*0.025, archTopY - s*0.05);
         g.lineTo(cx + s*0.025, archTopY - s*0.05);
      }

      // Rank 16: Kaiser - Imperial crown with double-headed eagle
      private static function drawKaiser(g:Graphics, s:int) : void
      {
         var cx:Number = s / 2;
         var cy:Number = s / 2 + s*0.05;
         var w:Number = s * 0.65;
         var h:Number = s * 0.4;
         var baseY:Number = cy + h/3;

         // Crown band (wider, more ornate)
         g.lineStyle(2, BRONZE);
         g.beginFill(BRIGHT_GOLD);
         g.drawRect(cx - w/2, baseY - h/4, w, h/3);
         g.endFill();

         // Purple velvet band
         g.lineStyle(0);
         g.beginFill(ROYAL_PURPLE);
         g.drawRect(cx - w/2 + 3, baseY - h/6, w - 6, h/7);
         g.endFill();

         // Crimson gems
         g.beginFill(CRIMSON);
         g.drawCircle(cx - w/4, baseY - h/8, s*0.03);
         g.drawCircle(cx, baseY - h/8, s*0.035);
         g.drawCircle(cx + w/4, baseY - h/8, s*0.03);
         g.endFill();

         // Ornate fleur points
         g.lineStyle(1, BRONZE);
         g.beginFill(BRIGHT_GOLD);
         drawLeaf(g, cx - w*0.4, baseY - h/4, cy - h/3, s*0.06);
         drawLeaf(g, cx - w*0.2, baseY - h/4, cy - h/3 - s*0.04, s*0.07);
         drawLeaf(g, cx, baseY - h/4, cy - h/3 - s*0.06, s*0.08);
         drawLeaf(g, cx + w*0.2, baseY - h/4, cy - h/3 - s*0.04, s*0.07);
         drawLeaf(g, cx + w*0.4, baseY - h/4, cy - h/3, s*0.06);
         g.endFill();

         // Single arch (HRE imperial crown has one arch)
         g.lineStyle(3, BRIGHT_GOLD);
         g.moveTo(cx - w/2 + 2, baseY - h/4);
         g.curveTo(cx, cy - h/2 - s*0.2, cx + w/2 - 2, baseY - h/4);

         // Orb and cross on top
         var archTopY:Number = cy - h/2 - s*0.12;
         g.lineStyle(1, BRONZE);
         g.beginFill(BRIGHT_GOLD);
         g.drawCircle(cx, archTopY, s*0.04);
         g.endFill();
         g.lineStyle(2, BRIGHT_GOLD);
         g.moveTo(cx, archTopY - s*0.08);
         g.lineTo(cx, archTopY - s*0.02);
         g.moveTo(cx - s*0.03, archTopY - s*0.055);
         g.lineTo(cx + s*0.03, archTopY - s*0.055);

         // Small eagle silhouette on the band
         g.lineStyle(1, 0x111111);
         var eagleY:Number = baseY - h/4 + h/6;
         // Eagle body
         g.beginFill(0x111111);
         drawDiamond(g, cx, eagleY, s*0.04);
         g.endFill();
         // Wings (simple V shapes)
         g.moveTo(cx - s*0.06, eagleY - s*0.04);
         g.lineTo(cx - s*0.02, eagleY);
         g.moveTo(cx + s*0.06, eagleY - s*0.04);
         g.lineTo(cx + s*0.02, eagleY);
      }

      // Helper: draw a coronet with N points
      private static function drawCoronet(g:Graphics, cx:Number, cy:Number, s:Number, points:int, fillColor:uint, lineColor:uint) : void
      {
         var w:Number = s * 0.6;
         var h:Number = s * 0.3;
         var baseY:Number = cy + h/3;
         var pointH:Number = s * 0.18;

         // Band
         g.lineStyle(2, lineColor);
         g.beginFill(fillColor);
         g.drawRect(cx - w/2, baseY - h/3, w, h/2);
         g.endFill();

         // Points
         var spacing:Number = w / (points + 1);
         for (var i:int = 1; i <= points; i++)
         {
            var px:Number = cx - w/2 + spacing * i;
            g.lineStyle(2, lineColor);
            g.beginFill(fillColor);
            g.moveTo(px - s*0.03, baseY - h/3);
            g.lineTo(px, baseY - h/3 - pointH);
            g.lineTo(px + s*0.03, baseY - h/3);
            g.endFill();
         }
      }

      // Helper: draw pearls on coronet points
      private static function drawPearls(g:Graphics, cx:Number, cy:Number, s:Number, points:int) : void
      {
         var w:Number = s * 0.6;
         var h:Number = s * 0.3;
         var baseY:Number = cy + h/3;
         var pointH:Number = s * 0.18;
         var spacing:Number = w / (points + 1);

         g.lineStyle(0);
         g.beginFill(0xFFFFFF);
         for (var i:int = 1; i <= points; i++)
         {
            var px:Number = cx - w/2 + spacing * i;
            g.drawCircle(px, baseY - h/3 - pointH, s*0.025);
         }
         g.endFill();
      }

      // Helper: draw a diamond shape
      private static function drawDiamond(g:Graphics, cx:Number, cy:Number, size:Number) : void
      {
         g.moveTo(cx, cy - size);
         g.lineTo(cx + size, cy);
         g.lineTo(cx, cy + size);
         g.lineTo(cx - size, cy);
         g.lineTo(cx, cy - size);
      }

      // Helper: draw a leaf/fleur shape (rounded triangle pointing up)
      private static function drawLeaf(g:Graphics, baseX:Number, baseY:Number, tipY:Number, width:Number) : void
      {
         g.moveTo(baseX - width/2, baseY);
         g.curveTo(baseX - width/3, tipY + (baseY - tipY)*0.3, baseX, tipY);
         g.curveTo(baseX + width/3, tipY + (baseY - tipY)*0.3, baseX + width/2, baseY);
      }
   }
}
