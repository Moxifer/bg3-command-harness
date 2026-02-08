local M = {}

local function defaultSerialize(value)
    if value == nil then
        return "nil"
    end
    return Ext.DumpExport(value)
end

function M.Create(config)
    local harness = {
        commandPath = config.commandPath,
        outputPath = config.outputPath,
        errorPath = config.errorPath,
        statusPath = config.statusPath,
        pollEvery = config.pollEvery or 5,
        tickCount = 0,
        lastCode = nil
    }

    local logPrefix = config.logPrefix or "[CommandHarness]"
    local serialize = config.serialize or defaultSerialize
    local shouldPoll = config.shouldPoll

    local function log(msg)
        Ext.Log.Print(logPrefix .. " " .. msg)
    end

    local function writeFile(path, text)
        Ext.IO.SaveFile(path, text or "")
    end

    local function pack(...)
        return { n = select('#', ...), ... }
    end

    local function runChunk(code)
        local fn, err = Ext.Utils.LoadString(code)
        if not fn then
            return false, "CompileError: " .. tostring(err)
        end

        local results = pack(pcall(fn))
        if not results[1] then
            return false, "RuntimeError: " .. tostring(results[2])
        end

        if results.n <= 2 then
            return true, results[2]
        end

        local out = {}
        for i = 2, results.n do
            out[#out + 1] = results[i]
        end
        return true, out
    end

    local function archiveCommand(code)
        local dir, name = harness.commandPath:match("^(.-)([^/]+)$")
        if not dir then
            dir = ""
            name = harness.commandPath
        end
        local stem = name:gsub("%.lua$", "")
        writeFile(dir .. "_" .. stem .. ".last.lua", code)
        writeFile(harness.commandPath, "")
    end

    local function pollCommands()
        if shouldPoll and not shouldPoll() then
            return
        end

        local code = Ext.IO.LoadFile(harness.commandPath)
        if not code or code == "" then
            return
        end

        if code == harness.lastCode then
            return
        end

        harness.lastCode = code
        log("executing command")

        local ok, result = runChunk(code)
        if ok then
            writeFile(harness.outputPath, serialize(result))
            writeFile(harness.errorPath, "")
            writeFile(harness.statusPath, "ok")
            log("command ok")
        else
            writeFile(harness.errorPath, tostring(result))
            writeFile(harness.statusPath, "error")
            log("command error: " .. tostring(result))
        end

        archiveCommand(code)
        harness.lastCode = nil
    end

    function harness.OnTick()
        harness.tickCount = harness.tickCount + 1
        if (harness.tickCount % harness.pollEvery) == 0 then
            pollCommands()
        end
    end

    function harness.PollNow()
        pollCommands()
    end

    function harness.Log(msg)
        log(msg)
    end

    function harness.WriteStatus(text)
        writeFile(harness.statusPath, text or "")
    end

    return harness
end

return M
