package kabam.rotmg.ui.commands
{
   import com.company.assembleegameclient.appengine.SavedCharacter;
   import com.company.assembleegameclient.ui.dialogs.Dialog;

   import flash.events.Event;

   import kabam.rotmg.account.core.Account;
   import kabam.rotmg.classes.model.CharacterClass;
   import kabam.rotmg.classes.model.ClassesModel;
   import kabam.rotmg.core.model.PlayerModel;
   import kabam.rotmg.core.signals.SetScreenWithValidDataSignal;
   import kabam.rotmg.dialogs.control.CloseDialogsSignal;
   import kabam.rotmg.dialogs.control.OpenDialogSignal;
   import kabam.rotmg.game.model.GameInitData;
   import kabam.rotmg.game.signals.PlayGameSignal;
   import kabam.rotmg.servers.api.ServerModel;
   import kabam.rotmg.ui.noservers.NoServersDialogFactory;

   public class EnterGameCommand
   {
      [Inject]
      public var account:Account;

      [Inject]
      public var model:PlayerModel;

      [Inject]
      public var setScreenWithValidData:SetScreenWithValidDataSignal;

      [Inject]
      public var playGame:PlayGameSignal;

      [Inject]
      public var openDialog:OpenDialogSignal;

      [Inject]
      public var closeDialogsSignal:CloseDialogsSignal;

      [Inject]
      public var servers:ServerModel;

      [Inject]
      public var noServersDialogFactory:NoServersDialogFactory;

      [Inject]
      public var classesModel:ClassesModel;

      public function EnterGameCommand()
      {
         super();
      }

      public function execute() : void
      {
         if(!this.servers.isServerAvailable())
         {
            this.showNoServersDialog();
            return;
         }

         if(this.model.getCharacterCount() > 0)
         {
            this.playExistingCharacter();
         }
         else
         {
            this.createWarrior();
         }
      }

      private function playExistingCharacter() : void
      {
         var character:SavedCharacter = this.model.getCharacterByIndex(0);
         this.model.currentCharId = character.charId();
         var characterClass:CharacterClass = this.classesModel.getCharacterClass(character.objectType());
         characterClass.setIsSelected(true);
         characterClass.skins.getSkin(character.skinType()).setIsSelected(true);
         var game:GameInitData = new GameInitData();
         game.createCharacter = false;
         game.charId = character.charId();
         game.isNewGame = true;
         this.playGame.dispatch(game);
      }

      private function createWarrior() : void
      {
         var charClass:CharacterClass = this.classesModel.getCharacterClass(0x0300);
         charClass.setIsSelected(true);
         var game:GameInitData = new GameInitData();
         game.createCharacter = true;
         game.charId = this.model.getNextCharId();
         game.keyTime = -1;
         game.isNewGame = true;
         this.playGame.dispatch(game);
      }

      private function close(_arg1:Event):void
      {
         this.closeDialogsSignal.dispatch();
      }

      private function showNoServersDialog():void
      {
         var dialog:Dialog = this.noServersDialogFactory.makeDialog();
         dialog.addEventListener(Dialog.BUTTON1_EVENT, this.close);
         this.openDialog.dispatch(dialog);
      }
   }
}
