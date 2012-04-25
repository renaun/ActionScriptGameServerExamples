package com.renaun.spelltraction.data
{
public final class UserData
{
	public var appID:int;
	public var shape:int;
	public var color:int;
	public var wordList:String = "";
	public var score:int = 0;
	public var wordListLevel:int = 1;
	public var xPos:int = -100;
	public var yPos:int = -100;
	public var currentXPos:int = -100;
	public var currentYPos:int = -100;
	public var gridPoint:int = -1;
	
	public var isDisconnected:Boolean = false;
	public var isNew:Boolean = true;
	public var isDirty:Boolean = false;
	
	function UserData(appID:int, shape:int, color:int)
	{
		this.appID = appID;
		this.shape = shape;
		this.color = color;
	}
}
}