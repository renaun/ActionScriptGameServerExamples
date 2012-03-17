package com.renaun.spelltraction.nerves
{
import flash.utils.ByteArray;

public interface INerveDispatcher
{
	function connect(ip:String, port:int):void;
	// If sentTo == -1 its broadcast if coming from server
	//		or if coming from client its send to server
	function sendMessage(msg:ByteArray, sendTo:int = -1):void; 
	function setReceiveHandler(receiveFunction:Function):void;
}
}