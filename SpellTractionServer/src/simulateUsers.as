import C.errno.*;
import C.socket.MSG_WAITALL;
import C.stdlib.*;
import C.string.*;
import C.unistd.*;

import avmplus.Socket;
import avmplus.System;

import flash.utils.ByteArray;
import flash.utils.Dictionary;

Socket.prototype.record = function() {};

var sockets:Dictionary = new Dictionary();
var msg:String = "";
var i:int = 0;
var j:int = 0;
var total:int = 10;
var idStart:int = 5000;
trace("a: " + System.argv.length + " - " + System.argv[0]);
if (System.argv.length > 0 && System.argv[0])
{
	trace("Run " + System.argv[0] + " times " + " idStart: " + System.argv[1]);
	total = System.argv[0];
	idStart = System.argv[1];
}
function createSocket(appid:int):void
{
	socket = new Socket();
	//socket.blocking = false;
	//socket.connect("ec2-50-16-78-175.compute-1.amazonaws.com", 12122);
	socket.connect("ec2-107-20-128-129.compute-1.amazonaws.com", 12122);
	socket.appid = appid;
	sockets[socket] = socket;
}
function removeSocket(socket):void
{
	sockets[socket] = null;
	delete sockets[socket];
}

var err:int = -1;
// Create TOTAL sockets
while(j < total && j < 10000)
{
	createSocket(idStart+j);
	j++;
	if (Socket.lastError != err)
	{
		err = Socket.lastError;
		trace("["+socket.descriptor+"]Error: " + err + ": " + strerror(err));
	}
	sleep(800);
}
sleep(500);
var sendBuffer:ByteArray = new ByteArray();
for each (var socket:Socket in sockets)
{
	if (socket.valid)
	{
		sendBuffer.clear();
		sendBuffer.writeByte(0x12);
		sendBuffer.writeShort(socket.appid);
		sendBuffer.writeByte(1);
		sendBuffer.writeUnsignedInt((Math.random()*0xffffff)%0x55FFFF);
		
		sendBuffer.writeByte(0x02);
		sendBuffer.writeShort(socket.appid);
		sendBuffer.writeShort(int(Math.random()*400));
		sendBuffer.writeShort(int(Math.random()*300));
		try
		{
			socket.sendBinary(sendBuffer);
		}
		catch(error:*)
		{
			trace("SocketError: " + socket.descriptor + " - " + error.message);
			removeSocket(socket);
		}
		
		sleep(300);
	}
	else
	{
		trace("remove socket: " + socket.descriptor);
		removeSocket(socket);
	}
}
// Read all bytes
var data:ByteArray;
var k:int = 0;
var k2:int = 0;
while (1 == 1)
{
	k = 0;
	for each (var socket:Socket in sockets)
	{
		if (socket.valid)
		{
			try
			{
			
				if (socket.readable)
				{
					//data = socket.receiveBinaryAll();
					//trace("data: " + data.bytesAvailable);
					socket.receive()
					//trace("data: " + socket.receive());
				}
				if (((k+k2) % 8) == 0)
				{
					sendBuffer.clear();
					sendBuffer.writeByte(0x02);
					sendBuffer.writeShort(socket.appid);
					sendBuffer.writeShort(int(Math.random()*400));
					sendBuffer.writeShort(int(Math.random()*300));
					socket.sendBinary(sendBuffer);
				}
			}
			catch(error:*)
			{
				trace("SocketError: " + socket.descriptor + " - " + error.message);
				removeSocket(socket);
			}
		}
		else
		{
			trace("remove socket: " + socket.descriptor);
			removeSocket(socket);
		}
		k++;
	}
	k2++;
	if (k2 > 100000)
		k2 = 0;
	sleep(500);
}
