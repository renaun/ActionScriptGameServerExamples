package com.renaun.spelltraction.heart
{
/**
 * 	Class implement this interface if they want to be controlled
 *  by the heart beat. In other words the game timer, game loop,
 *  the frame driver, etc...
 */
public interface IBeatable
{
	
	/**
	 * 	Function that is called by the Heartbeat class every X
	 *  number of milliseconds.
	 */
	function beat():void;
}
}