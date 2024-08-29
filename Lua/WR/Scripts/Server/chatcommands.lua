if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

local welcomemessage = [[
Welcome to No Man's Land!

Description:
No Man's Land is a WW1 theme PvP gamemode where two teams duke it out in a variety of locations & fashions, from trench warfare to urban chaos.
However, what separates it from most other PvP gamemodes is its POW mechanics; prisoners can be taken & converted to money for weapons.

General Rules:
  -No cheating
  -Support your comrades
  -Don't be a dick
  -No ERP

The Rules of War:
  -Do not kill those who can't fight (POWs, surrendering soldiers & wounded).
  -False surrender is prohibited.

Use !help in chat to get a list of commands.
]]

local help = [[These are all possible chat commands:
!help : This menu.
!rules : List of standard rules for No Man's Land.
!time : Remaining time left before the round ends.
!medguide : In depth details on how to treat your self & others.
!powguide : Guide on how to make money taking prisoners.]]

local rules = [[
General Rules:
  -No cheating
  -Support your comrades
  -Don't be a dick
  -No ERP

The Rules of War:
  -Do not kill those who can't fight (POWs, surrendering soldiers & wounded).
  -False surrender is prohibited.]]

local medicalguide = [[Medical system:
    
Mechanics:
- Medications have a max capacity for healing in the form of two afflictions: Medicated & Intravenous.
- Bleeding reduces the effectiveness of drugs & drains the aforementioned afflictions.
- Cardiac arrest will build when a wounded soldier is unconscious & will kill after 100 seconds (the player can give after 60 seconds, however). This affliction disappears after consciousness is restored.

Guide for everyone:
- Treating bleeding is key, prioritize stanching heavy bleeders before other treatment is crucial.
- After bleeding has been dealt with use an opiate to revive the patient, if their health is near 80% they should get up on their own; in that case you can start working on the next patient.
- NEVER cluster around a single patient as this will make you a prime target for attacking infantry & artillery.

Guide for the medic:
- Medical rigs & trauma kits can store blood & rigs increase medical effectiveness of drugs by 50%.
- If the patient has sustained massive damage, fentanyl can revive almost instantly.
- When you have to do prolonged treatment begin CPR to give yourself more time (slows down cardiac arrest).]]

local prisonerguide = [[How to use the pow system:
    
Mechanics:
- A pow defined as a character that is alive, cuffed & not on the same team.
- Money is a product of POW taking & can be used to buy equipment & weapons at the spawn bunker shop.
    
Guide:
- Immediately after a battle, scan the ground for alive enemy combatants (including unconscious soldiers) upon finding one, cuff them & stop any severe bleeding.
- Drag the pow to a special structure called a pull switch; these are found at the spawn bunkers & landmarks. After using the prisoner will be despawned, their items put into a footlocker & money will spawn at the spawn bunker.]]

Hook.Add("client.connected", "WR.welcomemessage", function(client)
    local chatMessage = ChatMessage.Create("Server", welcomemessage, ChatMessageType.ServerMessageBox, nil, nil)
    Game.SendDirectChatMessage(chatMessage, client)
end)

local chatcommands = function (message,client)
    if message == "!help" then
        WR.SendMessagetoClient(help, client, {type = ChatMessageType.Default})
        return true
    end
    if message == "!rules" then
        WR.SendMessagetoClient(rules, client, {type = ChatMessageType.Default})
        return true
    end
    if message == "!time" then
        if not WR.Game.ending and Game.RoundStarted then
            WR.SendMessagetoClient("Round ending in"..WR.FormatTime((WR.tickmax-WR.tick)/60)..".", client, {type = ChatMessageType.Default})
        else
            WR.SendMessagetoClient("Round ending or not started!", client, {type = ChatMessageType.Default})
        end
        return true
    end
    if message == "!medguide" then
        WR.SendMessagetoClient(medicalguide, client)
        return true
    end
    if message == "!powguide" then
        WR.SendMessagetoClient(prisonerguide, client)
        return true
    end
    return false
end

Hook.Add("chatMessage", "WR.chatcommands", function(message,client)
    return chatcommands(message,client)
end)

Game.AddCommand("setroundlength", "Use to set a custom round length in minutes. (Works for one round)", function(args)
    WR.tickmax = tonumber(args[1])*60*60
    print("NEW ROUND LENGTH: ",tonumber(args[1]))
end, nil, true)

Game.AddCommand("forceend", "Ends the round with a optional winner.", function(args)
    if args[1] then 
        WR.Game.winner = WR.teamKeys[args[1]]
    else
        WR.Game.winner = WR.Game.altWinner()
    end
    WR.Game.endGame()
end, nil, true)