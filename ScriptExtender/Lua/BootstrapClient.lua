local HarnessCore = Ext.Require("Shared/Harness.lua")

local Harness = HarnessCore.Create({
    commandPath = "CommandHarness/commands_client.lua",
    outputPath = "CommandHarness/output_client.txt",
    errorPath = "CommandHarness/error_client.txt",
    statusPath = "CommandHarness/status_client.txt",
    pollEvery = 5,
    logPrefix = "[CommandHarness][client]"
})

Ext.Events.Tick:Subscribe(function ()
    Harness.OnTick()
end)

Harness.WriteStatus("ready")
Harness.Log("ready")
