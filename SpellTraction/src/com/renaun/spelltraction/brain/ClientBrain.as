package com.renaun.spelltraction.brain
{
import assets.AssetBoard;
import assets.AssetGlass;
import assets.AssetOpponentMarker;
import assets.AssetPlayerMarker;
import assets.AssetServerMarker;
import assets.AssetTileBG;
import assets.FontSullivan;

import com.renaun.data.LinkedList;
import com.renaun.data.LinkedListNode;
import com.renaun.spelltraction.data.UserData;
import com.renaun.spelltraction.heart.IBeatable;
import com.renaun.spelltraction.nerves.ClientNerveSystem;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.Stage;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.utils.Dictionary;

import flashx.textLayout.formats.TextAlign;

public class ClientBrain implements IBeatable
{
	public function ClientBrain(stage:Stage)
	{
		changedPlayerList = new LinkedList();
		playersHash = new Dictionary(true);
		playersRenderObjectsHash = new Dictionary(true);
		renderArea = stage;
		// Background
		renderArea.addChild(new Bitmap(new AssetBoard()));
		
		gridArea = new Sprite();
		renderArea.addChild(gridArea);
		wordListContainer = new Sprite();
		renderArea.addChild(wordListContainer);
		players = new Sprite();
		renderArea.addChild(players);
		topplayers = new Sprite();
		renderArea.addChild(topplayers);
		glassLetters = new Sprite();
		renderArea.addChild(glassLetters);
		var glassBitmap:Bitmap = new Bitmap(new AssetGlass());
		glassLetters.addChild(glassBitmap);
		glassBitmap.x = -14;
		glassBitmap.y = -15;
		
		var format2:TextFormat = new TextFormat();
		format2.size = 20;
		//format2.bold = true;
		format2.color = 0xeeeeee;
		format2.font = "Verdana";
		format2.align = TextAlign.CENTER;
		
		
		txtScore = new TextField();
		txtScore.defaultTextFormat = format2;
		txtScore.width = BrainCommands.gridSize;
		txtScore.height = 96;
		txtScore.x = 525-9;
		txtScore.y = 390;
		txtScore.multiline = true;
		txtScore.selectable = false;
		txtScore.text = "Score:\n0";
		topplayers.addChild(txtScore);
		
		format2.size = 12;
		format2.align = TextAlign.RIGHT;
		txtStatus = new TextField();
		txtStatus.defaultTextFormat = format2;
		txtStatus.width = BrainCommands.gridSize*2;
		txtStatus.height = 96;
		txtStatus.x = 274;
		txtStatus.y = 412;
		txtStatus.multiline = true;
		txtStatus.selectable = false;
		txtStatus.text = "Total Connections: 0\nUptime: 0 Days 0 Hrs\nMem: 0MB (~0MB)";
		topplayers.addChild(txtStatus);
		
		// Trying Blitting
		
		canvasClearRect = new Rectangle(0, 0, BrainCommands.colSize*BrainCommands.gridSize, BrainCommands.rowSize*BrainCommands.gridSize);
		blitCanvas = new BitmapData(BrainCommands.colSize*BrainCommands.gridSize, BrainCommands.rowSize*BrainCommands.gridSize, true);
		var b2:Bitmap = new Bitmap(blitCanvas);
		b2.x = BrainCommands.gridStartX;
		b2.y = BrainCommands.gridStartY;
		topplayers.addChild(b2);
		
		// Grid
		// Tile Asset
		var tilebd:BitmapData = new AssetTileBG();
		var fontSullivan:FontSullivan;
		format = new TextFormat();
		format.size = 64;
		format.bold = true;
		format.color = 0xffffff;
		format.font = "FontSullivan";
		format.align = TextAlign.CENTER;
		
		//var g:Graphics = gridArea.graphics;
		//g.beginFill(0xaaaaaa, 0.9);
		//g.lineStyle(2, 0x333333);
		var xs:Number = 0;//((i%BrainCommands.colSize)*s)+1;
		var ys:Number = 0;//
		var s:int = BrainCommands.gridSize;
		for (var i:int = 0; i < BrainCommands.rowSize; i++)
		{
			for (var j:int = 0; j < BrainCommands.colSize; j++) 
			{
				xs = ((j)*s)+1;
				ys = (i)*s;
				//g.drawRect(xs, ys, s, s);	
				var t:TextField = new TextField();
				t.defaultTextFormat = format;
				t.selectable = false;
				t.embedFonts = true;
				t.width = s;
				t.text = " ";//letters[int(Math.random()*25)]+"";
				t.x = xs;
				t.y = ys + ((s-80)/2);
				var b:Bitmap = new Bitmap(tilebd);
				b.x = xs + 9;
				b.y = ys + 9;
				b.alpha = alphaOff;
				gridArea.addChild(b);
				glassLetters.addChild(t);
			}

		}
		
		for (var k:int = 0; k < 3; k++)
		{
			xs = 525;
			ys = k*s + 17;
			//g.drawRect(xs, ys, s, s);	
			t = new TextField();
			t.defaultTextFormat = format;
			t.selectable = false;
			t.embedFonts = true;
			t.width = s;
			t.text = " ";//letters[int(Math.random()*25)]+"";
			t.x = xs-9;
			t.y = ys+7;
			b = new Bitmap(tilebd);
			b.x = xs - 24;
			b.y = ys - 24;
			b.alpha = alphaOff;
			gridArea.addChild(b);
			wordListContainer.addChild(t);
		}
		
		//g.endFill();
		gridArea.x = BrainCommands.gridStartX;
		gridArea.y = BrainCommands.gridStartY;
		glassLetters.x = gridArea.x;
		glassLetters.y = gridArea.y;
	}
	private var format:TextFormat;
	private var changedPlayerList:LinkedList;
	private var playersHash:Dictionary;
	private var playersRenderObjectsHash:Dictionary;
	private var clientNerveSystem:ClientNerveSystem;
	
	public var clientUser:UserData;
	public var attractor:UserData;
	
	public var renderArea:Stage;
	public var gridArea:Sprite;
	public var players:Sprite;
	public var topplayers:Sprite;
	public var glassLetters:Sprite;
	
	public var txtScore:TextField;
	
	private var _connected:Boolean = false;
	public function get connected():Boolean
	{
		return _connected;
	}
	
	private var letters:Array = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

	
	private var p:Point = new Point(0, 0);
	private var rectAssetOpponent:Rectangle = new Rectangle(0, 0, 22, 22);
	
	private var beatCount:int = 0;
	public function beat():void
	{
		//trace("Client Beat");
		var node:LinkedListNode = changedPlayerList.head;
		var user:UserData;
		var render:Sprite;
		var deltaX:int = 0;
		var deltaY:int = 0;
		
		
		while (node)
		{
			user = node.data as UserData;
			
			node = node.next;
			
			render = playersRenderObjectsHash[user.appID];
			if (render)
			{
				//if(user.id > 1 && render.x != int((render.x+user.xPos)/2))
				
				if (render.x == user.xPos
					&& render.y == user.yPos)
					continue;
				
				//trace(user.appID + " - " + render.x+ " _ " + user.xPos);
				deltaX = (user.xPos-render.x)/4;
				render.x += (deltaX < 1 && deltaX > -1) ? user.xPos- render.x : deltaX;
				deltaY = (user.yPos-render.y)/4;
				render.y += (deltaY < 1 && deltaY > -1) ? user.yPos- render.y : deltaY;
			}
			
		}
		
		// BLIT
		blitCanvas.lock();
		blitCanvas.fillRect(canvasClearRect, 0x000000);
		
		for each (node in playersHash) 
		{
			user = node.data as UserData;
			if (user.shape < 3)
			{				
				//trace(user.appID + " - " + render.x+ " _ " + user.xPos);
				deltaX = (user.xPos-user.currentXPos)/4;
				user.currentXPos += (deltaX < 1 && deltaX > -1) ? user.xPos- user.currentXPos : deltaX;
				deltaY = (user.yPos-user.currentYPos)/4;
				user.currentYPos += (deltaY < 1 && deltaY > -1) ? user.yPos- user.currentYPos : deltaY;
				// BLIT do the blitting
				p.x = user.currentXPos-4 - BrainCommands.gridStartX;
				p.y = user.currentYPos-4 - BrainCommands.gridStartY;
				blitCanvas.copyPixels(assetOpponent, rectAssetOpponent, p, null, null, true);
			}
		}
		
		// BLIT
		blitCanvas.unlock();
		
		if (playersRenderObjectsHash && attractor)
		{
			render = playersRenderObjectsHash[attractor.appID];
			if (attractor.xPos == render.x
				&& attractor.yPos == render.y
				&& attractor.yPos < 3*117+24)
			{
				beatCount += direction;
				//trace("beatCount: " + beatCount);
				render.scaleX = 1 + (beatCount / 50);
				render.scaleY = 1 + (beatCount / 50);
				if (beatCount > 4 || beatCount < 0)
					direction *= -1;
			}
			else
			{
				render.scaleX = 1;
				render.scaleY = 1;
				beatCount = 0;
			}
		}
	}
	
	/**
	 * 	Called after person selects shape and color and wants to connect to the server.
	 */
	public function connect(ip:String, port:int, shape:int, color:int):void
	{
		clientUser = new UserData(-1, shape, color);
		clientNerveSystem.connect(ip, port);
	}
	
	/**
	 * 	
	 */
	public function accepted(id:int):void
	{
		clientUser.appID = id;
		clientUser.shape = 5;
		//trace("accepted::id: " + id);
		clientNerveSystem.joinGame(clientUser);
		
		playersHash[id] = new LinkedListNode(clientUser);
		playersRenderObjectsHash[id] = getRenderObject(clientUser.shape, clientUser.color, topplayers, 1);
		changeUserPosition(id, 0, 0);
	}
	
	/**
	 * 	The user moves their cirlce, keep it to only on grid locations
	 */
	public function move(xPos:int, yPos:int):void
	{
		if (xPos < BrainCommands.gridStartX || xPos > (BrainCommands.gridStartX + BrainCommands.gridSize*BrainCommands.colSize)
			|| yPos < BrainCommands.gridStartY
			|| yPos > (BrainCommands.gridStartY + BrainCommands.gridSize*BrainCommands.rowSize))
		{
			
			return;
		}
		trace("move:: ["+xPos+"/"+yPos+"]");
		clientUser.xPos = xPos;
		clientUser.yPos = yPos;
		clientNerveSystem.move(clientUser);
		
		changeUserPosition(clientUser.appID, xPos, yPos);
	}
	
	public function setWordList(wordList:String):void
	{
		if (clientUser)
			clientUser.wordList = wordList;
	
		for (var i:int = 0; i < wordList.length; i++) 
		{
			var t:TextField = wordListContainer.getChildAt(i) as TextField;
			if (t)
			{
				t.text = wordList.charAt(i);
			}
		}
	}
	
	public function scoreWordList(score:int, oldLetter:String, newLetter:String):void
	{
		if (!clientUser && clientUser.wordList.length > 2)
			return;
		clientUser.wordList = clientUser.wordList.replace(oldLetter, newLetter);
		var t:TextField = wordListContainer.getChildAt(clientUser.wordList.indexOf(newLetter)) as TextField;
		t.text = newLetter;
		clientUser.score = score;
		//trace("Scoring:: " + score);
		txtScore.text = "Score:\n" + clientUser.score;
	}
	
	public function setStats(totalConnections:int, upTime:Number, memory:Number, startMemory:Number):void
	{
		var up:String = Math.floor(upTime/24) + " Days " + Math.floor(upTime%24) + " Hrs";
		txtStatus.text = "Total Connections: "+totalConnections+"\nUptime: "+up+"\nMem: " + (memory/100000).toFixed(2) + "MB" +
			" (~" + ((memory-startMemory)/100000).toFixed(2) + "MB)";
	}
	
	/**
	 * 	Set the game letters from server
	 */
	public function setGameLetters(gameLetters:String):void
	{
		for (var i:int = 0; i < gameLetters.length; i++) 
		{
			var t:TextField = glassLetters.getChildAt(i+1) as TextField;
			if (t)
			{
				t.text = gameLetters.charAt(i);
			}
		}
	}
	
	/**
	 * 	Score based on grid position and letter
	 */
	public function scoreGameLetter(gridPosition:int, newLetter:String):void
	{
		if (gridPosition > glassLetters.numChildren)
			return;
		var t:TextField = glassLetters.getChildAt(gridPosition+1) as TextField;
		t.text = newLetter;
	}
	
	/**
	 * 	Comes from server once the user is connected to get their id
	 */
	public function serverConnectResponse(id:int):void
	{
		clientUser.appID = id;
		_connected = true;
	}
	
	public function addNerve(clientNerveSystem:ClientNerveSystem):void
	{
		// Used to send messages
		this.clientNerveSystem = clientNerveSystem;		
	}
	
	public function addAttractor(id:int, shape:int, color:int, xPos:int, yPos:int):void
	{
		if (playersHash[id])
			return;
		// hack for now
		shape = 3;
		attractor = new UserData(id, shape, color);
		attractor.xPos = xPos;
		attractor.yPos = yPos;
		attractor.currentXPos = xPos;
		attractor.currentYPos = yPos;
		
		playersHash[id] = new LinkedListNode(attractor);
		playersRenderObjectsHash[id] = getRenderObject(attractor.shape, attractor.color, topplayers, 1);
		changeUserPosition(id, xPos, yPos);
		
	}
	public function removeUser(id:int):void
	{
		trace("ClientBrain::removeUser: " + id);
		
		// BLIT 
		var sprite:Bitmap = playersRenderObjectsHash[id];
		if (sprite)
		{
			playersRenderObjectsHash[id] = null;
			delete playersRenderObjectsHash[id];
			
			//sprite.graphics.clear();
			sprite.x = -40;
			sprite.y = -40;
			sprites.push(sprite);
		}
			
		
		changedPlayerList.remove(playersHash[id]);
		playersHash[id] = null;
		delete playersHash[id];
	}
	public var kk:int = 0;
	public var kk2:int = 0;
	public function addUser(id:int, shape:int, color:int):void
	{
		if (id == clientUser.appID)
		{
			trace("Don't add yourself again");
			return;
		}
		if (playersHash[id])
		{
			trace("*****Player Already by that ID: " + id);
			return;
		}
		kk++;
		//if (kk < 3000)
		//	trace("===Player addding ID: " + id + " - " + kk);
		var u:UserData = new UserData(id, shape, color);
		playersHash[id] = new LinkedListNode(u);
		// BLIT playersRenderObjectsHash[id] = getRenderObject(u.shape, u.color, players);
	}
	
	public function changeUserPosition(id:int, x:int, y:int):void
	{
		var node:LinkedListNode = playersHash[id];
		if (!node)
		{
			
			//trace("changeUserPosition: " + id + " - " + node)
			return;
		}
		/* OLD Code to Fade grid sections - went with bouncing server marker instead
		if (attractor && (node.data as UserData).appID == attractor.appID)
		{
			//xGrid = ((currentHighestGridPoint%BrainCommands.colSize) * BrainCommands.gridSize)+half + BrainCommands.gridStartX;
			//yGrid = (int(currentHighestGridPoint/BrainCommands.colSize) * BrainCommands.gridSize)+half + BrainCommands.gridStartY;
			var colPos:int = Math.floor((x - BrainCommands.gridStartX)/BrainCommands.gridSize);
			colPos += Math.floor((y - BrainCommands.gridStartY)/BrainCommands.gridSize)*BrainCommands.colSize;
			if (attractorCurrentLocation)
				attractorCurrentLocation.alpha = alphaOff;
			if (colPos > 0 && colPos < BrainCommands.colSize * BrainCommands.rowSize)
				attractorCurrentLocation = gridArea.getChildAt(colPos) as Bitmap;
			if (attractorCurrentLocation)
				attractorCurrentLocation.alpha = 1;
		}
		*/
		//kk2++;
		//trace("changeUserPosition: " + x + "/"+ y);
		(node.data as UserData).xPos = x;
		(node.data as UserData).yPos = y;
		if (changedPlayerList.indexOf(node) == -1)
			changedPlayerList.add(node);
	}
	
	private var assetPlayer:BitmapData = new AssetPlayerMarker();
	private var assetServer:BitmapData = new AssetServerMarker();
	private var assetOpponent:BitmapData = new AssetOpponentMarker();
	private var sprites:Array = [];

	private var attractorCurrentLocation:Bitmap;

	private var alphaOff:Number = 1;

	private var wordListContainer:Sprite;

	private var txtStatus:TextField;

	private var direction:int = 1;

	private var blitCanvas:BitmapData;

	private var canvasClearRect:Rectangle;
	
	public function getRenderObject(shape:int, color:int, parent:Sprite, alpha:Number = 0.4):Sprite
	{
		var s:Sprite;
		if (sprites.length == 0)
		{
			s = new Sprite();
			s.addChild(new Bitmap());
			sprites.push(s);
		}
		s = sprites.pop();
		var b:Bitmap = s.getChildAt(0) as Bitmap;//s.graphics.clear();
		//s.graphics.beginFill(color, alpha);
		
		if (shape == 5)
		{
			b.bitmapData = assetPlayer;
			b.x = -16;
			b.y = -16;
			//s.graphics.lineStyle(2, 0x000000);
			//s.graphics.drawCircle(0, 0, 8);
		}
		else if (shape == 3)
		{
			b.bitmapData = assetServer;
			b.x = -16;
			b.y = -16;
			/*
			s.graphics.beginFill(0xffffff, alpha);
			s.graphics.lineStyle(2, 0x000000);
			s.graphics.drawRect(0, 0, 12, 12);
			s.graphics.beginFill(color, alpha);
			s.graphics.drawRect(3, 3, 6, 6);
			*/
		}
		else
		{
			//b.bitmapData = assetOpponent;
			//b.x = -11;
			//b.y = -11;
			//s.graphics.clear();
			//s.graphics.beginFill(color, alpha);
			//s.graphics.lineStyle(1, 0x000000, 0.7, true);
			//s.graphics.drawCircle(0, 0, 3);
		}
		
		//s.graphics.endFill();
		//s.cacheAsBitmap = true;
		parent.addChild(s);
		return s;
	}
}
}