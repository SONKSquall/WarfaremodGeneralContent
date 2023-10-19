if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

WR.Game = {}
WR.Game.roundwinner = "..."
WR.Game.roundend = false
WR.Game.roundtimerdelay = 1200
WR.Game.roundtimertick = 1200


Hook.add("think", "WR.RoundEnd", function()

    if WR.Game.roundend == false then return end
    -- end round after 20 secs
    WR.Game.roundtimertick = WR.Game.roundtimertick-1
    if WR.Game.roundtimertick <= 0 then
        WR.Game.roundtimertick = WR.Game.roundtimerdelay
        WR.Game.roundend = false
        Game.ExecuteCommand("end")
    end

end)

Hook.add("WR.gameobjective.xmlhook", "WR.gameobjective", function(effect, deltaTime, item, targets, worldPosition)

    local tags = item.Tags
    -- gets the winner string via a tag in the item
    local _, _, winner = string.find(tags, 'winnerifbroken="(%a*)"')
    WR.Game.roundwinner = winner or "..."

    WR.Game.roundend = true

end)

Hook.add("roundEnd", "WR.RoundEndScreen", function()

    print(WR.Game.roundwinner .. " is the winner!")

    WR.Game.roundwinner = "..."
end)