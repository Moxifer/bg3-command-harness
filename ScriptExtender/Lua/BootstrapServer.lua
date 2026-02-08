local HarnessCore = Ext.Require("Shared/Harness.lua")

local State = {
    ready = false,
    waitingLogged = false,
    osirisRegistered = false
}

local Harness

local function isGameplayReady()
    if Osi and Osi.GetHostCharacter then
        local ok, res = pcall(Osi.GetHostCharacter)
        if ok and res and res ~= "" then
            return true
        end
    end
    if Ext.Server then
        if Ext.Server.IsInGame then
            local ok, res = pcall(Ext.Server.IsInGame)
            if ok and res then
                return true
            end
        end
        if Ext.Server.GetCurrentLevel then
            local ok, res = pcall(Ext.Server.GetCurrentLevel)
            if ok and res and res ~= "" then
                return true
            end
        end
        if Ext.Server.GetHostCharacter then
            local ok, res = pcall(Ext.Server.GetHostCharacter)
            if ok and res ~= nil then
                return true
            end
        end
    end
    return false
end

local function markReady(reason)
    if State.ready then
        return
    end
    State.ready = true
    Harness.WriteStatus("ready")
    Harness.Log("gameplay ready" .. (reason and (": " .. reason) or ""))
end

local function registerSessionLoaded()
    if State.osirisRegistered then
        return
    end
    if not Ext.Events or not Ext.Events.SessionLoaded then
        return
    end
    local ok, err = pcall(function ()
        Ext.Events.SessionLoaded:Subscribe(function (_)
            markReady("SessionLoaded")
        end)
    end)
    if ok then
        State.osirisRegistered = true
    else
        Harness.Log("SessionLoaded listener not available: " .. tostring(err))
    end
end

local function ensureReady()
    if State.ready then
        return true
    end
    registerSessionLoaded()
    if isGameplayReady() then
        markReady("isGameplayReady")
        return true
    end
    if not State.waitingLogged then
        Harness.Log("waiting for level load before processing commands")
        Harness.WriteStatus("waiting")
        State.waitingLogged = true
    end
    return false
end

Harness = HarnessCore.Create({
    commandPath = "CommandHarness/commands_server.lua",
    outputPath = "CommandHarness/output_server.txt",
    errorPath = "CommandHarness/error_server.txt",
    statusPath = "CommandHarness/status_server.txt",
    pollEvery = 5,
    logPrefix = "[CommandHarness][server]",
    shouldPoll = ensureReady
})

Ext.Events.Tick:Subscribe(function ()
    Harness.OnTick()
end)

ensureReady()
Harness.Log("bootstrap ready")
