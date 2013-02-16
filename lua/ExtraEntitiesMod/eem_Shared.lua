//________________________________
//
//   	NS2 CustomEntitesMod   
//	Made by JimWest 2012
//
//________________________________

Script.Load("lua/ModUtility.lua")

// Adjust values
Script.Load("lua/ExtraEntitiesMod/eem_Globals.lua")

// New functions
Script.Load("lua/ExtraEntitiesMod/eem_Utility.lua")

// Class overrides here
Script.Load("lua/ExtraEntitiesMod/eem_MovementModifier.lua")
Script.Load("lua/ExtraEntitiesMod/PathingUtility_Modded.lua")

// New classes
Script.Load("lua/ExtraEntitiesMod/TeleportTrigger.lua")
Script.Load("lua/ExtraEntitiesMod/FuncTrain.lua")
Script.Load("lua/ExtraEntitiesMod/FuncPlatform.lua")
Script.Load("lua/ExtraEntitiesMod/FuncTrainWaypoint.lua")
Script.Load("lua/ExtraEntitiesMod/FuncMoveable.lua")
Script.Load("lua/ExtraEntitiesMod/FuncDoor.lua")
Script.Load("lua/ExtraEntitiesMod/PushTrigger.lua")
Script.Load("lua/ExtraEntitiesMod/LogicTimer.lua")
Script.Load("lua/ExtraEntitiesMod/LogicMultiplier.lua")
Script.Load("lua/ExtraEntitiesMod/LogicWeldable.lua")
Script.Load("lua/ExtraEntitiesMod/LogicFunction.lua")
Script.Load("lua/ExtraEntitiesMod/LogicCounter.lua")
Script.Load("lua/ExtraEntitiesMod/LogicTrigger.lua")
Script.Load("lua/ExtraEntitiesMod/LogicLua.lua")
Script.Load("lua/ExtraEntitiesMod/LogicButton.lua")
Script.Load("lua/ExtraEntitiesMod/MapSettings.lua")
Script.Load("lua/ExtraEntitiesMod/NobuildArea.lua")


// disable the portal gun, was just 4 fun, maybe make it later better
// Script.Load("lua/ExtraEntitiesMod/PortalGunTeleport.lua")
//Script.Load("lua/ExtraEntitiesMod/PortalGun.lua")


if Client then
//	Script.Load("lua/ExtraEntitiesMod/eem_Player_Client.lua")
//	Script.Load("lua/ExtraEntitiesMod/Hud/GUIFuncTrain.lua")
end