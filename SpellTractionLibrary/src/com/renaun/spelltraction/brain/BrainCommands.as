package com.renaun.spelltraction.brain
{
public class BrainCommands
{
	
	//public static const USER_ADDED:int = 0x01; 			// A user has been added, have to have all user details
	public static const USER_LOCATION:int = 0x02;		//
	public static const ATTRACTOR_INFO:int = 0x03
	// Multiple with a length byte
	public static const USER_LOCATIONS:int = 0x0A;
	public static const USER_CHANGES:int = 0x0B;		// Client sends Server the details of the user
	
	// Single
	public static const USER_LETTERS:int = 0x06;
	
	//public static const USER_CONNECT:int = 0x10; 		// Connect to Server
	public static const ACCEPT_RESPONSE:int = 0x11; 	// Respond with the client id
	public static const USER_JOIN_GAME:int = 0x12;		// First time joining game
	
	
	public static const gridSize:int = 100;
	public static const colSize:int = 4;
	public static const rowSize:int = 3;

}
}