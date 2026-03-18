--[[
=================================================================
  GrammarProServer — Script (NOT LocalScript)
  Place inside: ServerScriptService

  This script runs on the Roblox SERVER, where HttpService is
  allowed. It creates a RemoteFunction called "GrammarProAnalyze"
  in ReplicatedStorage. The client LocalScript invokes it with
  the user's text and gets back the raw Groq JSON string.

  SETUP CHECKLIST:
    1. Place THIS script in ServerScriptService (as a Script)
    2. Place the LocalScript in StarterPlayerScripts
    3. Game Settings > Security > Allow HTTP Requests = ON
=================================================================
--]]

local HttpService      = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================
-- CONFIG — keep in sync with the LocalScript config block
-- ============================================================
local GROQ_API_KEY   = "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"
local API_URL        = "https://api.groq.com/openai/v1/chat/completions"
local API_MODEL      = "llama-3.1-8b-instant"   -- fastest Groq model ~0.3s
local API_MAX_TOKENS = 1024                      -- JSON only, no bloat

-- ============================================================
-- SYSTEM PROMPT (identical to the one in the LocalScript)
-- ============================================================
local SYSTEM_PROMPT = [[You are a fast grammar analysis engine. Be BRIEF. No explanations longer than 6 words.

Analyze the user's sentence and return ONLY this JSON (no markdown, no extra text):
{
  "corrected": "<fixed sentence>",
  "improved": {
    "natural": "<natural rewrite>",
    "professional": "<formal rewrite>",
    "concise": "<short rewrite>"
  },
  "word_analysis": [
    {
      "original": "word",
      "corrected": "word",
      "type": "typo | grammar | filler | weak | correct",
      "suggestions": ["alt1"],
      "did_you_mean": [],
      "reason": "brief reason"
    }
  ],
  "sentence_suggestions": ["<alt sentence>"],
  "removed_fillers": [],
  "notes": "<one sentence summary>"
}
Rules: valid JSON only, every word in word_analysis, keep all values short.]]

-- ============================================================
-- RATE LIMITER — max 1 request per player per 5 seconds
-- prevents spam / runaway API costs
-- ============================================================
local lastCall = {}   -- [userId] = tick()
local RATE_LIMIT_SECS = 5

-- ============================================================
-- CREATE REMOTEFUNCTION
-- ============================================================
local rf = Instance.new("RemoteFunction")
rf.Name   = "GrammarProAnalyze"
rf.Parent = ReplicatedStorage

-- ============================================================
-- HANDLER
-- Called by the client: rf:InvokeServer(text)
-- Returns: { success=true, data=rawJsonString }
--      or: { success=false, error=errorMessage }
-- ============================================================
rf.OnServerInvoke = function(player, text)
    -- Input validation
    if type(text) ~= "string" then
        return { success = false, error = "Invalid input type." }
    end
    text = text:sub(1, 500)   -- cap at 500 chars to control token cost
    if #text:match("^%s*(.-)%s*$") == 0 then
        return { success = false, error = "Empty text." }
    end

    -- Rate limit check
    local uid  = player.UserId
    local now  = tick()
    if lastCall[uid] and (now - lastCall[uid]) < RATE_LIMIT_SECS then
        local wait = math.ceil(RATE_LIMIT_SECS - (now - lastCall[uid]))
        return { success = false, error = "Please wait " .. wait .. "s before analyzing again." }
    end
    lastCall[uid] = now

    -- Build Groq request payload
    local payload = HttpService:JSONEncode({
        model      = API_MODEL,
        max_tokens = API_MAX_TOKENS,
        messages   = {
            { role = "system", content = SYSTEM_PROMPT },
            { role = "user",   content = 'Analyze this text: "' .. text .. '"' },
        },
    })

    -- Make the HTTP call (allowed on server)
    local ok, response = pcall(function()
        return HttpService:RequestAsync({
            Url    = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"]  = "application/json",
                ["Authorization"] = "Bearer " .. GROQ_API_KEY,
            },
            Body = payload,
        })
    end)

    if not ok then
        warn("[GrammarProServer] HTTP call failed:", response)
        return { success = false, error = "HTTP failed: " .. tostring(response):sub(1, 100) }
    end

    if not response.Success then
        warn("[GrammarProServer] Groq HTTP error:", response.StatusCode, response.Body:sub(1, 200))
        return {
            success = false,
            error   = "Groq error " .. tostring(response.StatusCode) .. ": " .. response.Body:sub(1, 100)
        }
    end

    -- Pull the assistant message content out of the OpenAI-format response
    local apiOk, apiData = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not apiOk or not apiData then
        return { success = false, error = "Could not decode Groq outer JSON." }
    end

    local rawContent = ""
    if apiData.choices and apiData.choices[1] and apiData.choices[1].message then
        rawContent = apiData.choices[1].message.content or ""
    end

    if rawContent == "" then
        return { success = false, error = "Groq returned an empty message content." }
    end

    -- Return the raw JSON string — client will parse and render it
    return { success = true, data = rawContent }
end

print("[GrammarProServer] ✓ Ready. RemoteFunction 'GrammarProAnalyze' live in ReplicatedStorage.")
