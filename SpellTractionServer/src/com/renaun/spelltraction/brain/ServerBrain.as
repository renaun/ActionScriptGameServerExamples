package com.renaun.spelltraction.brain
{
import avmplus.System;

import com.renaun.data.LinkedList;
import com.renaun.data.LinkedListNode;
import com.renaun.spelltraction.data.UserData;
import com.renaun.spelltraction.heart.IBeatable;
import com.renaun.spelltraction.nerves.ServerNerveSystem;

import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.getTimer;

public class ServerBrain implements IBeatable
{
	public function ServerBrain()
	{
		playersList = new LinkedList();
		playersHash = new Dictionary(true);
		dirtyList = new LinkedList();
		dirtyNodePool = new Array();
		
		gridLength = BrainCommands.colSize * BrainCommands.rowSize;
		for (var i:int = 0; i < gridLength; i++)
		{
			gridValues[i] = 0;
		}
		attractor = new UserData(1, -1, 0x111111);
		
		gameLetters = createGameLetterList();
		startTime = getTimer()/1000; // track seconds
	
		startMemory = getMem();		
		
		half = BrainCommands.gridSize/2;
		xGrid = BrainCommands.gridStartX + (BrainCommands.colSize * BrainCommands.gridSize/2);
		yGrid = (BrainCommands.gridStartY*2) + (BrainCommands.rowSize * BrainCommands.gridSize);
	}
	
	private var dirtyList:LinkedList;
	private var dirtyNodePool:Array;
	
	private var playersList:LinkedList;
	private var playersHash:Dictionary;
	private var serverNerveSystem:ServerNerveSystem;
	
	private var letters:Array = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
	
	// Grid Variables
	protected var gridValues:Array = [];
	protected var currentHighestGridPoint:int = -1;
	protected var highGridPointCount:int = 0;
	private var gridLength:int = 12;
	private var uniqueID:int = 2;
	protected var gameLetters:String;
	
	// Attractor
	protected var attractor:UserData;

	private var let:String;

	private var oldLet:String;
	private var isScoring:Boolean = false;

	private var scoredLetter:String;

	private var delayCount:int = 0;

	private var totalConnections:int = 0;

	private var startTime:Number;

	private var startMemory:Number;

	private var half:int;

	private var xGrid:int;

	private var yGrid:int;
	
	public function beat():void
	{
		//trace("Server Frame Beat");
		// Main Loop
		// - Create Delta Message Buffer
		// - New User Message
		var node:LinkedListNode = playersList.head;
		var u:UserData;
		var gridPoint:int = -1;
		while (node)
		{
			u = node.data;
			if (u.isDisconnected)
			{
				//trace("Send Disconnect Bytes");
				serverNerveSystem.sendUserChange(u, -1);
				u.isDisconnected = false;
				
				if (totalConnections > 0)
					totalConnections--;
				
				// Remove User
				playersList.remove(node);
				playersHash[u.appID] = null;
				delete playersHash[u.appID];
				continue;
			}
			else if (u.isNew)
			{
				serverNerveSystem.sendUserChange(u, 1);
				u.isNew = false;
			}
			
			if (u.isDirty)
			{
				serverNerveSystem.sendUserLocation(u);
				u.isDirty = false;
			}
			if (isScoring)
			{
				if (u.wordList.indexOf(oldLet) > -1)
				{
					let = getUniqueLetter(u.wordList);
					u.score++;
					serverNerveSystem.userScoreNewLetter(u.score, oldLet, let, u.appID);
					u.wordList = u.wordList.replace(oldLet, let);
				}
			}
			node = node.next;
		}
		isScoring = false;
		
		if (currentHighestGridPoint >= 0 && attractor.gridPoint == currentHighestGridPoint)
		{
			highGridPointCount++;
			
			// Score The Letter
			if (highGridPointCount > 20)
			{
				isScoring = true;
				oldLet = gameLetters.charAt(currentHighestGridPoint);
				scoredLetter = oldLet; 
				let = getUniqueLetter(gameLetters);
				
				//trace("BEAT:: oldLet: " + oldLet + " let: " + let);
				gameLetters = gameLetters.replace(gameLetters.charAt(currentHighestGridPoint), let);
				serverNerveSystem.scoreAndReplaceLetter(currentHighestGridPoint, let);
				highGridPointCount = 0;
				currentHighestGridPoint = -1;
				attractor.xPos = xGrid;
				attractor.yPos = yGrid;
				attractor.gridPoint = currentHighestGridPoint;
			}
		}
		
		// Send attractor location
		serverNerveSystem.sendUserLocation(attractor);
		// Send New User Message
		serverNerveSystem.sendUserChange(null, 1, true);
		
		// Send Delta Messages		
		serverNerveSystem.sendUserLocation(null, true);
		
		if (delayCount++ == 50)
		{
			delayCount = 0;
			
			// Send Stat Info	
			var currentHours:Number = ((getTimer()/1000) - startTime)/3600;
			serverNerveSystem.sendStats(totalConnections, currentHours, getMem(), startMemory);
		}
	}
	
	public function addNerve(serverNerveSystem:ServerNerveSystem):void
	{
		// Used to send messages
		this.serverNerveSystem = serverNerveSystem;		
	}
	
	public function removeUser(appID:int):void
	{
		//trace("Removing User1: " + appID + " - " + playersHash[appID]);
		if (!playersHash[appID])
			return;
		//trace("Removing User2: " + appID + " - " + playersHash[appID]);
		var u:UserData = playersHash[appID];
		if (u.gridPoint > -1)
		{
			gridValues[u.gridPoint]--;
			findMaxGridPoint();
		}
		u.isDisconnected = true;
	}
	
	public function addUser(appID:int, shape:int, color:int):void
	{
		if (playersHash[appID])
			return;
		
		//trace("Adding User: " + appID + " - " + playersHash[appID]);
		var u:UserData = new UserData(appID, shape, color);
		u.isNew = true;
		playersHash[appID] = u;
		playersList.add(new LinkedListNode(u));
		
		
		totalConnections++;
		
		// Send current game server grid letters
		serverNerveSystem.sendGameLetters(gameLetters, appID);
		
		// Send them a word list
		createWordList(u);
		//trace("Send WordList " + id);
		serverNerveSystem.sendUserLetters(u.wordList, appID);
		//trace("Send Attractor info");
		// Send the attractor's current cordinates
		serverNerveSystem.sendAttractorInfo(attractor, appID);
		
		// Send out all existing users
		var node:LinkedListNode = playersList.head;
		var gridPoint:int = -1;
		var buffer:ByteArray = new ByteArray();
		while (node)
		{
			u = node.data;
			if (u.appID != appID)
			{
				serverNerveSystem.writeNewUserBuffer(buffer, u, 1);
				serverNerveSystem.writeLocationBuffer(buffer, u);
			}
			node = node.next;
		}
		
		//trace("Adding User4: " + id + " - " + playersHash[id]);
		serverNerveSystem.writeBuffer(buffer, appID);
		//serverNerveSystem.sendUserChange(null, 1, true, appID);
		//serverNerveSystem.sendUserLocation(null, true, appID);
		
		// Send Stat Info	
		var currentHours:Number = ((getTimer()/1000) - startTime)/3600;
		serverNerveSystem.sendStats(totalConnections, currentHours, getMem(), startMemory, appID);
	}
	
	public function userLocation(id:int, xPos:int, yPos:int):void
	{
		var u:UserData = playersHash[id];
		if (!u)
			return;
		u.xPos = xPos;
		u.yPos = yPos;
		u.isDirty = true;
		
		// Check out GridPoint and find new one, adjust if needed
		var old:int = u.gridPoint;
		u.gridPoint = findGridPoint(u.xPos, u.yPos); // Not carry about users not actually being there
		if (old > -1)
			gridValues[old]--;
		if (u.gridPoint > -1)
			gridValues[u.gridPoint]++;
		//if (old < 0 || u.gridPoint < 0 || currentHighestGridPoint == -1)
		//{
			findMaxGridPoint();
		//}
	}
	
	private function findMaxGridPoint():void
	{
		var oldGridPoint:int = currentHighestGridPoint;
		var mxm:int = gridValues[0];
		var isNotMax:Boolean = false;
		var count:int = 0;
		for (var i:int=0; i < gridLength; i++) 
		{
			count += gridValues[i];
			if (gridValues[i] > mxm) 
			{
				mxm = gridValues[i];
				if (mxm > 1) // Has to have 2 or more
					currentHighestGridPoint = i;
			}
		}
		for (i=0; i < gridLength; i++) 
		{
			if (gridValues[i] == mxm && currentHighestGridPoint != i)
			{
				isNotMax = true;
				break;
			}
		}
		if (count < 2 || isNotMax || mxm <= 1)
			currentHighestGridPoint = -1;
		// reset grid count if it changes MAYBE move this to not change so much, check on in beat()?
		if (oldGridPoint != currentHighestGridPoint)
		{
			highGridPointCount = 0;
			if (currentHighestGridPoint >= 0)
			{
				attractor.xPos = ((currentHighestGridPoint%BrainCommands.colSize) * BrainCommands.gridSize)+half + BrainCommands.gridStartX;
				attractor.yPos = (int(currentHighestGridPoint/BrainCommands.colSize) * BrainCommands.gridSize)+half + BrainCommands.gridStartY;
				
				attractor.gridPoint = currentHighestGridPoint;
			}
			else
			{
				attractor.xPos = xGrid;
				attractor.yPos = yGrid;
				attractor.gridPoint = currentHighestGridPoint;
			}
		}
	}
	
	private function findGridPoint(xPos:int, yPos:int):int
	{
		return int(xPos/BrainCommands.gridSize) + (int(yPos/BrainCommands.gridSize)*BrainCommands.colSize);
	}
	
	
	
	protected function createWordList(user:UserData):void
	{
		var w:String = "";
		var len:int = 3;
		while (len-- > 0)
			w += getUniqueLetter(w);
		user.wordList = w;
	}
	
	/**
	 *	Inital game server letter board list 
	 */
	protected function createGameLetterList():String
	{
		var w:String = "";
		var len:int = BrainCommands.rowSize*BrainCommands.colSize;
		while (len-- > 0)
			w += getUniqueLetter(w);
		return w;
	}
	
	private function getUniqueLetter(list:String):String
	{
		var let:String = letters[int((Math.random()*10000)%25)];
		while (list.indexOf(let) > -1)
			let = letters[int((Math.random()*10000)%25)];
		return let;
	}
	
	// If this get bigger then a Short 2^16 there is a problem
	public function getNewID():int
	{
		// Hack for now to just flip over assuming there wont be more then 65k connections around
		if (uniqueID == 65530)
			uniqueID = 2;
		while (playersHash[uniqueID+1])
			uniqueID++;
		return uniqueID++;
	}
	
	
	
	private function getMem():Number
	{
		var vals:Array = System.popen("pmap -x " + System.pid + " | tail -1").split(" ");
		
		var k:int = 0;
		for (var i:int = 5; i < 25; i++)
		{
			if (vals[i] > 0)
				k++;
			if (k == 2)
				return vals[i] * 100;
		}
		return System.privateMemory;
	}
}
}
