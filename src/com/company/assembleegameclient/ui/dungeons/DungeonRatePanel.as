package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

import kabam.rotmg.account.core.Account;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.application.api.ApplicationSetup;

public class DungeonRatePanel extends Sprite
{
    private static const PANEL_W:int = 300;
    private static const PANEL_H:int = 200;

    private var data_:Object;
    private var browser_:DungeonBrowser;
    private var selectedDifficulty_:int = 0;
    private var liked_:Boolean = false;
    private var stars_:Vector.<SimpleText>;
    private var likeBtn_:TextButton;
    private var submitBtn_:TextButton;
    private var cancelBtn_:TextButton;

    public function DungeonRatePanel(data:Object, browser:DungeonBrowser)
    {
        super();
        this.data_ = data;
        this.browser_ = browser;

        // Background
        var g:Graphics = this.graphics;
        g.beginFill(0x1a1a2e, 1);
        g.lineStyle(2, 0x5a5a8c);
        g.drawRoundRect(0, 0, PANEL_W, PANEL_H, 10, 10);
        g.endFill();

        // Title
        var title:SimpleText = new SimpleText(18, 0xFFFFFF, false, PANEL_W, 0);
        title.setBold(true);
        title.htmlText = "<p align=\"center\">Rate: " + data.name + "</p>";
        title.filters = [new DropShadowFilter(0, 0, 0, 1, 2, 2)];
        title.updateMetrics();
        title.y = 12;
        addChild(title);

        // Difficulty label
        var diffLabel:SimpleText = new SimpleText(14, 0xCCCCCC, false, 0, 0);
        diffLabel.text = "Difficulty:";
        diffLabel.updateMetrics();
        diffLabel.x = 20;
        diffLabel.y = 50;
        addChild(diffLabel);

        // Stars
        this.stars_ = new Vector.<SimpleText>();
        for (var i:int = 0; i < 5; i++)
        {
            var star:SimpleText = new SimpleText(24, 0x555555, false, 0, 0);
            star.text = "\u2605";
            star.updateMetrics();
            star.x = 110 + i * 30;
            star.y = 44;
            star.addEventListener(MouseEvent.CLICK, this.makeStarHandler(i + 1));
            star.addEventListener(MouseEvent.MOUSE_OVER, this.makeStarHoverHandler(i + 1));
            star.addEventListener(MouseEvent.ROLL_OUT, this.onStarRollOut);
            addChild(star);
            this.stars_.push(star);
        }

        // Like label + button
        var likeLabel:SimpleText = new SimpleText(14, 0xCCCCCC, false, 0, 0);
        likeLabel.text = "Like:";
        likeLabel.updateMetrics();
        likeLabel.x = 20;
        likeLabel.y = 92;
        addChild(likeLabel);

        this.likeBtn_ = new TextButton(16, "\u2665 No", 80);
        this.likeBtn_.x = 110;
        this.likeBtn_.y = 88;
        this.likeBtn_.addEventListener(MouseEvent.CLICK, this.onLikeToggle);
        addChild(this.likeBtn_);

        // Submit
        this.submitBtn_ = new TextButton(14, "Submit", 80);
        this.submitBtn_.x = PANEL_W / 2 - 90;
        this.submitBtn_.y = PANEL_H - 45;
        this.submitBtn_.addEventListener(MouseEvent.CLICK, this.onSubmit);
        addChild(this.submitBtn_);

        // Cancel
        this.cancelBtn_ = new TextButton(14, "Cancel", 80);
        this.cancelBtn_.x = PANEL_W / 2 + 10;
        this.cancelBtn_.y = PANEL_H - 45;
        this.cancelBtn_.addEventListener(MouseEvent.CLICK, this.onCancel);
        addChild(this.cancelBtn_);
    }

    private function makeStarHandler(rating:int):Function
    {
        var self:DungeonRatePanel = this;
        return function(e:MouseEvent):void
        {
            self.selectedDifficulty_ = rating;
            self.updateStars(rating);
        };
    }

    private function makeStarHoverHandler(rating:int):Function
    {
        var self:DungeonRatePanel = this;
        return function(e:MouseEvent):void
        {
            self.updateStars(rating);
        };
    }

    private function onStarRollOut(e:MouseEvent):void
    {
        this.updateStars(this.selectedDifficulty_);
    }

    private function updateStars(highlight:int):void
    {
        for (var i:int = 0; i < 5; i++)
        {
            if (i < highlight)
                this.stars_[i].setColor(0xFFD700); // gold
            else
                this.stars_[i].setColor(0x555555); // grey
        }
    }

    private function onLikeToggle(e:MouseEvent):void
    {
        this.liked_ = !this.liked_;
        this.likeBtn_.setText(this.liked_ ? "\u2665 Yes" : "\u2665 No");
    }

    private function onSubmit(e:MouseEvent):void
    {
        if (this.selectedDifficulty_ == 0)
            return; // must select difficulty

        var setup:ApplicationSetup = StaticInjectorContext.getInjector().getInstance(ApplicationSetup);
        var account:Account = StaticInjectorContext.getInjector().getInstance(Account);
        var url:String = setup.getAppEngineUrl() + "/dungeons/rate";

        var vars:URLVariables = new URLVariables();
        vars.guid = account.getUserId();
        vars.password = account.getPassword();
        vars.dungeonName = this.data_.name;
        vars.difficulty = this.selectedDifficulty_;
        vars.liked = this.liked_;

        var request:URLRequest = new URLRequest(url);
        request.method = URLRequestMethod.POST;
        request.data = vars;

        var loader:URLLoader = new URLLoader();
        loader.addEventListener(Event.COMPLETE, this.onRateResponse);
        loader.addEventListener("ioError", this.onRateResponse);
        loader.load(request);
    }

    private function onRateResponse(e:Event):void
    {
        this.browser_.onRateComplete();
    }

    private function onCancel(e:MouseEvent):void
    {
        this.browser_.onRateComplete();
    }
}
}
