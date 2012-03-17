package com.renaun.spelltraction.nerves
{
import flash.utils.ByteArray;

public interface IServerNerveSystem
{
	function accept(fd:int, id:int = -1):void;
	function receiveHandler(fd:int, msg:ByteArray):void;
}
}