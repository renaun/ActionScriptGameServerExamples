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
	
	// Game Board Letters
	public static const GAME_LETTERS:int = 0x05;
	// Single
	public static const USER_LETTERS:int = 0x06;
	// Score
	public static const SCORE_LETTER:int = 0x07;
	public static const SCORE_NEW_LETTER:int = 0x08;
	
	// Stats
	public static const STATS_UPDATE:int = 0x09;
	
	//public static const USER_CONNECT:int = 0x10; 		// Connect to Server
	public static const ACCEPT_RESPONSE:int = 0x11; 	// Respond with the client id
	public static const USER_JOIN_GAME:int = 0x12;		// First time joining game
	
	
	public static const gridSize:int = 117;
	public static const gridStartX:int = 24;
	public static const gridStartY:int = 24;
	public static const colSize:int = 4;
	public static const rowSize:int = 3;

}
}