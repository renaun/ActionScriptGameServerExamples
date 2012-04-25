package com.renaun.spelltraction.nerves
{
import com.renaun.spelltraction.brain.BrainCommands;
import com.renaun.spelltraction.brain.ServerBrain;
import com.renaun.spelltraction.data.UserData;

import flash.utils.ByteArray;
import flash.utils.Dictionary;

public class ServerNerveSystem implements IServerNerveSystem
{
	
	
	public function ServerNerveSystem(serverBrain:ServerBrain, dispatcher:INerveDispatcher)
	{
		this.serverBrain = serverBrain;
		this.dispatcher = dispatcher;
		this.dispatcher.setReceiveHandler(receiveHandler);
		if (!receiveBuffer)
			receiveBuffer = new ByteArray();
		if (!sendBuffer)
			sendBuffer = new ByteArray();
		if (!newUserBuffer)
			newUserBuffer = new ByteArray();
		if (!newLocationsBuffer)
			newLocationsBuffer = new ByteArray();
	}
	
	private var serverBrain:ServerBrain;
	private var dispatcher:INerveDispatcher;
	private var waitingForMoreBytes:Boolean = false;
	
	private var receiveBuffer:ByteArray;
	private var sendBuffer:ByteArray;
	private var newUserCount:int = 0;
	private var newUserBuffer:ByteArray;
	private var newLocationsCount:int = 0;
	private var newLocationsBuffer:ByteArray;
	
	
	private var clientAppIDs:Dictionary = new Dictionary(true);
	
	public function getNewID():int
	{
		return serverBrain.getNewID();
	}
	
	public function accept(fd:int, id:int = -1):void
	{
		if (id == -1)
			id = serverBrain.getNewID();
		clientAppIDs[fd] = id;
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.ACCEPT_RESPONSE);
		sendBuffer.writeShort(id);
		//trace("NerveSendAcceptMessage: " + id);
		dispatcher.sendMessage(sendBuffer, id);
	}
	
	public function disconnect(appID:int, fd:int):void
	{
		serverBrain.removeUser(appID);
		clientAppIDs[fd] = null;
		delete clientAppIDs[fd];
	}
	
	public function receiveHandler(fd:int, bytes:ByteArray):void
	{
		// look at bytes, have a game schema?
		bytes.position = 0;
		var commandType:int = bytes.readByte();
		var readable:Boolean = bytes.bytesAvailable > 0;
		var id:int = 0;
		//trace("RECEIVED: " + commandType);
		switch (commandType)
		{
			case BrainCommands.USER_JOIN_GAME:
				id = bytes.readUnsignedShort();
				if (clientAppIDs[fd] != id)
					id = clientAppIDs[fd];
				var shape:int = bytes.readByte();
				var color:int = bytes.readUnsignedInt();
				serverBrain.addUser(id, shape, color);
				break;
			case BrainCommands.USER_LOCATION:
				id = bytes.readUnsignedShort();
				if (clientAppIDs[fd] != id)
					id = clientAppIDs[fd];
				var xPos:int = bytes.readUnsignedShort();
				var yPos:int = bytes.readUnsignedShort();
				serverBrain.userLocation(id, xPos, yPos);
				break;
		}
		
	}
	
	public function sendGameLetters(gameLettersList:String, sendTo:int):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.GAME_LETTERS);
		sendBuffer.writeByte(gameLettersList.length);
		sendBuffer.writeUTFBytes(gameLettersList);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	public function sendUserLetters(wordList:String, sendTo:int):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.USER_LETTERS);
		sendBuffer.writeByte(wordList.length);
		sendBuffer.writeUTFBytes(wordList);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	public function sendAttractorInfo(attractor:UserData, sendTo:int):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.ATTRACTOR_INFO);
		sendBuffer.writeShort(attractor.appID);
		sendBuffer.writeByte(attractor.shape);
		sendBuffer.writeUnsignedInt(attractor.color);
		sendBuffer.writeShort(attractor.xPos);
		sendBuffer.writeShort(attractor.yPos);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	public function userScoreNewLetter(score:int, oldLetter:String, newLetter:String, sendTo:int):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.SCORE_NEW_LETTER);
		sendBuffer.writeShort(score);
		sendBuffer.writeUTFBytes(oldLetter+newLetter);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	public function scoreAndReplaceLetter(currentHighestGridPoint:int, let:String):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.SCORE_LETTER);
		sendBuffer.writeByte(currentHighestGridPoint);
		sendBuffer.writeUTFBytes(let);
		dispatcher.sendMessage(sendBuffer);
	}
	
	public function sendStats(totalConnections:int, upTime:Number, memory:Number, startMemory:Number, sendTo:int = -1):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.STATS_UPDATE);
		sendBuffer.writeInt(totalConnections);
		sendBuffer.writeFloat(upTime);
		sendBuffer.writeFloat(memory);
		sendBuffer.writeFloat(startMemory);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	//======= Batch Methods =======//
	
	public function sendUserChange(user:UserData, addDelete:int = 1, forceSend:Boolean = false, sendTo:int = -1):void
	{
		// Limit bytes sent
		if (forceSend)
		{
			if (newUserBuffer.length > 0)
			{
				trace("sendUserChange::forceSend - " + newUserBuffer.length);
				dispatcher.sendMessage(newUserBuffer, sendTo);
				newUserBuffer.clear();
			}
			if (forceSend)
				return;
		}
		writeNewUserBuffer(newUserBuffer, user, addDelete);
	}
	
	public function writeNewUserBuffer(buffer:ByteArray, user:UserData, addDelete:int = 1):void
	{
		// 1 byte - command
		// 1 byte - number of user changes
		// 1 short - id
		// 1 byte - Add = 1 , Delete = -1
		// 1 byte - shape
		// 1 unsigned int - color
		buffer.writeByte(BrainCommands.USER_CHANGES);
		buffer.writeShort(user.appID);
		buffer.writeByte(addDelete);
		buffer.writeByte(user.shape);
		buffer.writeUnsignedInt(user.color);
	}
	
	
	public function sendUserLocation(user:UserData, forceSend:Boolean = false, sendTo:int = -1):void
	{
		// Limit bytes sent
		if (forceSend)
		{
			if (newLocationsBuffer.length > 0)
			{
				dispatcher.sendMessage(newLocationsBuffer, sendTo);
				newLocationsBuffer.clear();
			}
			if (forceSend)
				return;
		}
		writeLocationBuffer(newLocationsBuffer, user);
	}	
	
	public function writeLocationBuffer(buffer:ByteArray, user:UserData):void
	{
		// 1 byte - command
		// 1 byte - number of user changes
		// 1 short - id
		// 1 short - xPos
		// 1 short - yPos
		buffer.writeByte(BrainCommands.USER_LOCATIONS);
		buffer.writeShort(user.appID);
		buffer.writeShort(user.xPos);
		buffer.writeShort(user.yPos);
	}
	
	public function writeBuffer(buffer:ByteArray, sendTo:int = 1):void
	{
		dispatcher.sendMessage(buffer, sendTo);
		buffer.clear();
	}
}
}