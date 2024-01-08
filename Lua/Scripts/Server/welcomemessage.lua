if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

local gamemodemessage = [[
Welcome to No Man's Land!

Description:
No Man's Land is a WW1 theme PvP gamemode where two teams duke it out in a variety of locations and fashions, from trench warfare to urban chaos.
However, what separates it from most other PvP gamemodes is its POW mechanics; prisoners can be taken & converted to money for weapons.

General Rules:
-Support your comrades
-Don't be a dick
-Don't wear enemy uniforms (particularly helmets).
-No spawncamping

The Rules of War:
-Do not kill those who can't fight (POWs, surrendering soldiers and wounded).
-False surrender is prohibited.
]]

Hook.Add("client.connected", "WR.welcomemessage", function(client)
    local chatMessage = ChatMessage.Create("Server", gamemodemessage, ChatMessageType.ServerMessageBox, nil, nil)
    Game.SendDirectChatMessage(chatMessage, client)
end)