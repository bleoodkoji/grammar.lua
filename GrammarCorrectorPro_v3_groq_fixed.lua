--[[
=================================================================
  GRAMMAR CORRECTOR PRO — Loadstring Edition
  v3.0.0  (AI Deep Analysis: multi-style rewrites, per-word
           analysis, did-you-mean, tone detection, JSON engine)

  HOW TO USE:
    Option 1 — LocalScript:
      StarterPlayer > StarterPlayerScripts > LocalScript

    Option 2 — Loadstring:
      loadstring(game:HttpGet("https://YOUR_RAW_URL"))()

    Option 3 — Command Bar (Play mode only)

  REQUIREMENTS:
    • TextChatService.ChatVersion = TextChatService
    • HttpService.HttpEnabled = true  (Game Settings > Security)
    • A Groq API key inserted at GROQ_API_KEY below
      Get one free at: https://console.groq.com/keys
      (Server proxy recommended for production — see note)

  API KEY NOTE:
    Replace "YOUR_API_KEY_HERE" with your Groq key.
    For published games, route requests through a proxy server
    rather than embedding the key directly in the script.
=================================================================
--]]

local _ok, _err = xpcall(function()

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextChatService  = game:GetService("TextChatService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

if RunService:IsServer() then
    warn("[GrammarPro] Must be a LocalScript."); return
end

-- ============================================================
-- !! CONFIGURATION — SET YOUR GROQ API KEY HERE !!
-- ============================================================
local GROQ_API_KEY  = "YOUR_API_KEY_HERE"   -- https://console.groq.com/keys
local API_URL       = "https://api.groq.com/openai/v1/chat/completions"
local API_MODEL     = "llama-3.3-70b-versatile"   -- fast + smart; swap to
                                                   -- "mixtral-8x7b-32768" if desired
local API_MAX_TOKENS = 2000
-- Deep-analysis fires only on button click — no per-keystroke API calls.

-- ============================================================
-- SECTION 1: MASTER CORRECTION DICTIONARY  (offline, instant)
-- ============================================================
local WORD_FIXES = {
    ["your"]="you're",["youd"]="you'd",["youll"]="you'll",["youve"]="you've",
    ["youre"]="you're",["theyre"]="they're",["thier"]="their",
    ["itd"]="it'd",["itll"]="it'll",["itss"]="it's",
    ["im"]="I'm",["ive"]="I've",["ill"]="I'll",["id"]="I'd",
    ["idk"]="I don't know",["idc"]="I don't care",["imo"]="in my opinion",
    ["imho"]="in my honest opinion",["irl"]="in real life",
    ["ikr"]="I know, right",["iirc"]="if I recall correctly",
    ["dont"]="don't",["doesnt"]="doesn't",["didnt"]="didn't",
    ["wont"]="won't",["wouldnt"]="wouldn't",["couldnt"]="couldn't",
    ["shouldnt"]="shouldn't",["mustnt"]="mustn't",["neednt"]="needn't",
    ["mightnt"]="mightn't",["oughtnt"]="oughtn't",["hadnt"]="hadn't",
    ["hasnt"]="hasn't",["havent"]="haven't",["isnt"]="isn't",
    ["wasnt"]="wasn't",["werent"]="weren't",["arent"]="aren't",
    ["aint"]="isn't",["cannot"]="can't",["cant"]="can't",
    ["wed"]="we'd",["weve"]="we've",["well"]="we'll",["were"]="we're",
    ["theyd"]="they'd",["theyve"]="they've",["theyll"]="they'll",
    ["hed"]="he'd",["hes"]="he's",["hell"]="he'll",
    ["shed"]="she'd",["shes"]="she's",["shell"]="she'll",
    ["whos"]="who's",["whod"]="who'd",["wholl"]="who'll",["whove"]="who've",
    ["thats"]="that's",["theres"]="there's",["whats"]="what's",
    ["hows"]="how's",["wheres"]="where's",["whens"]="when's",["lets"]="let's",
    ["wanna"]="want to",["gonna"]="going to",["gotta"]="got to",
    ["kinda"]="kind of",["sorta"]="sort of",["hafta"]="have to",
    ["oughta"]="ought to",["betcha"]="bet you",["coulda"]="could have",
    ["woulda"]="would have",["shoulda"]="should have",["musta"]="must have",
    ["mighta"]="might have",["lotta"]="lot of",["outta"]="out of",
    ["lotsa"]="lots of",["dunno"]="don't know",["gimme"]="give me",
    ["lemme"]="let me",["cmon"]="come on",["c'mon"]="come on",
    ["yall"]="y'all",["ya'll"]="y'all",["ya"]="you",["u"]="you",
    ["ur"]="your",["r"]="are",["b4"]="before",["gr8"]="great",
    ["l8r"]="later",["plz"]="please",["pls"]="please",["thx"]="thanks",
    ["ty"]="thank you",["np"]="no problem",["nvm"]="never mind",
    ["omg"]="oh my god",["lol"]="lol",["lmao"]="lmao",
    ["brb"]="be right back",["gtg"]="got to go",["afk"]="away from keyboard",
    ["smh"]="shaking my head",["tbh"]="to be honest",
    ["ngl"]="not going to lie",["ftw"]="for the win",
    ["fwiw"]="for what it's worth",["fyi"]="for your information",
    ["acomodate"]="accommodate",["accomodate"]="accommodate",
    ["acheive"]="achieve",["accross"]="across",["adress"]="address",
    ["agressive"]="aggressive",["agression"]="aggression",
    ["alot"]="a lot",["alright"]="all right",["adn"]="and",["nad"]="and",
    ["ahve"]="have",["amature"]="amateur",["apparant"]="apparent",
    ["apparantly"]="apparently",["arguement"]="argument",["athiest"]="atheist",
    ["basicly"]="basically",["becuase"]="because",["becasue"]="because",
    ["beacuse"]="because",["becouse"]="because",["begining"]="beginning",
    ["beleive"]="believe",["belive"]="believe",["bizzare"]="bizarre",
    ["buisness"]="business",["calender"]="calendar",["catagory"]="category",
    ["cemetary"]="cemetery",["collegue"]="colleague",["comming"]="coming",
    ["commited"]="committed",["commitee"]="committee",["concious"]="conscious",
    ["concsious"]="conscious",["curiousity"]="curiosity",["damagage"]="damage",
    ["definitly"]="definitely",["definately"]="definitely",["definatly"]="definitely",
    ["desparate"]="desperate",["dissapear"]="disappear",["dissapoint"]="disappoint",
    ["disapear"]="disappear",["embarass"]="embarrass",["enviroment"]="environment",
    ["existance"]="existence",["experiance"]="experience",["expierence"]="experience",
    ["facinating"]="fascinating",["firey"]="fiery",["florescent"]="fluorescent",
    ["flourescent"]="fluorescent",["foriegn"]="foreign",["fourty"]="forty",
    ["freind"]="friend",["freinds"]="friends",["futher"]="further",
    ["gaurd"]="guard",["glamourous"]="glamorous",["goverment"]="government",
    ["grammer"]="grammar",["harrass"]="harass",["heros"]="heroes",
    ["hierachy"]="hierarchy",["hte"]="the",["ignorence"]="ignorance",
    ["imaginery"]="imaginary",["immedietly"]="immediately",["imediately"]="immediately",
    ["indispensible"]="indispensable",["innoculate"]="inoculate",
    ["inteligent"]="intelligent",["irresistable"]="irresistible",
    ["knowlege"]="knowledge",["knowlegde"]="knowledge",["labratory"]="laboratory",
    ["liesure"]="leisure",["liason"]="liaison",["maintainance"]="maintenance",
    ["maintenence"]="maintenance",["managment"]="management",["medival"]="medieval",
    ["millenium"]="millennium",["miniscule"]="minuscule",["mischevious"]="mischievous",
    ["mischievious"]="mischievous",["momment"]="moment",["naturaly"]="naturally",
    ["neccessary"]="necessary",["necesary"]="necessary",["nieghbor"]="neighbor",
    ["noticable"]="noticeable",["nto"]="not",["occured"]="occurred",
    ["occurance"]="occurrence",["occassion"]="occasion",["persistance"]="persistence",
    ["pharoah"]="pharaoh",["playright"]="playwright",["politican"]="politician",
    ["possesion"]="possession",["prescence"]="presence",["priviledge"]="privilege",
    ["probaly"]="probably",["proffesional"]="professional",["propoganda"]="propaganda",
    ["psycology"]="psychology",["questionaire"]="questionnaire",["realy"]="really",
    ["recieve"]="receive",["relevent"]="relevant",["religous"]="religious",
    ["remeber"]="remember",["repitition"]="repetition",["resistence"]="resistance",
    ["responsability"]="responsibility",["rythm"]="rhythm",["rythem"]="rhythm",
    ["sargent"]="sergeant",["seperate"]="separate",["sieze"]="seize",
    ["speach"]="speech",["studing"]="studying",["succesful"]="successful",
    ["sucessful"]="successful",["suprise"]="surprise",["taht"]="that",
    ["tath"]="that",["teh"]="the",["thsi"]="this",["temperment"]="temperament",
    ["tendancy"]="tendency",["therefor"]="therefore",["tommorrow"]="tomorrow",
    ["tommorow"]="tomorrow",["tounge"]="tongue",["transfered"]="transferred",
    ["truely"]="truly",["twelth"]="twelfth",["tyrany"]="tyranny",
    ["untill"]="until",["useable"]="usable",["usualy"]="usually",
    ["vaccum"]="vacuum",["vegitable"]="vegetable",["visability"]="visibility",
    ["voilence"]="violence",["volunter"]="volunteer",["waht"]="what",
    ["wellcome"]="welcome",["wether"]="whether",["wierd"]="weird",
    ["wich"]="which",["wiil"]="will",["writting"]="writing",
    ["woudl"]="would",["coudl"]="could",["shoudl"]="should",
    ["yuo"]="you",["tje"]="the",["tjhe"]="the",["thr"]="the",
}

-- ============================================================
-- SECTION 1B: WORD UPGRADES (offline suggestions)
-- ============================================================
local WORD_UPGRADES = {
    ["very big"]={sug="enormous",reason="stronger single word"},
    ["very small"]={sug="tiny",reason="stronger single word"},
    ["very fast"]={sug="rapid",reason="stronger single word"},
    ["very slow"]={sug="sluggish",reason="stronger single word"},
    ["very good"]={sug="excellent",reason="stronger single word"},
    ["very bad"]={sug="terrible",reason="stronger single word"},
    ["very happy"]={sug="elated",reason="stronger single word"},
    ["very sad"]={sug="devastated",reason="stronger single word"},
    ["very angry"]={sug="furious",reason="stronger single word"},
    ["very tired"]={sug="exhausted",reason="stronger single word"},
    ["very scared"]={sug="terrified",reason="stronger single word"},
    ["very pretty"]={sug="gorgeous",reason="stronger single word"},
    ["very ugly"]={sug="hideous",reason="stronger single word"},
    ["very smart"]={sug="brilliant",reason="stronger single word"},
    ["very stupid"]={sug="foolish",reason="stronger single word"},
    ["very cold"]={sug="freezing",reason="stronger single word"},
    ["very hot"]={sug="scorching",reason="stronger single word"},
    ["very old"]={sug="ancient",reason="stronger single word"},
    ["very new"]={sug="brand-new",reason="stronger single word"},
    ["very important"]={sug="crucial",reason="stronger single word"},
    ["very interesting"]={sug="fascinating",reason="stronger single word"},
    ["very boring"]={sug="tedious",reason="stronger single word"},
    ["very hard"]={sug="arduous",reason="stronger single word"},
    ["very easy"]={sug="effortless",reason="stronger single word"},
    ["very loud"]={sug="deafening",reason="stronger single word"},
    ["very quiet"]={sug="silent",reason="stronger single word"},
    ["very bright"]={sug="dazzling",reason="stronger single word"},
    ["very dark"]={sug="pitch-black",reason="stronger single word"},
    ["really good"]={sug="excellent",reason="stronger single word"},
    ["really bad"]={sug="terrible",reason="stronger single word"},
    ["really big"]={sug="massive",reason="stronger single word"},
    ["really fast"]={sug="swift",reason="stronger single word"},
    ["really hard"]={sug="challenging",reason="stronger single word"},
    ["a lot of"]={sug="numerous",reason="more precise"},
    ["lots of"]={sug="numerous",reason="more precise"},
    ["kind of"]={sug="somewhat",reason="cleaner phrasing"},
    ["sort of"]={sug="somewhat",reason="cleaner phrasing"},
    ["a bit"]={sug="slightly",reason="cleaner phrasing"},
    ["a little bit"]={sug="slightly",reason="cleaner phrasing"},
}
local SINGLE_WORD_UPGRADES = {
    ["make"]={sug="create",reason="more precise"},["get"]={sug="obtain",reason="more formal"},
    ["use"]={sug="utilize",reason="more formal"},["show"]={sug="demonstrate",reason="more precise"},
    ["tell"]={sug="inform",reason="more formal"},["ask"]={sug="inquire",reason="more formal"},
    ["try"]={sug="attempt",reason="more formal"},["want"]={sug="desire",reason="more formal"},
    ["need"]={sug="require",reason="more formal"},["help"]={sug="assist",reason="more formal"},
    ["start"]={sug="commence",reason="more formal"},["end"]={sug="conclude",reason="more formal"},
    ["stop"]={sug="cease",reason="more formal"},["think"]={sug="consider",reason="more precise"},
    ["know"]={sug="understand",reason="more precise"},["see"]={sug="observe",reason="more precise"},
    ["look"]={sug="examine",reason="more precise"},["say"]={sug="state",reason="more formal"},
    ["talk"]={sug="communicate",reason="more precise"},["give"]={sug="provide",reason="more formal"},
    ["take"]={sug="acquire",reason="more formal"},["put"]={sug="place",reason="more formal"},
    ["go"]={sug="proceed",reason="more formal"},["come"]={sug="arrive",reason="more formal"},
    ["find"]={sug="locate",reason="more formal"},["keep"]={sug="maintain",reason="more formal"},
    ["thing"]={sug="element",reason="more specific"},["stuff"]={sug="material",reason="more specific"},
    ["things"]={sug="elements",reason="more specific"},["lot"]={sug="great deal",reason="more precise"},
    ["big"]={sug="significant",reason="more descriptive"},["small"]={sug="minor",reason="more descriptive"},
    ["good"]={sug="excellent",reason="stronger word"},["bad"]={sug="poor",reason="stronger word"},
    ["nice"]={sug="pleasant",reason="stronger word"},["fine"]={sug="acceptable",reason="more precise"},
    ["cool"]={sug="impressive",reason="more formal"},["awesome"]={sug="remarkable",reason="more formal"},
    ["awful"]={sug="dreadful",reason="stronger word"},["pretty"]={sug="quite",reason="cleaner adverb"},
    ["very"]={sug="extremely",reason="stronger intensifier"},["really"]={sug="genuinely",reason="stronger intensifier"},
    ["hard"]={sug="difficult",reason="more formal"},["easy"]={sug="simple",reason="cleaner word"},
    ["fast"]={sug="rapid",reason="stronger word"},["slow"]={sug="gradual",reason="more precise"},
    ["old"]={sug="aged",reason="more descriptive"},["new"]={sug="recent",reason="more precise"},
    ["many"]={sug="numerous",reason="stronger word"},["few"]={sug="limited",reason="more precise"},
    ["more"]={sug="additional",reason="more formal"},["less"]={sug="fewer",reason="grammatically precise"},
    ["important"]={sug="crucial",reason="stronger word"},["different"]={sug="distinct",reason="more precise"},
    ["same"]={sug="identical",reason="more precise"},["ok"]={sug="acceptable",reason="more formal"},
    ["okay"]={sug="acceptable",reason="more formal"},["problem"]={sug="issue",reason="more neutral"},
    ["chance"]={sug="opportunity",reason="more positive"},["done"]={sug="completed",reason="more formal"},
    ["fix"]={sug="resolve",reason="more formal"},["check"]={sug="verify",reason="more precise"},
    ["care"]={sug="concern",reason="more formal"},["pick"]={sug="select",reason="more formal"},
    ["buy"]={sug="purchase",reason="more formal"},["sell"]={sug="offer",reason="more formal"},
    ["build"]={sug="construct",reason="more formal"},["break"]={sug="disrupt",reason="more precise"},
    ["change"]={sug="modify",reason="more precise"},["hide"]={sug="conceal",reason="more formal"},
    ["move"]={sug="relocate",reason="more formal"},["win"]={sug="succeed",reason="more formal"},
    ["lose"]={sug="fail",reason="more formal"},["fight"]={sug="contest",reason="more neutral"},
    ["meet"]={sug="encounter",reason="more formal"},["plan"]={sug="intend",reason="more formal"},
    ["hope"]={sug="anticipate",reason="more formal"},
}

-- ============================================================
-- SECTION 1C: FILLER WORDS
-- ============================================================
local FILLER_WORDS = {
    ["uh"]=true,["um"]=true,["uhh"]=true,["umm"]=true,["erm"]=true,
    ["hmm"]=true,["hm"]=true,["ah"]=true,["ahh"]=true,["er"]=true,
    ["eh"]=true,["mhm"]=true,["ugh"]=true,["like"]=true,
    ["basically"]=true,["literally"]=true,["honestly"]=true,
    ["actually"]=true,["just"]=true,["so"]=true,["well"]=true,
    ["right"]=true,["anyway"]=true,["anyways"]=true,["i mean"]=true,
}

-- ============================================================
-- SECTION 1D: PATTERN-BASED TYPO RULES
-- ============================================================
local PATTERN_RULES = {
    {"(%a)%1%1+","%1%1","triple+ letters → double"},
    {"%.%.%.+","...","normalize ellipsis"},
    {"%!%!+","!","normalize exclamation"},
    {"%?%?+","?","normalize question marks"},
    {"dependance","dependence","dependance fix"},
    {"existance","existence","existance fix"},
    {"independance","independence","independance fix"},
    {"differance","difference","differance fix"},
    {"recieve","receive","ie→ei after c"},
    {"beleive","believe","ei→ie"},
    {"wierd","weird","ei→ie"},
    {"freind","friend","ei→ie"},
    {"hieght","height","ie→ei"},
    {"theif","thief","ei→ie"},
    {"peice","piece","ei→ie"},
    {"concieve","conceive","ie→ei after c"},
    {"decieve","deceive","ie→ei after c"},
    {"percieve","perceive","ie→ei after c"},
    {"stoped","stopped","stoped fix"},
    {"droped","dropped","droped fix"},
    {"skiped","skipped","skiped fix"},
    {"planed","planned","planed fix"},
    {"runing","running","runing fix"},
    {"siting","sitting","siting fix"},
    {"geting","getting","geting fix"},
    {"referance","reference","referance fix"},
    {"usefull","useful","usefull fix"},
    {"helpfull","helpful","helpfull fix"},
    {"beautifull","beautiful","beautifull fix"},
    {"wonderfull","wonderful","wonderfull fix"},
    {"successfull","successful","successfull fix"},
    {"carefull","careful","carefull fix"},
    {"gratefull","grateful","gratefull fix"},
    {"missunderstand","misunderstand","missunderstand fix"},
    {"missspell","misspell","missspell fix"},
    {"mispell","misspell","mispell fix"},
}

-- ============================================================
-- SECTION 1E: SENTENCE IMPROVEMENT RULES  (offline)
-- ============================================================
local IMPROVE_PHRASES = {
    {"^I think that ","I believe ","stronger opener"},
    {"^I think ","I believe ","stronger opener"},
    {"^I feel like ","I believe ","stronger opener"},
    {"^I feel that ","I believe ","stronger opener"},
    {"^It is ","It remains ","more dynamic"},
    {"^There is ","There exists ","slightly stronger"},
    {"^There are ","Numerous ","stronger opener"},
    {"^This is ","This serves as ","more descriptive"},
    {"^So ","","remove filler opener"},
    {"^Well, ","","remove filler opener"},
    {"^Basically, ","","remove filler opener"},
    {"^Honestly, ","","remove filler opener"},
    {"^Actually, ","","remove filler opener"},
    {"^Like, ","","remove filler opener"},
    {"^OK so ","","remove filler opener"},
    {"^Okay so ","","remove filler opener"},
    {"in order to ","to ","concise"},
    {"at this point in time","currently","concise"},
    {"due to the fact that","because","concise"},
    {"in the event that ","if ","concise"},
    {"for the purpose of ","to ","concise"},
    {"with regard to ","regarding ","concise"},
    {"in spite of the fact that","although ","concise"},
    {"as a matter of fact,","","remove filler"},
    {"the fact that ","that ","concise"},
    {"in my opinion,","I believe","smoother"},
    {"in my opinion ","I believe ","smoother"},
    {"I think that I ","I ","remove redundancy"},
    {"it is important to note that","notably,","concise"},
    {"it should be noted that","notably,","concise"},
    {"there is no doubt that","undoubtedly,","concise"},
    {"it goes without saying","naturally,","concise"},
    {"in the near future","soon","concise"},
    {"at the present time","currently","concise"},
    {"on a daily basis","daily","concise"},
    {"in a timely manner","promptly","concise"},
    {"a large number of","many","concise"},
    {"a great deal of","much","concise"},
    {"make a decision","decide","concise"},
    {"make an attempt","attempt","concise"},
    {"take into consideration","consider","concise"},
    {"come to the conclusion","conclude","concise"},
    {"in close proximity to","near","concise"},
    {"in the vicinity of","near","concise"},
    {"referred to as","called","concise"},
    {"with the exception of","except","concise"},
    {"prior to","before","simpler"},
    {"subsequent to","after","simpler"},
    {"in addition to","besides","concise"},
    {"in addition,","furthermore,","stronger connector"},
    {"also,","additionally,","stronger connector"},
    {"but ","however, ","stronger connector"},
    {"and also","and","remove redundancy"},
    {"as well as","and","simpler"},
    {"each and every","every","remove redundancy"},
    {"first and foremost","primarily","concise"},
    {"last but not least","finally","concise"},
}

-- ============================================================
-- SECTION 2: OFFLINE CORRECTION ENGINE  (instant, no API)
-- ============================================================
local function capFirst(s)
    if not s or #s==0 then return s end
    return s:sub(1,1):upper()..s:sub(2)
end
local function matchCase(original,replacement)
    if #original>1 and original==original:upper() then return replacement:upper() end
    if original:sub(1,1)==original:sub(1,1):upper() then return capFirst(replacement) end
    return replacement
end
local function hasTerminal(s) return s:match("[%.%!%?…]%s*$")~=nil end
local function trim(s) return s:match("^%s*(.-)%s*$") end

local function applyPatternRules(text)
    for _,rule in ipairs(PATTERN_RULES) do
        local pat,rep=rule[1],rule[2]
        text = (type(rep)=="function") and text:gsub(pat,rep) or text:gsub(pat,rep)
    end
    return text
end

local function applyWordUpgrades(text)
    local suggestions={}
    local lower=text:lower()
    for phrase,data in pairs(WORD_UPGRADES) do
        local esc=phrase:gsub("([%(%)%.%%%+%-%*%?%[%^%$])","%%%1")
        if lower:find(esc) then
            table.insert(suggestions,{original=phrase,suggested=data.sug,reason=data.reason})
        end
    end
    local seen={}
    text:gsub("%f[%a][%a]+%f[%A]",function(word)
        local lw=word:lower()
        local upg=SINGLE_WORD_UPGRADES[lw]
        if upg and not seen[lw] then seen[lw]=true
            table.insert(suggestions,{original=word,suggested=upg.sug,reason=upg.reason})
        end
    end)
    local trimmed={}
    for i=1,math.min(#suggestions,6) do trimmed[i]=suggestions[i] end
    return trimmed
end

local function improveText(corrected)
    local text=corrected
    for _,rule in ipairs(IMPROVE_PHRASES) do
        text=text:gsub(rule[1],rule[2])
    end
    text=trim(text)
    if #text>0 then text=text:sub(1,1):upper()..text:sub(2) end
    if not hasTerminal(text) then
        if hasTerminal(corrected) then
            text=text..(corrected:match("[%.%!%?…]%s*$"):sub(1,1))
        else text=text.."." end
    end
    return text
end

local function correctText(input)
    if not input or trim(input)=="" then return input,{},input,{} end
    local text=input; local changes={}
    text=text:gsub("  +"," "); text=trim(text)
    text=text:gsub("%f[%a][%a']+%f[%A]",function(word)
        local lower=word:lower(); local fix=WORD_FIXES[lower]
        if fix and fix~=lower then
            local result=matchCase(word,fix)
            if result~=word then table.insert(changes,{original=word,corrected=result}) end
            return result
        end; return word
    end)
    local before2b=text; text=applyPatternRules(text)
    if text~=before2b then table.insert(changes,{original="pattern errors",corrected="fixed"}) end
    text=text:gsub("^i([%s%p])","I%1"); text=text:gsub("([%s])i([%s%p])","I%2") -- fixed capture
    text=text:gsub("([%s])i$","%1I"); text=text:gsub("^i$","I")
    text=text:gsub("^i'","I'"); text=text:gsub("([%s])i'","%1I'")
    if #text>0 then text=text:sub(1,1):upper()..text:sub(2) end
    text=text:gsub("([%.%!%?]%s+)(%a)",function(p,l) return p..l:upper() end)
    text=text:gsub("([%,%;%:])([%a%d])","%1 %2")
    text=text:gsub("([%.%!%?])([%a%d])","%1 %2")
    text=text:gsub("%s+([%,%.%!%?%;%:])","1")
    text=trim(text)
    if #text>0 and not hasTerminal(text) then text=text.."." end
    local improved=improveText(text)
    local upgradeSuggestions=applyWordUpgrades(text)
    return text,changes,improved,upgradeSuggestions
end

-- ============================================================
-- SECTION 3: CHAT SENDER
-- ============================================================
local function sendToChat(message)
    if not message or trim(message)=="" then return false end
    local success=false
    if TextChatService.ChatVersion==Enum.ChatVersion.TextChatService then
        local channels=TextChatService:FindFirstChild("TextChannels")
        if channels then
            local general=channels:FindFirstChild("RBXGeneral")
            if general then
                local ok=pcall(function() general:SendAsync(message) end)
                success=ok
            end
        end
    end
    if not success then
        local StarterGui=game:GetService("StarterGui")
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage",{
                Text="[GrammarPro] "..message,Color=Color3.fromRGB(200,200,255)})
        end)
        local Chat=game:GetService("Chat")
        pcall(function()
            Chat:Chat(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") or workspace,message)
        end)
        success=true
    end
    return success
end

-- ============================================================
-- SECTION 3B: ✦ AI DEEP ANALYSIS ENGINE  (Groq API)
-- Groq uses the OpenAI-compatible /v1/chat/completions endpoint.
-- The system prompt goes into messages[1]{role="system"}.
-- ============================================================

-- System prompt — passed as the first message with role "system"
local SYSTEM_PROMPT = [[You are a top-tier writing engine integrated into a Roblox real-time grammar system.
Your task is to perform a COMPLETE and EXHAUSTIVE analysis of the user's sentence.
Do not miss anything. Every word must be evaluated.

CORE OBJECTIVES:
1. Correct ALL grammar, spelling, punctuation, and sentence structure errors
2. Detect and fix ALL typos, even subtle or uncommon ones
3. Analyze EVERY word and suggest a stronger, clearer, or more precise alternative when possible
4. Identify incorrect word usage (e.g., "your" vs "you're") and provide "did you mean" suggestions
5. Remove or flag filler words (e.g., "like", "really", "just", "uh")
6. Improve sentence clarity, flow, and readability
7. Rewrite the sentence in multiple enhanced styles
8. Preserve original meaning at all times

ADVANCED BEHAVIOR:
- Be aggressive but intelligent with improvements
- Do NOT skip words — every word must appear in word_analysis
- If a word is already optimal, do not force a bad replacement
- If multiple corrections are possible, include the best one
- Detect tone and slightly improve it without making it robotic

OUTPUT FORMAT (STRICT JSON ONLY — no text outside the JSON, no markdown fences):
{
  "corrected": "<fully corrected sentence>",
  "improved": {
    "natural": "<smooth, natural rewrite>",
    "professional": "<more formal, refined version>",
    "concise": "<shortened, high-impact version>"
  },
  "word_analysis": [
    {
      "original": "word",
      "corrected": "word",
      "type": "typo | grammar | filler | weak | correct",
      "suggestions": ["alternative1", "alternative2"],
      "did_you_mean": ["optional suggestion"],
      "reason": "short explanation"
    }
  ],
  "sentence_suggestions": [
    "<alternative full sentence>",
    "<alternative full sentence>"
  ],
  "removed_fillers": ["word1", "word2"],
  "notes": "<brief explanation of the most important improvements>"
}

CRITICAL RULES:
- ALWAYS return valid JSON only
- DO NOT include any text outside the JSON
- DO NOT skip word analysis — every word must appear in word_analysis
- Keep explanations short and efficient (under 12 words each)
- Suggestions must be useful, not random or excessive]]

--[[
    callDeepAnalysis(text, onSuccess, onError)

    WHY A REMOTE BRIDGE?
    Roblox blocks HttpService:RequestAsync() in LocalScripts — it only
    works in server Scripts. So we fire a RemoteFunction to a companion
    server Script (GrammarProServer) which makes the real HTTP call and
    sends the raw JSON string back. We then parse it here on the client.

    Setup: place GrammarProServer (Script, not LocalScript) inside
    ServerScriptService. Its source is printed at the bottom of this file
    and is also saved as a separate file alongside this one.
--]]
local function callDeepAnalysis(text, onSuccess, onError)
    -- Find or wait for the RemoteFunction the server script creates
    local rf = game:GetService("ReplicatedStorage"):FindFirstChild("GrammarProAnalyze")
    if not rf then
        -- Give the server script up to 8 seconds to create it
        rf = game:GetService("ReplicatedStorage"):WaitForChild("GrammarProAnalyze", 8)
    end
    if not rf then
        onError("RemoteFunction 'GrammarProAnalyze' not found. Did you install GrammarProServer in ServerScriptService?")
        return
    end

    task.spawn(function()
        -- InvokeServer sends our text to the server script and waits for reply.
        -- The server returns: { success=bool, data=string, error=string }
        local ok, reply = pcall(function()
            return rf:InvokeServer(text)
        end)

        if not ok then
            onError("RemoteFunction invoke failed: " .. tostring(reply))
            return
        end

        if not reply or not reply.success then
            onError(tostring(reply and reply.error or "Server returned no data"))
            return
        end

        -- reply.data is the raw JSON string from Groq
        local rawContent = tostring(reply.data)

        -- Strip accidental markdown fences the model may add
        rawContent = rawContent
            :gsub("^```json%s*", "")
            :gsub("^```%s*",     "")
            :gsub("```%s*$",     "")
            :match("^%s*(.-)%s*$")

        -- Parse the inner JSON analysis payload
        local jsonOk, result = pcall(function()
            return HttpService:JSONDecode(rawContent)
        end)
        if not jsonOk or not result then
            onError("Failed to parse analysis JSON. Raw: " .. rawContent:sub(1, 120))
            return
        end

        onSuccess(result)
    end)
end

-- ============================================================
-- SECTION 4: THEME
-- ============================================================
local T = {
    PANEL       = Color3.fromRGB(20,20,30),
    TITLEBAR    = Color3.fromRGB(16,16,26),
    BORDER      = Color3.fromRGB(50,50,80),
    INPUT_BG    = Color3.fromRGB(26,26,40),
    PREVIEW_BG  = Color3.fromRGB(18,30,18),
    IMPROVE_BG  = Color3.fromRGB(18,22,35),
    SUGGEST_BG  = Color3.fromRGB(30,20,40),
    ANALYSIS_BG = Color3.fromRGB(14,14,26),
    TAB_ACTIVE  = Color3.fromRGB(80,140,255),
    TAB_IDLE    = Color3.fromRGB(35,35,55),
    TEXT        = Color3.fromRGB(220,220,255),
    TEXT_DIM    = Color3.fromRGB(120,120,160),
    TEXT_GREEN  = Color3.fromRGB(100,230,140),
    TEXT_BLUE   = Color3.fromRGB(120,180,255),
    TEXT_YELLOW = Color3.fromRGB(255,220,80),
    TEXT_PURPLE = Color3.fromRGB(200,140,255),
    TEXT_RED    = Color3.fromRGB(255,100,100),
    TEXT_ORANGE = Color3.fromRGB(255,170,80),
    TEXT_GRAY   = Color3.fromRGB(140,140,170),
    ACCENT      = Color3.fromRGB(80,140,255),
    BTN_SEND    = Color3.fromRGB(50,160,100),
    BTN_COPY    = Color3.fromRGB(60,120,220),
    BTN_PASTE   = Color3.fromRGB(140,80,220),
    BTN_CLEAR   = Color3.fromRGB(180,60,60),
    BTN_ANALYZE = Color3.fromRGB(160,100,240),
    CHANGE_BG   = Color3.fromRGB(60,40,0),
    CHANGE_TEXT = Color3.fromRGB(255,200,60),
    DOT_OK      = Color3.fromRGB(46,213,115),
    DOT_BUSY    = Color3.fromRGB(255,200,50),
    DOT_ERR     = Color3.fromRGB(255,80,80),
    -- Word-type colours for deep analysis
    TYPE_TYPO   = Color3.fromRGB(255,100,100),
    TYPE_GRAMMAR= Color3.fromRGB(255,170,80),
    TYPE_FILLER = Color3.fromRGB(180,120,255),
    TYPE_WEAK   = Color3.fromRGB(120,200,255),
    TYPE_CORRECT= Color3.fromRGB(80,220,120),
}

-- ============================================================
-- SECTION 5: UI CONSTRUCTION
-- ============================================================
local existingGui = PlayerGui:FindFirstChild("GrammarProUI")
if existingGui then existingGui:Destroy() end

local PANEL_W = 540
local PANEL_H = 620

local screenGui = Instance.new("ScreenGui")
screenGui.Name="GrammarProUI"; screenGui.ResetOnSpawn=false
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder=99; screenGui.Parent=PlayerGui

local panel = Instance.new("Frame")
panel.Name="Panel"; panel.Size=UDim2.new(0,PANEL_W,0,PANEL_H)
panel.Position=UDim2.new(0.5,-PANEL_W/2,0.5,-PANEL_H/2)
panel.BackgroundColor3=T.PANEL; panel.BorderSizePixel=0
panel.ClipsDescendants=true; panel.Parent=screenGui
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,14); c.Parent=panel
    local s=Instance.new("UIStroke"); s.Color=T.BORDER; s.Thickness=1.5
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=panel
end

local shadow=Instance.new("Frame")
shadow.Size=UDim2.new(1,16,1,16); shadow.Position=UDim2.new(0,-8,0,6)
shadow.BackgroundColor3=Color3.fromRGB(0,0,0); shadow.BackgroundTransparency=0.55
shadow.BorderSizePixel=0; shadow.ZIndex=panel.ZIndex-1; shadow.Parent=panel
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,18); c.Parent=shadow end

-- Title bar
local titleBar=Instance.new("Frame")
titleBar.Name="TitleBar"; titleBar.Size=UDim2.new(1,0,0,42)
titleBar.BackgroundColor3=T.TITLEBAR; titleBar.BorderSizePixel=0; titleBar.Parent=panel
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,14); c.Parent=titleBar end
local tbFix=Instance.new("Frame")
tbFix.Size=UDim2.new(1,0,0,14); tbFix.Position=UDim2.new(0,0,1,-14)
tbFix.BackgroundColor3=T.TITLEBAR; tbFix.BorderSizePixel=0; tbFix.Parent=titleBar

local logoDot=Instance.new("Frame")
logoDot.Size=UDim2.new(0,10,0,10); logoDot.Position=UDim2.new(0,14,0.5,-5)
logoDot.BackgroundColor3=T.ACCENT; logoDot.BorderSizePixel=0; logoDot.Parent=titleBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=logoDot end

local titleLabel=Instance.new("TextLabel")
titleLabel.Size=UDim2.new(1,-90,1,0); titleLabel.Position=UDim2.new(0,32,0,0)
titleLabel.BackgroundTransparency=1; titleLabel.Text="Grammar Corrector Pro  ✦ v3 Groq"
titleLabel.TextColor3=T.TEXT; titleLabel.Font=Enum.Font.GothamBold
titleLabel.TextSize=14; titleLabel.TextXAlignment=Enum.TextXAlignment.Left
titleLabel.Parent=titleBar

local statusDot=Instance.new("Frame")
statusDot.Size=UDim2.new(0,10,0,10); statusDot.Position=UDim2.new(1,-46,0.5,-5)
statusDot.BackgroundColor3=T.DOT_OK; statusDot.BorderSizePixel=0; statusDot.Parent=titleBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=statusDot end

local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,28,0,28); closeBtn.Position=UDim2.new(1,-36,0.5,-14)
closeBtn.BackgroundColor3=Color3.fromRGB(200,60,60); closeBtn.BorderSizePixel=0
closeBtn.Text="✕"; closeBtn.TextColor3=Color3.fromRGB(255,255,255)
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12; closeBtn.Parent=titleBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=closeBtn end
closeBtn.Activated:Connect(function() screenGui:Destroy() end)

-- ── TAB BAR ───────────────────────────────────────────────
local tabBar=Instance.new("Frame")
tabBar.Name="TabBar"; tabBar.Size=UDim2.new(1,-24,0,34)
tabBar.Position=UDim2.new(0,12,0,48)
tabBar.BackgroundColor3=T.ANALYSIS_BG; tabBar.BorderSizePixel=0; tabBar.Parent=panel
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=tabBar
    local layout=Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.Padding=UDim.new(0,2); layout.Parent=tabBar
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,4)
    p.PaddingTop=UDim.new(0,4); p.PaddingBottom=UDim.new(0,4); p.Parent=tabBar
end

local function makeTab(name,label)
    local btn=Instance.new("TextButton")
    btn.Name=name; btn.Size=UDim2.new(0,150,1,0)
    btn.BackgroundColor3=T.TAB_IDLE; btn.BorderSizePixel=0
    btn.Text=label; btn.TextColor3=T.TEXT_DIM
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=12; btn.Parent=tabBar
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=btn end
    return btn
end
local tabStandard = makeTab("TabStandard","⚙  Standard")
local tabDeep     = makeTab("TabDeep",    "✦  Deep Analysis (AI)")

-- ── PAGES (two frames, only one visible at a time) ────────
local function makePage(name)
    local f=Instance.new("Frame")
    f.Name=name; f.Size=UDim2.new(1,-24,1,-98)
    f.Position=UDim2.new(0,12,0,90)
    f.BackgroundTransparency=1; f.BorderSizePixel=0; f.Parent=panel
    return f
end
local pageStandard = makePage("PageStandard")
local pageDeep     = makePage("PageDeep")
pageDeep.Visible   = false

-- ============================================================
-- SECTION 5B: STANDARD PAGE  (preserved from v2)
-- ============================================================
local function makeLabel(parent,text,yPos)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,16); lbl.Position=UDim2.new(0,0,0,yPos)
    lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.TextColor3=T.TEXT_DIM; lbl.Font=Enum.Font.GothamSemibold
    lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=parent
    return lbl
end
local function makeButton(parent,label,color,xPos,yPos,width,height)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,width,0,height or 36)
    btn.Position=UDim2.new(0,xPos,0,yPos)
    btn.BackgroundColor3=color; btn.BorderSizePixel=0
    btn.Text=label; btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13; btn.Parent=parent
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=btn end
    local base=color
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3=Color3.new(math.min(1,base.R+0.12),math.min(1,base.G+0.12),math.min(1,base.B+0.12))
    end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=base end)
    return btn
end

-- Input
makeLabel(pageStandard,"✎  YOUR MESSAGE",0)
local inputBox=Instance.new("TextBox")
inputBox.Name="InputBox"; inputBox.Size=UDim2.new(1,0,0,64)
inputBox.Position=UDim2.new(0,0,0,18)
inputBox.BackgroundColor3=T.INPUT_BG; inputBox.BorderSizePixel=0
inputBox.Text=""; inputBox.PlaceholderText="Type your message here..."
inputBox.PlaceholderColor3=T.TEXT_DIM; inputBox.TextColor3=T.TEXT
inputBox.Font=Enum.Font.Gotham; inputBox.TextSize=14
inputBox.TextXAlignment=Enum.TextXAlignment.Left; inputBox.TextYAlignment=Enum.TextYAlignment.Top
inputBox.MultiLine=true; inputBox.ClearTextOnFocus=false
inputBox.TextWrapped=true; inputBox.Parent=pageStandard
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=inputBox
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10)
    p.PaddingRight=UDim.new(0,10); p.PaddingTop=UDim.new(0,8); p.Parent=inputBox
    local s=Instance.new("UIStroke"); s.Color=T.BORDER; s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=inputBox
end

-- Corrected preview
makeLabel(pageStandard,"✓  CORRECTED",90)
local previewFrame=Instance.new("Frame")
previewFrame.Size=UDim2.new(1,0,0,46); previewFrame.Position=UDim2.new(0,0,0,108)
previewFrame.BackgroundColor3=T.PREVIEW_BG; previewFrame.BorderSizePixel=0
previewFrame.ClipsDescendants=true; previewFrame.Parent=pageStandard
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=previewFrame
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(40,100,40); s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=previewFrame
end
local previewText=Instance.new("TextLabel")
previewText.Size=UDim2.new(1,-20,1,0); previewText.Position=UDim2.new(0,10,0,0)
previewText.BackgroundTransparency=1; previewText.Text=""
previewText.TextColor3=T.TEXT_GREEN; previewText.Font=Enum.Font.Gotham
previewText.TextSize=13; previewText.TextXAlignment=Enum.TextXAlignment.Left
previewText.TextYAlignment=Enum.TextYAlignment.Top; previewText.TextWrapped=true
previewText.Parent=previewFrame
do local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,6); p.Parent=previewText end

-- Improved preview
makeLabel(pageStandard,"✦  IMPROVED",162)
local improveFrame=Instance.new("Frame")
improveFrame.Size=UDim2.new(1,0,0,46); improveFrame.Position=UDim2.new(0,0,0,180)
improveFrame.BackgroundColor3=T.IMPROVE_BG; improveFrame.BorderSizePixel=0
improveFrame.ClipsDescendants=true; improveFrame.Parent=pageStandard
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=improveFrame
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(40,60,130); s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=improveFrame
end
local improveText=Instance.new("TextLabel")
improveText.Size=UDim2.new(1,-20,1,0); improveText.Position=UDim2.new(0,10,0,0)
improveText.BackgroundTransparency=1; improveText.Text=""
improveText.TextColor3=T.TEXT_BLUE; improveText.Font=Enum.Font.Gotham
improveText.TextSize=13; improveText.TextXAlignment=Enum.TextXAlignment.Left
improveText.TextYAlignment=Enum.TextYAlignment.Top; improveText.TextWrapped=true
improveText.Parent=improveFrame
do local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,6); p.Parent=improveText end

-- Corrections made
makeLabel(pageStandard,"⚡  CORRECTIONS MADE",234)
local changesScroll=Instance.new("ScrollingFrame")
changesScroll.Size=UDim2.new(1,0,0,38); changesScroll.Position=UDim2.new(0,0,0,252)
changesScroll.BackgroundColor3=T.INPUT_BG; changesScroll.BorderSizePixel=0
changesScroll.ScrollBarThickness=3; changesScroll.ScrollBarImageColor3=T.ACCENT
changesScroll.CanvasSize=UDim2.new(0,0,0,0); changesScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
changesScroll.ClipsDescendants=true; changesScroll.Parent=pageStandard
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=changesScroll
    local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal
    layout.Padding=UDim.new(0,4); layout.Parent=changesScroll
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,6); p.PaddingTop=UDim.new(0,5); p.Parent=changesScroll
end
local noChangesLabel=Instance.new("TextLabel")
noChangesLabel.Name="NoChanges"; noChangesLabel.Size=UDim2.new(1,-12,1,0)
noChangesLabel.Position=UDim2.new(0,6,0,0); noChangesLabel.BackgroundTransparency=1
noChangesLabel.Text="No corrections yet — start typing above."
noChangesLabel.TextColor3=T.TEXT_DIM; noChangesLabel.Font=Enum.Font.Gotham
noChangesLabel.TextSize=12; noChangesLabel.TextXAlignment=Enum.TextXAlignment.Left
noChangesLabel.Parent=changesScroll

-- Word upgrades
makeLabel(pageStandard,"💡  WORD UPGRADES",298)
local upgradeScroll=Instance.new("ScrollingFrame")
upgradeScroll.Size=UDim2.new(1,0,0,70); upgradeScroll.Position=UDim2.new(0,0,0,316)
upgradeScroll.BackgroundColor3=T.SUGGEST_BG; upgradeScroll.BorderSizePixel=0
upgradeScroll.ScrollBarThickness=3; upgradeScroll.ScrollBarImageColor3=Color3.fromRGB(160,80,240)
upgradeScroll.CanvasSize=UDim2.new(0,0,0,0); upgradeScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
upgradeScroll.ClipsDescendants=true; upgradeScroll.Parent=pageStandard
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=upgradeScroll
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(80,40,120); s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=upgradeScroll
    local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Vertical
    layout.Padding=UDim.new(0,2); layout.Parent=upgradeScroll
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,8); p.PaddingTop=UDim.new(0,5)
    p.PaddingBottom=UDim.new(0,4); p.PaddingRight=UDim.new(0,8); p.Parent=upgradeScroll
end
local noUpgradesLabel=Instance.new("TextLabel")
noUpgradesLabel.Name="NoUpgrades"; noUpgradesLabel.Size=UDim2.new(1,0,0,22)
noUpgradesLabel.BackgroundTransparency=1
noUpgradesLabel.Text="No suggestions yet — type something above."
noUpgradesLabel.TextColor3=T.TEXT_DIM; noUpgradesLabel.Font=Enum.Font.Gotham
noUpgradesLabel.TextSize=12; noUpgradesLabel.TextXAlignment=Enum.TextXAlignment.Left
noUpgradesLabel.Parent=upgradeScroll

-- Standard page buttons
local BTN_Y=396
local btnSend        = makeButton(pageStandard,"▶  Send",       T.BTN_SEND,  0,   BTN_Y,   108)
local btnCopy        = makeButton(pageStandard,"⧉  Copy",       T.BTN_COPY,  114, BTN_Y,   108)
local btnPaste       = makeButton(pageStandard,"⏎  Paste",      T.BTN_PASTE, 228, BTN_Y,   108)
local btnClear       = makeButton(pageStandard,"✕  Clear",      T.BTN_CLEAR, 342, BTN_Y,   108)
local btnUseImproved = makeButton(pageStandard,"✦  Use Improved",Color3.fromRGB(80,50,160),0,BTN_Y+44,228)
local btnSendImproved= makeButton(pageStandard,"▶  Send Improved",T.BTN_SEND,234,BTN_Y+44,228)

-- ============================================================
-- SECTION 5C: ✦ DEEP ANALYSIS PAGE
-- ============================================================

-- Analyze button (prominent at top of deep page)
local btnAnalyze=makeButton(pageDeep,"🔍  Run Deep Analysis (AI)",T.BTN_ANALYZE,0,0,516,38)

-- Status/loading bar
local analysisStatus=Instance.new("TextLabel")
analysisStatus.Size=UDim2.new(1,0,0,18); analysisStatus.Position=UDim2.new(0,0,0,46)
analysisStatus.BackgroundTransparency=1
analysisStatus.Text="Enter text in Standard tab, then click Analyze."
analysisStatus.TextColor3=T.TEXT_DIM; analysisStatus.Font=Enum.Font.Gotham
analysisStatus.TextSize=12; analysisStatus.TextXAlignment=Enum.TextXAlignment.Left
analysisStatus.Parent=pageDeep

-- Results scrolling frame
local deepScroll=Instance.new("ScrollingFrame")
deepScroll.Name="DeepScroll"; deepScroll.Size=UDim2.new(1,0,1,-72)
deepScroll.Position=UDim2.new(0,0,0,68)
deepScroll.BackgroundColor3=T.ANALYSIS_BG; deepScroll.BorderSizePixel=0
deepScroll.ScrollBarThickness=4; deepScroll.ScrollBarImageColor3=T.ACCENT
deepScroll.CanvasSize=UDim2.new(0,0,0,0); deepScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
deepScroll.ClipsDescendants=true; deepScroll.Parent=pageDeep
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=deepScroll
    local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Vertical
    layout.Padding=UDim.new(0,8); layout.Parent=deepScroll
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10)
    p.PaddingTop=UDim.new(0,10); p.PaddingBottom=UDim.new(0,10); p.Parent=deepScroll
end

-- ============================================================
-- SECTION 6: DEEP ANALYSIS UI RENDERER
-- ============================================================

-- Helper: create a section header inside deep scroll
local function deepHeader(parent, text, color)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,20); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.TextColor3=color or T.TEXT_DIM
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=parent
    return lbl
end

-- Helper: create a text body row
local function deepRow(parent,text,color,size)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,0); lbl.AutomaticSize=Enum.AutomaticSize.Y
    lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.TextColor3=color or T.TEXT; lbl.Font=Enum.Font.Gotham
    lbl.TextSize=size or 13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextWrapped=true; lbl.Parent=parent
    return lbl
end

-- Helper: horizontal divider
local function deepDivider(parent)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,1); f.BackgroundColor3=T.BORDER; f.BorderSizePixel=0
    f.Parent=parent
end

-- Type → colour mapping
local TYPE_COLORS = {
    typo    = T.TYPE_TYPO,
    grammar = T.TYPE_GRAMMAR,
    filler  = T.TYPE_FILLER,
    weak    = T.TYPE_WEAK,
    correct = T.TYPE_CORRECT,
}

--[[
    renderDeepAnalysis(result)
    Takes the parsed JSON from the API and builds UI rows
    inside deepScroll.
--]]
local function renderDeepAnalysis(result)
    -- Clear previous results
    for _,ch in ipairs(deepScroll:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
            ch:Destroy()
        end
    end

    -- ── CORRECTED ─────────────────────────────────────────
    deepHeader(deepScroll,"✓  CORRECTED",T.TEXT_GREEN)
    local corrFrame=Instance.new("Frame")
    corrFrame.Size=UDim2.new(1,0,0,0); corrFrame.AutomaticSize=Enum.AutomaticSize.Y
    corrFrame.BackgroundColor3=T.PREVIEW_BG; corrFrame.BorderSizePixel=0; corrFrame.Parent=deepScroll
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=corrFrame
       local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10); p.PaddingTop=UDim.new(0,6)
       p.PaddingBottom=UDim.new(0,6); p.PaddingRight=UDim.new(0,10); p.Parent=corrFrame end
    deepRow(corrFrame, result.corrected or "—", T.TEXT_GREEN, 13)
    deepDivider(deepScroll)

    -- ── THREE IMPROVED STYLES ──────────────────────────────
    if result.improved then
        deepHeader(deepScroll,"✦  REWRITES",T.TEXT_BLUE)
        local styles={
            {"Natural",     result.improved.natural,     T.TEXT_GREEN},
            {"Professional",result.improved.professional,T.TEXT_BLUE},
            {"Concise",     result.improved.concise,     T.TEXT_YELLOW},
        }
        for _,style in ipairs(styles) do
            local frame=Instance.new("Frame")
            frame.Size=UDim2.new(1,0,0,0); frame.AutomaticSize=Enum.AutomaticSize.Y
            frame.BackgroundColor3=T.IMPROVE_BG; frame.BorderSizePixel=0; frame.Parent=deepScroll
            do
                local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=frame
                local s=Instance.new("UIStroke"); s.Color=T.BORDER; s.Thickness=1
                s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=frame
                local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10); p.PaddingTop=UDim.new(0,6)
                p.PaddingBottom=UDim.new(0,6); p.PaddingRight=UDim.new(0,10); p.Parent=frame
            end
            -- Label badge
            local badge=Instance.new("TextLabel")
            badge.Size=UDim2.new(1,0,0,14); badge.BackgroundTransparency=1
            badge.Text=style[1]:upper(); badge.TextColor3=style[3]
            badge.Font=Enum.Font.GothamBold; badge.TextSize=10
            badge.TextXAlignment=Enum.TextXAlignment.Left; badge.Parent=frame
            local body=deepRow(frame, style[2] or "—", T.TEXT, 13)
            body.Position=UDim2.new(0,0,0,16)
            -- Make frame taller to fit label + body
            frame.AutomaticSize=Enum.AutomaticSize.Y

            -- "Use this" button on each style
            local useBtn=Instance.new("TextButton")
            useBtn.Size=UDim2.new(0,80,0,22); useBtn.AutomaticSize=Enum.AutomaticSize.None
            useBtn.BackgroundColor3=Color3.fromRGB(50,50,80); useBtn.BorderSizePixel=0
            useBtn.Text="Use this"; useBtn.TextColor3=style[3]
            useBtn.Font=Enum.Font.Gotham; useBtn.TextSize=11; useBtn.Parent=frame
            do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=useBtn end
            local capturedText = style[2] or ""
            useBtn.Activated:Connect(function()
                if capturedText ~= "" then
                    inputBox.Text = capturedText
                end
            end)
        end
        deepDivider(deepScroll)
    end

    -- ── WORD ANALYSIS TABLE ────────────────────────────────
    if result.word_analysis and #result.word_analysis > 0 then
        deepHeader(deepScroll,"🔬  WORD-BY-WORD ANALYSIS",T.TEXT_YELLOW)
        for _,w in ipairs(result.word_analysis) do
            local typeColor=TYPE_COLORS[w.type] or T.TEXT
            local frame=Instance.new("Frame")
            frame.Size=UDim2.new(1,0,0,0); frame.AutomaticSize=Enum.AutomaticSize.Y
            frame.BackgroundColor3=Color3.fromRGB(22,22,36); frame.BorderSizePixel=0
            frame.Parent=deepScroll
            do
                local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=frame
                local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Vertical
                layout.Padding=UDim.new(0,2); layout.Parent=frame
                local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,8); p.PaddingTop=UDim.new(0,5)
                p.PaddingBottom=UDim.new(0,5); p.PaddingRight=UDim.new(0,8); p.Parent=frame
            end

            -- Row 1: original → corrected  [type badge]
            local row1=Instance.new("Frame")
            row1.Size=UDim2.new(1,0,0,18); row1.BackgroundTransparency=1; row1.Parent=frame
            do
                local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal
                layout.VerticalAlignment=Enum.VerticalAlignment.Center; layout.Padding=UDim.new(0,6)
                layout.Parent=row1
            end
            local function addR1(text,color,bold,size)
                local l=Instance.new("TextLabel"); l.AutomaticSize=Enum.AutomaticSize.X
                l.Size=UDim2.new(0,0,1,0); l.BackgroundTransparency=1; l.Text=text
                l.TextColor3=color; l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
                l.TextSize=size or 13; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=row1
            end
            -- original word
            addR1('"'..(w.original or "")..'"', T.TEXT_DIM, false, 13)
            if w.corrected and w.corrected ~= w.original then
                addR1("→", T.TEXT_DIM, false, 12)
                addR1('"'..(w.corrected)..'"', T.TEXT_GREEN, true, 13)
            end
            -- type badge
            local typeBadge=Instance.new("TextLabel"); typeBadge.AutomaticSize=Enum.AutomaticSize.X
            typeBadge.Size=UDim2.new(0,0,0,16); typeBadge.BackgroundColor3=Color3.fromRGB(30,30,50)
            typeBadge.Text=" "..(w.type or "?").." "; typeBadge.TextColor3=typeColor
            typeBadge.Font=Enum.Font.GothamBold; typeBadge.TextSize=10; typeBadge.Parent=row1
            do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,4); c.Parent=typeBadge end

            -- Row 2: reason
            if w.reason and w.reason~="" then
                local reasonLbl=Instance.new("TextLabel"); reasonLbl.Size=UDim2.new(1,0,0,14)
                reasonLbl.BackgroundTransparency=1; reasonLbl.Text=w.reason
                reasonLbl.TextColor3=T.TEXT_GRAY; reasonLbl.Font=Enum.Font.Gotham
                reasonLbl.TextSize=11; reasonLbl.TextXAlignment=Enum.TextXAlignment.Left
                reasonLbl.Parent=frame
            end

            -- Row 3: suggestions
            if w.suggestions and #w.suggestions>0 then
                local sugText="Suggestions: "..table.concat(w.suggestions,", ")
                local sugLbl=Instance.new("TextLabel"); sugLbl.Size=UDim2.new(1,0,0,14)
                sugLbl.BackgroundTransparency=1; sugLbl.Text=sugText
                sugLbl.TextColor3=T.TEXT_PURPLE; sugLbl.Font=Enum.Font.Gotham
                sugLbl.TextSize=11; sugLbl.TextXAlignment=Enum.TextXAlignment.Left
                sugLbl.Parent=frame
            end

            -- Row 4: did you mean
            if w.did_you_mean and #w.did_you_mean>0 then
                local dymText='Did you mean: "'..table.concat(w.did_you_mean,'", "')..'"?'
                local dymLbl=Instance.new("TextLabel"); dymLbl.Size=UDim2.new(1,0,0,14)
                dymLbl.BackgroundTransparency=1; dymLbl.Text=dymText
                dymLbl.TextColor3=T.TEXT_ORANGE; dymLbl.Font=Enum.Font.GothamSemibold
                dymLbl.TextSize=11; dymLbl.TextXAlignment=Enum.TextXAlignment.Left
                dymLbl.Parent=frame
            end
        end
        deepDivider(deepScroll)
    end

    -- ── SENTENCE SUGGESTIONS ──────────────────────────────
    if result.sentence_suggestions and #result.sentence_suggestions>0 then
        deepHeader(deepScroll,"💬  ALTERNATIVE SENTENCES",T.TEXT_PURPLE)
        for i,sent in ipairs(result.sentence_suggestions) do
            local frame=Instance.new("Frame")
            frame.Size=UDim2.new(1,0,0,0); frame.AutomaticSize=Enum.AutomaticSize.Y
            frame.BackgroundColor3=Color3.fromRGB(24,18,38); frame.BorderSizePixel=0
            frame.Parent=deepScroll
            do
                local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=frame
                local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10); p.PaddingTop=UDim.new(0,6)
                p.PaddingBottom=UDim.new(0,6); p.PaddingRight=UDim.new(0,10); p.Parent=frame
                local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Vertical
                layout.Padding=UDim.new(0,3); layout.Parent=frame
            end
            local numLbl=Instance.new("TextLabel"); numLbl.Size=UDim2.new(1,0,0,12)
            numLbl.BackgroundTransparency=1; numLbl.Text="Option "..i
            numLbl.TextColor3=Color3.fromRGB(140,90,220); numLbl.Font=Enum.Font.GothamBold
            numLbl.TextSize=10; numLbl.TextXAlignment=Enum.TextXAlignment.Left; numLbl.Parent=frame
            deepRow(frame,sent,T.TEXT,13)
            -- "Use" button
            local useBtn=Instance.new("TextButton"); useBtn.Size=UDim2.new(0,60,0,20)
            useBtn.BackgroundColor3=Color3.fromRGB(50,30,80); useBtn.BorderSizePixel=0
            useBtn.Text="Use"; useBtn.TextColor3=T.TEXT_PURPLE
            useBtn.Font=Enum.Font.Gotham; useBtn.TextSize=11; useBtn.Parent=frame
            do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,4); c.Parent=useBtn end
            local capturedSent=sent
            useBtn.Activated:Connect(function() inputBox.Text=capturedSent end)
        end
        deepDivider(deepScroll)
    end

    -- ── REMOVED FILLERS ───────────────────────────────────
    if result.removed_fillers and #result.removed_fillers>0 then
        deepHeader(deepScroll,"🚫  FILLERS REMOVED",T.TYPE_FILLER)
        local fillerText=table.concat(result.removed_fillers,",  ")
        deepRow(deepScroll,fillerText,T.TYPE_FILLER,12)
        deepDivider(deepScroll)
    end

    -- ── NOTES ─────────────────────────────────────────────
    if result.notes and result.notes~="" then
        deepHeader(deepScroll,"📝  ANALYSIS NOTES",T.TEXT_YELLOW)
        local notesFrame=Instance.new("Frame")
        notesFrame.Size=UDim2.new(1,0,0,0); notesFrame.AutomaticSize=Enum.AutomaticSize.Y
        notesFrame.BackgroundColor3=Color3.fromRGB(30,28,14); notesFrame.BorderSizePixel=0
        notesFrame.Parent=deepScroll
        do
            local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=notesFrame
            local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10); p.PaddingTop=UDim.new(0,7)
            p.PaddingBottom=UDim.new(0,7); p.PaddingRight=UDim.new(0,10); p.Parent=notesFrame
        end
        deepRow(notesFrame,result.notes,T.TEXT_YELLOW,12)
    end
end

-- ============================================================
-- SECTION 7: REAL-TIME PREVIEW (standard tab)
-- ============================================================
local isUpdatingPreview=false
local debounceTime=0
local DEBOUNCE=0.3
local currentImproved=""

local function updateChangeTags(changes)
    for _,ch in ipairs(changesScroll:GetChildren()) do
        if ch:IsA("TextButton") or (ch:IsA("TextLabel") and ch.Name~="NoChanges") then ch:Destroy() end
    end
    if #changes==0 then noChangesLabel.Visible=true; return end
    noChangesLabel.Visible=false
    for _,chg in ipairs(changes) do
        local tag=Instance.new("TextButton"); tag.AutomaticSize=Enum.AutomaticSize.X
        tag.Size=UDim2.new(0,0,0,26); tag.BackgroundColor3=T.CHANGE_BG; tag.BorderSizePixel=0
        tag.Text=("  %s → %s  "):format(chg.original,chg.corrected)
        tag.TextColor3=T.CHANGE_TEXT; tag.Font=Enum.Font.Gotham; tag.TextSize=11
        tag.Parent=changesScroll
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=tag end
    end
end

local function updateUpgradeTags(suggestions)
    for _,ch in ipairs(upgradeScroll:GetChildren()) do
        if ch:IsA("Frame") or (ch:IsA("TextLabel") and ch.Name~="NoUpgrades") then ch:Destroy() end
    end
    if #suggestions==0 then noUpgradesLabel.Visible=true; return end
    noUpgradesLabel.Visible=false
    for _,sug in ipairs(suggestions) do
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,-16,0,20)
        row.BackgroundTransparency=1; row.BorderSizePixel=0; row.Parent=upgradeScroll
        do
            local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal
            layout.VerticalAlignment=Enum.VerticalAlignment.Center; layout.Padding=UDim.new(0,5)
            layout.Parent=row
        end
        local function addL(text,color,bold)
            local l=Instance.new("TextLabel"); l.AutomaticSize=Enum.AutomaticSize.X
            l.Size=UDim2.new(0,0,1,0); l.BackgroundTransparency=1; l.Text=text
            l.TextColor3=color; l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
            l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=row
        end
        addL(sug.original,T.TEXT_DIM,false); addL("→",Color3.fromRGB(160,100,220),false)
        addL(sug.suggested,T.TEXT_PURPLE,true)
        local rLbl=Instance.new("TextLabel"); rLbl.AutomaticSize=Enum.AutomaticSize.X
        rLbl.Size=UDim2.new(0,0,1,0); rLbl.BackgroundTransparency=1
        rLbl.Text="("..sug.reason..")"; rLbl.TextColor3=Color3.fromRGB(90,80,110)
        rLbl.Font=Enum.Font.Gotham; rLbl.TextSize=11
        rLbl.TextXAlignment=Enum.TextXAlignment.Left; rLbl.Parent=row
    end
end

local function setStatus(color)
    statusDot.BackgroundColor3=color
    task.delay(1.2,function() statusDot.BackgroundColor3=T.DOT_OK end)
end

local function runPreview()
    isUpdatingPreview=true
    local raw=inputBox.Text
    if trim(raw)=="" then
        previewText.Text=""; improveText.Text=""; currentImproved=""
        updateChangeTags({}); updateUpgradeTags({}); isUpdatingPreview=false; return
    end
    local corrected,changes,improved,upgrades=correctText(raw)
    previewText.Text=corrected; improveText.Text=improved; currentImproved=improved
    if corrected~=raw or improved~=corrected then
        logoDot.BackgroundColor3=T.DOT_BUSY
        task.delay(0.6,function() logoDot.BackgroundColor3=T.ACCENT end)
    end
    updateChangeTags(changes); updateUpgradeTags(upgrades); isUpdatingPreview=false
end

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
    if isUpdatingPreview then return end
    debounceTime=tick()
end)
RunService.Heartbeat:Connect(function()
    if debounceTime>0 and (tick()-debounceTime)>=DEBOUNCE then debounceTime=0; runPreview() end
end)

-- ============================================================
-- SECTION 8: BUTTON ACTIONS
-- ============================================================

-- Standard tab
btnSend.Activated:Connect(function()
    local raw=inputBox.Text; if trim(raw)=="" then return end
    local corrected=correctText(raw)
    if sendToChat(corrected) then
        setStatus(T.DOT_OK); inputBox.Text=""; previewText.Text=""
        improveText.Text=""; currentImproved=""; updateChangeTags({}); updateUpgradeTags({})
    else setStatus(T.DOT_ERR) end
end)

btnCopy.Activated:Connect(function()
    local raw=inputBox.Text; if trim(raw)=="" then return end
    local corrected=correctText(raw)
    pcall(function() setclipboard(corrected) end)
    btnCopy.BackgroundColor3=T.DOT_OK; task.delay(0.5,function() btnCopy.BackgroundColor3=T.BTN_COPY end)
    setStatus(T.DOT_OK)
end)

btnPaste.Activated:Connect(function()
    local ok,pasted=pcall(function() return getclipboard() end)
    if ok and type(pasted)=="string" and #pasted>0 then
        inputBox.Text=pasted; runPreview(); setStatus(T.DOT_OK)
    else setStatus(T.DOT_ERR) end
end)

btnClear.Activated:Connect(function()
    inputBox.Text=""; previewText.Text=""; improveText.Text=""; currentImproved=""
    updateChangeTags({}); updateUpgradeTags({})
end)

btnUseImproved.Activated:Connect(function()
    if trim(currentImproved)=="" then return end
    inputBox.Text=currentImproved; runPreview(); setStatus(T.DOT_OK)
end)

btnSendImproved.Activated:Connect(function()
    if trim(currentImproved)=="" then return end
    if sendToChat(currentImproved) then
        setStatus(T.DOT_OK); inputBox.Text=""; previewText.Text=""
        improveText.Text=""; currentImproved=""; updateChangeTags({}); updateUpgradeTags({})
    else setStatus(T.DOT_ERR) end
end)

-- ✦ Deep Analysis "Analyze" button
btnAnalyze.Activated:Connect(function()
    local raw=inputBox.Text
    if trim(raw)=="" then
        analysisStatus.Text="⚠ No text entered. Type in the Standard tab first."
        analysisStatus.TextColor3=T.DOT_ERR; return
    end

    -- Visual loading state
    btnAnalyze.Text="⏳  Analyzing..."; btnAnalyze.BackgroundColor3=Color3.fromRGB(80,60,140)
    analysisStatus.Text="Calling AI engine — this may take 2–5 seconds..."
    analysisStatus.TextColor3=T.DOT_BUSY
    logoDot.BackgroundColor3=T.DOT_BUSY

    callDeepAnalysis(raw,
        function(result)
            -- Success
            renderDeepAnalysis(result)
            analysisStatus.Text="✓ Analysis complete  ·  "..#(result.word_analysis or {}).." words analyzed"
            analysisStatus.TextColor3=T.DOT_OK
            btnAnalyze.Text="🔍  Run Deep Analysis (AI)"; btnAnalyze.BackgroundColor3=T.BTN_ANALYZE
            logoDot.BackgroundColor3=T.ACCENT
        end,
        function(errMsg)
            -- Failure
            analysisStatus.Text="✕ Error: "..tostring(errMsg):sub(1,80)
            analysisStatus.TextColor3=T.DOT_ERR
            btnAnalyze.Text="🔍  Run Deep Analysis (AI)"; btnAnalyze.BackgroundColor3=T.BTN_ANALYZE
            logoDot.BackgroundColor3=T.DOT_ERR
            task.delay(1.5,function() logoDot.BackgroundColor3=T.ACCENT end)
        end
    )
end)

-- ============================================================
-- SECTION 9: TAB SWITCHING
-- ============================================================
local function setTab(tab)
    if tab=="standard" then
        pageStandard.Visible=true; pageDeep.Visible=false
        tabStandard.BackgroundColor3=T.TAB_ACTIVE; tabStandard.TextColor3=Color3.fromRGB(255,255,255)
        tabDeep.BackgroundColor3=T.TAB_IDLE; tabDeep.TextColor3=T.TEXT_DIM
    else
        pageStandard.Visible=false; pageDeep.Visible=true
        tabDeep.BackgroundColor3=T.TAB_ACTIVE; tabDeep.TextColor3=Color3.fromRGB(255,255,255)
        tabStandard.BackgroundColor3=T.TAB_IDLE; tabStandard.TextColor3=T.TEXT_DIM
    end
end

tabStandard.Activated:Connect(function() setTab("standard") end)
tabDeep.Activated:Connect(function() setTab("deep") end)
setTab("standard")  -- default

-- ============================================================
-- SECTION 10: DRAG SYSTEM
-- ============================================================
local dragging=false; local dragStart=Vector2.new(); local panelStart=Vector2.new()
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or
       input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position
        panelStart=Vector2.new(panel.AbsolutePosition.X,panel.AbsolutePosition.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or
       input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType==Enum.UserInputType.MouseMovement or
       input.UserInputType==Enum.UserInputType.Touch then
        local delta=Vector2.new(input.Position.X-dragStart.X,input.Position.Y-dragStart.Y)
        local newX=panelStart.X+delta.X; local newY=panelStart.Y+delta.Y
        local vpSize=workspace.CurrentCamera.ViewportSize
        newX=math.clamp(newX,0,vpSize.X-panel.AbsoluteSize.X)
        newY=math.clamp(newY,0,vpSize.Y-panel.AbsoluteSize.Y)
        panel.Position=UDim2.new(0,newX,0,newY)
    end
end)

-- ============================================================
-- SECTION 11: TextChatService BACKGROUND PATCH
-- ============================================================
local function patchChannel(ch)
    if ch:GetAttribute("GrammarPatched") then return end
    ch:SetAttribute("GrammarPatched",true)
    local orig=ch.SendAsync; local guard=false
    ch.SendAsync=function(self,msg,...)
        if guard then return orig(self,msg,...) end
        guard=true; local fixed=correctText(msg)
        local r=orig(self,fixed,...); guard=false; return r
    end
end
local function initChatPatch()
    if TextChatService.ChatVersion~=Enum.ChatVersion.TextChatService then return end
    local chans=TextChatService:FindFirstChild("TextChannels")
    if not chans then chans=TextChatService:WaitForChild("TextChannels",8) end
    if not chans then return end
    for _,ch in ipairs(chans:GetChildren()) do
        if ch:IsA("TextChannel") then patchChannel(ch) end
    end
    chans.ChildAdded:Connect(function(ch)
        if ch:IsA("TextChannel") then task.defer(function() patchChannel(ch) end) end
    end)
end
task.spawn(initChatPatch)

-- ============================================================
print("[GrammarPro v3] ✓ Loaded. Standard + Groq Deep Analysis tabs live.")

end, function(e)
    warn("[GrammarPro] Fatal error: "..tostring(e))
    warn(debug.traceback())
end)
if not _ok then warn("[GrammarPro] Script failed to load. See error above.") end
