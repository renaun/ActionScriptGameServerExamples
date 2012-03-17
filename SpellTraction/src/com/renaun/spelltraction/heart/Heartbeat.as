package com.renaun.spelltraction.heart
{
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;

import org.osflash.signals.Signal;

/**
 *  Drives all the IBeatable classes for a game loop timer.
 */
public class Heartbeat
{
	/**
	 * 
	 * 	@param framesPerSecond framesPerSecond time in milliseconds for the beat of the heart.
	 */
	public function Heartbeat(fps:int = 60)
	{
		_framesPerSecond = fps;
		beatSignal = new Signal();
	}
	
	private var beatSignal:Signal;
	private var timer:Timer;
	
	private var _framesPerSecond:int = 60;
	
	public function get framesPerSecond():int
	{
		return _framesPerSecond;
	}

	public function set framesPerSecond(value:int):void
	{
		_framesPerSecond = value;
	}
	
	/**
	 * 	If the timer is coming from some where else this allows it to
	 *  plug into the Heartbeat way of things.
	 * 
	 *  This needs to be called before you added IBeatable objects.
	 */
	public function start(stage:Stage = null):void
	{
		if (stage)
		{
			stage.frameRate = framesPerSecond;
			stage.addEventListener(Event.ENTER_FRAME, enterHandler);
		}
		else
		{
			if (!timer)
			{
				timer = new Timer(1000/framesPerSecond);
				timer.addEventListener(TimerEvent.TIMER, timerHandler);
			}
			timer.delay = 1000/framesPerSecond;
			timer.start();
		}
	}
	
	protected function timerHandler(event:TimerEvent):void
	{
		beatSignal.dispatch();		
	}
	
	protected function enterHandler(event:Event):void
	{
		beatSignal.dispatch();
	}
	
	public function addBeatables(parts:IBeatable):void
	{
		beatSignal.add(parts.beat);
	}
	
	public function removeBeatables(parts:IBeatable):void
	{
		beatSignal.remove(parts.beat);
	}
	
	

}
}