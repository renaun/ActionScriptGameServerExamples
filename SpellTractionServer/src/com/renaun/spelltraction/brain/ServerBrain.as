package com.renaun.spelltraction.brain
{
import com.renaun.data.LinkedList;
import com.renaun.data.LinkedListNode;
import com.renaun.spelltraction.data.UserData;
import com.renaun.spelltraction.heart.IBeatable;
import com.renaun.spelltraction.nerves.ServerNerveSystem;

import flash.utils.Dictionary;

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
	}
	
	private var dirtyList:LinkedList;
	private var dirtyNodePool:Array;
	
	private var playersList:LinkedList;
	private var playersHash:Dictionary;
	private var serverNerveSystem:ServerNerveSystem;
	
	private var letters:Array = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
	
	// Grid Variables
	protected var gridValues:Array = [];
	protected var currentHighestGridPoint:int = 0;
	protected var highGridPointCount:int = 0;
	private var gridLength:int;
	private var uniqueID:int = 2;
	
	// Attractor
	protected var attractor:UserData;
	
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
			// RANDOM TEST CODE
			/*
			if (u.id > 2 && int((Math.random() * 0xff) % 5) == 1)
			{
				
				u.xPos = Math.random()*400;
				u.yPos = Math.random()*300;
				u.isDirty = true;
			}
			*/
			// RANDOM STOP
			if (u.isNew)
			{
				serverNerveSystem.sendUserChange(u, 1);
				u.isNew = false;
			}
			if (u.isDisconnected)
			{
				trace("Send Disconnect Bytes");
				serverNerveSystem.sendUserChange(u, -1);
				u.isDisconnected = false;
				
				// Remove User
				playersList.remove(node);
				playersHash[u.appID] = null;
				delete playersHash[u.appID];
				continue;
			}
			if (u.isDirty)
			{
				serverNerveSystem.sendUserLocation(u);
				u.isDirty = false;
			}
			node = node.next;
		}
		
		// Determine Attraction State (how long has it been in that grid)
		
		// If attraction happens Then Score
		
		// Move Attraction Circle
		var half:int = BrainCommands.gridSize/2;
		var xGrid:int = ((currentHighestGridPoint%BrainCommands.colSize) * BrainCommands.gridSize)+half;
		var yGrid:int = (int(currentHighestGridPoint/BrainCommands.colSize) * BrainCommands.gridSize)+half;
		//trace("xGrid: " + xGrid+"/"+yGrid + " - " + currentHighestGridPoint);
		if (attractor.xPos != xGrid || attractor.yPos != yGrid)
		{
			attractor.xPos = xGrid;
			attractor.yPos = yGrid;
			serverNerveSystem.sendUserLocation(attractor);
		}
		attractor.gridPoint = findGridPoint(attractor.xPos, attractor.yPos);
		if (attractor.gridPoint == currentHighestGridPoint)
			highGridPointCount++;
		else
			highGridPointCount = 0;
		if (highGridPointCount > 20)
		{
			//if (currentHighestGridPoint > 0)
			//	trace("score grid: " + currentHighestGridPoint);
			highGridPointCount = 0;
		}
		// Send New User Message
		serverNerveSystem.sendUserChange(null, 1, true);
		
		// Send Delta Messages		
		serverNerveSystem.sendUserLocation(null, true);
	}
	
	public function addNerve(serverNerveSystem:ServerNerveSystem):void
	{
		// Used to send messages
		this.serverNerveSystem = serverNerveSystem;		
	}
	
	public function removeUser(appID:int):void
	{
		trace("Removing User1: " + appID + " - " + playersHash[appID]);
		if (!playersHash[appID])
			return;
		trace("Removing User2: " + appID + " - " + playersHash[appID]);
		var u:UserData = playersHash[appID];
		u.isDisconnected = true;
	}
	
	public function addUser(appID:int, shape:int, color:int):void
	{
		if (playersHash[appID])
			return;
		
		trace("Adding User: " + appID + " - " + playersHash[appID]);
		var u:UserData = new UserData(appID, shape, color);
		u.isNew = true;
		playersHash[appID] = u;
		playersList.add(new LinkedListNode(u));
		
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
		while (node)
		{
			u = node.data;
			if (u.appID != appID)
			{
				serverNerveSystem.sendUserChange(u, 1, false, appID);
			}
			node = node.next;
		}
		
		//trace("Adding User4: " + id + " - " + playersHash[id]);
		serverNerveSystem.sendUserChange(null, 1, true, appID);
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
		var oldGridPoint:int = currentHighestGridPoint;
		if (old > -1)
			gridValues[old]--;
		if (u.gridPoint > -1)
			gridValues[u.gridPoint]++;
		if (old < 0 || u.gridPoint < 0)
		{
			var mxm:int = gridValues[0];
			for (var i:int=0; i < BrainCommands.colSize*BrainCommands.rowSize; i++) 
			{
				if (gridValues[i] > mxm) 
				{
					mxm = gridValues[i];
					currentHighestGridPoint = i;
				}
			}
		}
		else if (gridValues[u.gridPoint] > gridValues[currentHighestGridPoint])
			currentHighestGridPoint = u.gridPoint;
		
		// reset grid count if it changes MAYBE move this to not change so much, check on in beat()?
		if (oldGridPoint != currentHighestGridPoint)
			highGridPointCount = 0;
		//trace("GP["+u.id+"]: " + u.gridPoint + " - " + currentHighestGridPoint);
	}
	
	private function findGridPoint(xPos:int, yPos:int):int
	{
		return int(xPos/BrainCommands.gridSize) + (int(yPos/BrainCommands.gridSize)*BrainCommands.colSize);
	}
	
	
	
	protected function createWordList(user:UserData):void
	{
		var i:int = 0;
		var w:String = "";
		while (i < user.wordListLevel && i < 6)
		{
			w += letters[int((Math.random()*10000)%25)];
			i++;
		}
		user.wordList = w;
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
}
}
