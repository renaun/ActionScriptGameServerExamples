package com.renaun.spelltraction.brain
{
import com.renaun.data.LinkedList;
import com.renaun.data.LinkedListNode;
import com.renaun.spelltraction.data.UserData;
import com.renaun.spelltraction.heart.IBeatable;
import com.renaun.spelltraction.nerves.ClientNerveSystem;
import com.renaun.spelltraction.nerves.LocalNerveDispatcher;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.Stage;
import flash.utils.Dictionary;

public class ClientBrain implements IBeatable
{
	public function ClientBrain(stage:Stage)
	{
		changedPlayerList = new LinkedList();
		playersHash = new Dictionary(true);
		playersRenderObjectsHash = new Dictionary(true);
		renderArea = stage;
		gridArea = new Sprite();
		renderArea.addChild(gridArea);
		players = new Sprite();
		renderArea.addChild(players);
		toplayer = new Sprite();
		renderArea.addChild(toplayer);
		var s:int = BrainCommands.gridSize;
		// Drag Grid
		var g:Graphics = gridArea.graphics;
		g.beginFill(0xaaaaaa, 0.9);
		g.lineStyle(2, 0x333333);
		for (var i:int = 0; i < BrainCommands.colSize*BrainCommands.rowSize; i++)
		{
			g.drawRect(((i%BrainCommands.colSize)*s)+1, (i%BrainCommands.rowSize)*s, s, s);	
		}
		g.endFill();
		
	}
	
	private var changedPlayerList:LinkedList;
	private var playersHash:Dictionary;
	private var playersRenderObjectsHash:Dictionary;
	private var clientNerveSystem:ClientNerveSystem;
	
	public var clientUser:UserData;
	public var attractor:UserData;
	
	public var renderArea:Stage;
	public var gridArea:Sprite;
	public var players:Sprite;
	public var toplayer:Sprite;
	
	private var _connected:Boolean = false;
	public function get connected():Boolean
	{
		return _connected;
	}
	
	private var letters:Array = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

	
	public function beat():void
	{
		//trace("Client Beat");
		var node:LinkedListNode = changedPlayerList.head;
		var user:UserData;
		var render:Sprite;
		while (node)
		{
			user = node.data as UserData;
			
			
			render = playersRenderObjectsHash[user.appID];
			//if(user.id > 1 && render.x != int((render.x+user.xPos)/2))
			//trace(user.id + " - " + render.x+ " _ " + user.xPos);
			render.x += int((user.xPos-render.x)/6);
			render.y += int((user.yPos-render.y)/6);
			node = node.next;
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
	
	public function accepted(id:int):void
	{
		clientUser.appID = id;
		clientUser.shape = 5;
		trace("id: " + id);
		clientNerveSystem.joinGame(clientUser);
		
		playersHash[id] = new LinkedListNode(clientUser);
		playersRenderObjectsHash[id] = getRenderObject(clientUser.shape, clientUser.color, toplayer, 1);
		changeUserPosition(id, 0, 0);
	}
	
	public function move(xPos:int, yPos:int):void
	{
		clientUser.xPos = xPos;
		clientUser.yPos = yPos;
		clientNerveSystem.move(clientUser);
		
		changeUserPosition(clientUser.appID, xPos, yPos);
	}
	
	public function setWordList(wordList:String):void
	{
		if (clientUser)
			clientUser.wordList = wordList;
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
		playersRenderObjectsHash[id] = getRenderObject(attractor.shape, attractor.color, toplayer, 1);
		changeUserPosition(id, xPos, yPos);
		
	}
	public function removeUser(id:int):void
	{
		trace("ClientBrain::removeUser: " + id);
		var sprite:Sprite = playersRenderObjectsHash[id];
		sprite.graphics.clear();
		if (sprite)
			sprites.push(sprite);
		playersRenderObjectsHash[id] = null;
		delete playersRenderObjectsHash[id];
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
			kk2++;
			return;
		}
		if (playersHash[id])
		{
			kk++;
			trace("id: " + id + " already created kk:" + kk);
			return;
		}
		kk2++;
		var u:UserData = new UserData(id, shape, color);
		playersHash[id] = new LinkedListNode(u);
		playersRenderObjectsHash[id] = getRenderObject(u.shape, u.color, players);
	}
	
	public function changeUserPosition(id:int, x:int, y:int):void
	{
		var node:LinkedListNode = playersHash[id];
		if (!node)
		{
			
			//trace("changeUserPosition: " + id + " - " + node)
			return;
		}
		(node.data as UserData).xPos = x;
		(node.data as UserData).yPos = y;
		if (changedPlayerList.indexOf(node) == -1)
			changedPlayerList.add(node);
	}
	
	private var sprites:Array = [];
	public function getRenderObject(shape:int, color:int, parent:Sprite, alpha:Number = 0.4):Sprite
	{
		var s:Sprite;
		if (sprites.length == 0)
			sprites.push(new Sprite());
		s = sprites.pop();
		s.graphics.clear();
		s.graphics.beginFill(color, alpha);
		
		if (shape == 5)
		{
			s.graphics.lineStyle(2, 0x000000);
			s.graphics.drawCircle(0, 0, 8);
		}
		else if (shape == 3)
		{
			s.graphics.beginFill(0xffffff, alpha);
			s.graphics.lineStyle(2, 0x000000);
			s.graphics.drawRect(0, 0, 12, 12);
			s.graphics.beginFill(color, alpha);
			s.graphics.drawRect(3, 3, 6, 6);
			
		}
		else
		{
			s.graphics.lineStyle(1, 0x000000, 0.7, true);
			s.graphics.drawCircle(0, 0, 3);
		}
		
		s.graphics.endFill();
		s.cacheAsBitmap = true;
		parent.addChild(s);
		return s;
	}
}
}