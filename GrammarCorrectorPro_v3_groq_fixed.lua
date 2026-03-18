--[[
=================================================================
  KOJI — Auto-Correct on Crack  v3.0
  UI: authentic Roblox chat window (tab bar, chat area, input bar)
  Tabs: "Correct" | "Settings"
  Drag: grab the tab bar
  Resize: drag the ⇲ corner handle
=================================================================
--]]

local _ok = xpcall(function()

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextChatService  = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

if RunService:IsServer() then warn("[Koji] Must be a LocalScript."); return end

-- ============================================================
-- SECTION 1: TOGGLE FLAGS
-- ============================================================
local togPunct = true
local togAC    = true
local togCap   = true

-- ============================================================
-- SECTION 2: DICTIONARIES
-- ============================================================
local WORD_FIXES = {
    -- ── Contractions & pronouns ───────────────────────────────
    ["im"]="I'm",["ive"]="I've",["ill"]="I'll",["id"]="I'd",
    ["your"]="you're",["youd"]="you'd",["youll"]="you'll",["youve"]="you've",
    ["youre"]="you're",["ur"]="your",["yr"]="your",
    ["u"]="you",["ya"]="you",["yuo"]="you",
    ["theyre"]="they're",["theyd"]="they'd",["theyve"]="they've",["theyll"]="they'll",
    ["itd"]="it'd",["itll"]="it'll",["itss"]="it's",
    ["wed"]="we'd",["weve"]="we've",["well"]="we'll",["were"]="we're",
    ["hed"]="he'd",["hes"]="he's",["hell"]="he'll",
    ["shed"]="she'd",["shes"]="she's",["shell"]="she'll",
    ["whos"]="who's",["whod"]="who'd",["wholl"]="who'll",["whove"]="who've",
    ["thats"]="that's",["theres"]="there's",["whats"]="what's",
    ["hows"]="how's",["wheres"]="where's",["whens"]="when's",["lets"]="let's",
    -- ── Negations ─────────────────────────────────────────────
    ["dont"]="don't",["dnt"]="don't",["dno't"]="don't",
    ["doesnt"]="doesn't",["didnt"]="didn't",
    ["wont"]="won't",["wouldnt"]="wouldn't",["couldnt"]="couldn't",
    ["shouldnt"]="shouldn't",["mustnt"]="mustn't",["neednt"]="needn't",
    ["mightnt"]="mightn't",["oughtnt"]="oughtn't",["hadnt"]="hadn't",
    ["hasnt"]="hasn't",["havent"]="haven't",["isnt"]="isn't",
    ["wasnt"]="wasn't",["werent"]="weren't",["arent"]="aren't",
    ["aint"]="isn't",["cannot"]="can't",["cant"]="can't",["cantt"]="can't",
    ["wudnt"]="wouldn't",["wldnt"]="wouldn't",["wudnt"]="wouldn't",
    -- ── Common slang / abbreviations ─────────────────────────
    ["idk"]="I don't know",["idkno"]="I don't know",["ikno"]="I don't know",
    ["idc"]="I don't care",["imo"]="in my opinion",
    ["imho"]="in my honest opinion",["irl"]="in real life",
    ["ikr"]="I know, right",["iirc"]="if I recall correctly",
    ["tbh"]="to be honest",["ngl"]="not going to lie",
    ["btw"]="by the way",["bty"]="by the way",["bytheway"]="by the way",
    ["fwiw"]="for what it's worth",["fyi"]="for your information",
    ["omg"]="oh my god",["omgg"]="oh my god",
    ["brb"]="be right back",["gtg"]="got to go",["afk"]="away from keyboard",
    ["smh"]="shaking my head",["nvm"]="never mind",["np"]="no problem",
    ["ty"]="thank you",["yw"]="you're welcome",["urw"]="you're welcome",
    ["plz"]="please",["pls"]="please",["plss"]="please",
    ["thx"]="thanks",["thnx"]="thanks",["thanx"]="thanks",["thanq"]="thanks",
    ["tx"]="thanks",["thxx"]="thanks",["thnks"]="thanks",
    ["kk"]="okay",["okey"]="okay",["oke"]="okay",["okkk"]="okay",
    ["okayy"]="okay",["kkk"]="okay",["kkay"]="okay",["ay"]="okay",
    ["aight"]="alright",["alrighty"]="alright",
    ["heyy"]="hey",["heeey"]="hey",["hii"]="hi",["hiii"]="hi",
    ["helloo"]="hello",["helo"]="hello",["heloo"]="hello",
    ["yess"]="yes",["yeess"]="yes",["yee"]="yes",
    ["nooo"]="no",["noo"]="no",["naah"]="nah",["naa"]="nah",
    ["nm"]="not much",["fr"]="for",["nvm"]="never mind",
    -- ── Modal/aux verbs ───────────────────────────────────────
    ["wanna"]="want to",["wannaah"]="want to",["wannaaa"]="want to",
    ["wonna"]="want to",["wan"]="want to",["wnt"]="want",
    ["gonna"]="going to",["gona"]="going to",["gon"]="going to",
    ["gotta"]="got to",["kinda"]="kind of",["kindaa"]="kind of",
    ["sorta"]="sort of",["hafta"]="have to",["oughta"]="ought to",
    ["betcha"]="bet you",["coulda"]="could have",["woulda"]="would have",
    ["shoulda"]="should have",["musta"]="must have",["mighta"]="might have",
    ["lotta"]="lot of",["outta"]="out of",["lotsa"]="lots of",
    ["dunno"]="don't know",["gimme"]="give me",["lemme"]="let me",
    ["cmon"]="come on",["c'mon"]="come on",
    ["yall"]="y'all",["ya'll"]="y'all",
    ["wud"]="would",["wld"]="would",["wuld"]="would",["whould"]="would",
    ["woudl"]="would",["woul"]="would",
    ["cud"]="could",["coudl"]="could",["coul"]="could",["coud"]="could",
    ["shud"]="should",["shoudl"]="should",["shoud"]="should",["shul"]="should",
    ["hav"]="have",["havv"]="have",["haave"]="have",["hve"]="have",
    -- ── Short forms / texting ─────────────────────────────────
    ["b4"]="before",["gr8"]="great",["l8r"]="later",
    ["cuz"]="because",["bcuz"]="because",["bcoz"]="because",
    ["bcz"]="because",["bec"]="because",
    ["tho"]="though",["thou"]="though",["thogh"]="though",["thuh"]="though",
    ["thn"]="then",["tehn"]="then",["thenn"]="then",
    ["thru"]="through",["thruu"]="through",["thruugh"]="through",
    ["somethin"]="something",["somthing"]="something",["sumthing"]="something",
    ["anythin"]="anything",["anythng"]="anything",
    ["nothin"]="nothing",["nuthing"]="nothing",["notting"]="nothing",
    ["prolly"]="probably",["probaly"]="probably",["probbly"]="probably",
    ["srry"]="sorry",["sory"]="sorry",["sry"]="sorry",["sorri"]="sorry",
    ["srryy"]="sorry",["soory"]="sorry",["soree"]="sorry",["soryy"]="sorry",
    ["sawry"]="sorry",["sawrryy"]="sorry",
    ["tht"]="that",["thit"]="that",["taht"]="that",["tath"]="that",
    ["thatt"]="that",["thatss"]="that's",
    ["wat"]="what",["wut"]="what",["whaat"]="what",["wha"]="what",
    ["whatt"]="what",["wha"]="what",
    ["wen"]="when",["whn"]="when",["wne"]="when",["whe"]="when",
    ["wich"]="which",["whcih"]="which",["wihch"]="which",
    ["whitch"]="which",["whch"]="which",["whch"]="which",
    ["liek"]="like",["lik"]="like",["liik"]="like",["likke"]="like",
    ["lkike"]="like",["liike"]="like",
    ["realy"]="really",["reeli"]="really",["reelly"]="really",
    ["realy"]="really",["reely"]="really",["relly"]="really",
    ["reaally"]="really",["realli"]="really",["raely"]="really",
    ["reeliy"]="really",["realyy"]="really",
    ["tru"]="true",["truue"]="true",["treu"]="true",["truu"]="true",
    ["fal"]="false",["fals"]="false",["fale"]="false",
    ["happe"]="happy",["hapy"]="happy",["happpy"]="happy",
    ["sadn"]="sad",["saad"]="sad",["sadd"]="sad",
    ["exited"]="excited",["exiteed"]="excited",["exitd"]="excited",
    ["completly"]="completely",["completlyy"]="completely",["completley"]="completely",
    ["somhow"]="somehow",["somhoww"]="somehow",["sumhow"]="somehow",
    ["curently"]="currently",["currntly"]="currently",
    ["frst"]="first",["frist"]="first",["frstt"]="first",["firt"]="first",
    ["latly"]="lately",["latelyy"]="lately",
    -- ── Common words / filler ─────────────────────────────────
    ["teh"]="the",["hte"]="the",["tje"]="the",["tjhe"]="the",
    ["thr"]="the",["th"]="the",["te"]="the",
    ["adn"]="and",["nad"]="and",["annd"]="and",["ad"]="and",
    ["nto"]="not",["waht"]="what",["yuo"]="you",
    ["wiil"]="will",["thsi"]="this",
    ["ahve"]="have",["ahd"]="had",
    ["jist"]="just",["jst"]="just",["jus"]="just",["jusst"]="just",
    ["knwo"]="know",["kown"]="know",["knw"]="know",
    ["ned"]="need",["needd"]="need",["nead"]="need",
    ["gud"]="good",["goood"]="good",["godo"]="good",["gd"]="good",
    ["gdoo"]="good",["gooodd"]="good",["guddd"]="good",
    ["baddd"]="bad",["badd"]="bad",["bd"]="bad",["baad"]="bad",
    ["goimng"]="going",["goin"]="going",["goinng"]="going",
    ["comig"]="coming",["cming"]="coming",["commingg"]="coming",
    ["thik"]="think",["thnk"]="think",["thnking"]="thinking",
    ["imporant"]="important",["importnt"]="important",["imprtnt"]="important",
    ["imprtant"]="important",["impotant"]="important",["importannt"]="important",
    -- ── Typos / misspellings ─────────────────────────────────
    ["abvailable"]="available",["avalable"]="available",["avialable"]="available",["avalible"]="available",
    ["accross"]="across",["acrosss"]="across",["acros"]="across",["accros"]="across",
    ["acess"]="access",["acesss"]="access",
    ["acheive"]="achieve",["acheived"]="achieved",["acheiving"]="achieving",
    ["acknowlege"]="acknowledge",["acknowlegde"]="acknowledge",["acknowledgge"]="acknowledge",
    ["acomodate"]="accommodate",["accomodate"]="accommodate",["acommodate"]="accommodate",
    ["acomodation"]="accommodation",["accomodation"]="accommodation",
    ["actully"]="actually",
    ["adress"]="address",["adres"]="address",["adresss"]="address",["adrees"]="address",
    ["adventage"]="advantage",
    ["agressive"]="aggressive",["agression"]="aggression",
    ["alot"]="a lot",["alottt"]="a lot",
    ["amature"]="amateur",
    ["amazingg"]="amazing",
    ["ammount"]="amount",
    ["aniversary"]="anniversary",
    ["anywayz"]="anyway",
    ["appologies"]="apologies",["appologiess"]="apologies",
    ["appriciate"]="appreciate",
    ["approriate"]="appropriate",["approrpiate"]="appropriate",["approuch"]="approach",
    ["aproximately"]="approximately",
    ["arguement"]="argument",["arguemented"]="argument",
    ["articel"]="article",["artical"]="article",
    ["assasinate"]="assassinate",
    ["assit"]="assist",["assistent"]="assistant",
    ["atempt"]="attempt",["attatched"]="attached",
    ["athor"]="author",
    ["augest"]="august",
    ["awfull"]="awful",
    ["bakc"]="back",["blanck"]="blank",
    ["basicly"]="basically",
    ["beatiful"]="beautiful",["beutiful"]="beautiful",["biutiful"]="beautiful",
    ["beautifull"]="beautiful",
    ["becas"]="because",["becaue"]="because",["becasue"]="because",
    ["becuase"]="because",["beacuse"]="because",["becouse"]="because",
    ["becaus"]="because",["bcause"]="because",["becauss"]="because",
    ["becomeing"]="becoming",
    ["beggining"]="beginning",["begining"]="beginning",["beginingg"]="beginning",
    ["beleave"]="believe",["beleive"]="believe",["belive"]="believe",
    ["beleve"]="believe",["bileve"]="believe",["beleaved"]="believed",
    ["believd"]="believed",["belivd"]="believed",
    ["beleif"]="belief",
    ["benifical"]="beneficial",["benifit"]="benefit",
    ["berief"]="brief",
    ["beter"]="better",
    ["bizzare"]="bizarre",
    ["bn"]="been",["ben"]="been",["bne"]="been",
    ["buisy"]="busy",
    ["buisness"]="business",["busines"]="business",["busniess"]="business",
    ["calandar"]="calendar",["calender"]="calendar",["calenderr"]="calendar",
    ["caluclate"]="calculate",
    ["cange"]="change",["chaged"]="changed",
    ["cann"]="can",
    ["carrerist"]="careerist",["carrer"]="career",
    ["catagory"]="category",["catagorys"]="categories",
    ["celabrate"]="celebrate",
    ["cemetary"]="cemetery",
    ["ceratain"]="certain",
    ["charachter"]="character",
    ["chating"]="chatting",
    ["cheif"]="chief",["choosen"]="chosen",
    ["childern"]="children",["chldren"]="children",["childrn"]="children",
    ["cirlce"]="circle",
    ["collage"]="college",["colleg"]="college",["collagee"]="college",
    ["collegue"]="colleague",["colleg"]="colleague",
    ["comand"]="command",["comandd"]="command",
    ["commited"]="committed",["commitee"]="committee",["comittment"]="commitment",
    ["committment"]="commitment",["commitmnt"]="commitment",
    ["comparision"]="comparison",["comparrison"]="comparison",
    ["conciouss"]="conscious",["concious"]="conscious",["concieve"]="conceive",
    ["concerned"]="concerned",
    ["congradulate"]="congratulate",["congradulations"]="congratulations",
    ["conitnue"]="continue",["coninute"]="continue",
    ["conncet"]="connect",["connecct"]="connect",
    ["controversal"]="controversial",
    ["corupt"]="corrupt",
    ["correspondance"]="correspondence",
    ["coughted"]="caught",["cought"]="caught",
    ["creat"]="create",["creavite"]="creative",
    ["curiouse"]="curious",["curiousity"]="curiosity",
    ["decission"]="decision",["descision"]="decision",
    ["definate"]="definite",["definit"]="definite",["definitt"]="definite",
    ["definately"]="definitely",["definatly"]="definitely",["definetely"]="definitely",
    ["definetly"]="definitely",["definitly"]="definitely",["definitley"]="definitely",
    ["defintly"]="definitely",["definittely"]="definitely",
    ["deliever"]="deliver",
    ["dependant"]="dependent",["independant"]="independent",
    ["descover"]="discover",
    ["desparate"]="desperate",
    ["diferent"]="different",["dificult"]="difficult",["diffrent"]="different",
    ["dimention"]="dimension",
    ["disapoint"]="disappoint",["dissapoint"]="disappoint",
    ["disapointed"]="disappointed",
    ["dissapear"]="disappear",["dissapearing"]="disappearing",
    ["defint"]="definition",["defintion"]="definition",
    ["embarass"]="embarrass",["embarassed"]="embarrassed",["embarased"]="embarrassed",
    ["embarassing"]="embarrassing",["embarasing"]="embarrassing",["embarrasing"]="embarrassing",
    ["embarras"]="embarrass",["embarrasss"]="embarrass",
    ["enviroment"]="environment",["envirement"]="environment",["enviromentt"]="environment",
    ["enviromental"]="environmental",["enviromentl"]="environmental",
    ["enviro"]="environment",["environmnt"]="environment",
    ["equiptment"]="equipment",
    ["especialy"]="especially",["expecially"]="especially",["espescially"]="especially",
    ["excellant"]="excellent",["excelent"]="excellent",["excllent"]="excellent",
    ["existancee"]="existence",["existance"]="existence",
    ["exmaple"]="example",["exmple"]="example",
    ["expereince"]="experience",["experiance"]="experience",["expierence"]="experience",
    ["extreem"]="extreme",
    ["exagerate"]="exaggerate",
    ["facinating"]="fascinating",["fasinating"]="fascinating",["fascinatingg"]="fascinating",
    ["facinated"]="fascinated",["fasinated"]="fascinated",["fascinatedd"]="fascinated",
    ["fascinateing"]="fascinating",
    ["famouse"]="famous",["famus"]="famous",["famouss"]="famous",
    ["familar"]="familiar",
    ["fasion"]="fashion",
    ["felxible"]="flexible",
    ["finacial"]="financial",
    ["finnaly"]="finally",
    ["focous"]="focus",
    ["foriegn"]="foreign",["foreignn"]="foreign",["forieng"]="foreign",
    ["formaly"]="formally",
    ["foward"]="forward",["forwad"]="forward",["fowardd"]="forward",
    ["freindly"]="friendly",
    ["freind"]="friend",["firend"]="friend",["frind"]="friend",
    ["freinds"]="friends",["frndss"]="friends",["frens"]="friends",["freindss"]="friends",
    ["frnd"]="friend",["fren"]="friend",
    ["functoin"]="function",["functin"]="function",["funtion"]="function",
    ["funtional"]="functional",
    ["futher"]="further",
    ["gaurantee"]="guarantee",
    ["gaurd"]="guard",
    ["gentel"]="gentle",
    ["geniusss"]="genius",
    ["goverment"]="government",["govrnment"]="government",["govemment"]="government",
    ["govermental"]="governmental",
    ["grate"]="great",["graet"]="great",["gret"]="great",
    ["gratefull"]="grateful",["greatful"]="grateful",["gratefulll"]="grateful",
    ["gratfull"]="grateful",["gratefullly"]="gratefully",
    ["grammer"]="grammar",
    ["happend"]="happened",["hapennd"]="happened",["happnd"]="happened",
    ["happendd"]="happened",
    ["harrass"]="harass",["harrased"]="harassed",["haras"]="harass",
    ["harrassed"]="harassed",
    ["harrassment"]="harassment",["harasment"]="harassment",["harassmentt"]="harassment",
    ["heigth"]="height",["hieght"]="height",["hight"]="height",["hieghts"]="heights",
    ["hesistate"]="hesitate",
    ["honestley"]="honestly",
    ["humerus"]="humorous",["humorouse"]="humorous",
    ["idicate"]="indicate",["identifiy"]="identify",["indicatee"]="indicate",
    ["imediately"]="immediately",["immedietly"]="immediately",["immediatly"]="immediately",
    ["immediatlyy"]="immediately",
    ["importent"]="important",
    ["imaginativee"]="imaginative",
    ["inconvienent"]="inconvenient",["inconvinent"]="inconvenient",
    ["inconveniant"]="inconvenient",["inconvience"]="inconvenience",
    ["indepent"]="independent",["indepndent"]="independent",
    ["infomation"]="information",["informtion"]="information",
    ["innocense"]="innocence",
    ["insistant"]="insistent",["insistentt"]="insistent",
    ["inteligent"]="intelligent",["inteligence"]="intelligence",
    ["interupt"]="interrupt",["interupted"]="interrupted",
    ["introducion"]="introduction",["intrduction"]="introduction",
    ["irresistablee"]="irresistible",["irresistable"]="irresistible",
    ["judgement"]="judgment",["judgemnt"]="judgment",["judgemental"]="judgmental",
    ["knowlege"]="knowledge",["knowlegde"]="knowledge",["knowlage"]="knowledge",
    ["knowldge"]="knowledge",["knwledge"]="knowledge",
    ["knowlegeable"]="knowledgeable",
    ["labratoryy"]="laboratory",["labratory"]="laboratory",
    ["lenght"]="length",["lengthh"]="length",["lenghth"]="length",
    ["liasion"]="liaison",["liason"]="liaison",["lison"]="liaison",
    ["liasonn"]="liaison",["liaisonn"]="liaison",
    ["lightening"]="lightning",["lightining"]="lightning",
    ["littel"]="little",["littlee"]="little",
    ["livly"]="lively",["livelyy"]="lively",
    ["maintainance"]="maintenance",["maintenence"]="maintenance",["maintainancee"]="maintenance",
    ["managment"]="management",["managmentt"]="management",["managmnt"]="management",
    ["managament"]="management",["managemnt"]="management",
    ["manouver"]="manoeuvre",["manovre"]="manoeuvre",["manoevre"]="manoeuvre",
    ["manoevour"]="manoeuvre",
    ["marraige"]="marriage",["marraigee"]="marriage",
    ["medeval"]="medieval",["medival"]="medieval",["medievall"]="medieval",
    ["mesage"]="message",["mesagee"]="message",["messgae"]="message",["msgae"]="message",
    ["millenium"]="millennium",["milleniume"]="millennium",
    ["miniture"]="miniature",["minituree"]="miniature",
    ["mischevious"]="mischievous",["mischievious"]="mischievous",["mischeivous"]="mischievous",
    ["mispell"]="misspell",["misspel"]="misspell",
    ["mispelled"]="misspelled",
    ["momment"]="moment",
    ["naturaly"]="naturally",
    ["neccessary"]="necessary",["necesary"]="necessary",["necesarry"]="necessary",
    ["neccesary"]="necessary",["necessery"]="necessary",
    ["neigbour"]="neighbour",["neibor"]="neighbour",["neighbur"]="neighbour",
    ["neigbourhood"]="neighbourhood",
    ["nife"]="knife",["kife"]="knife",["knfe"]="knife",
    ["noticable"]="noticeable",
    ["ocassionally"]="occasionally",["occassion"]="occasion",["ocassion"]="occasion",
    ["ocassionn"]="occasion",
    ["occured"]="occurred",["occurrred"]="occurred",["ocurred"]="occurred",
    ["occuring"]="occurring",["ocuring"]="occurring",["ocurrng"]="occurring",
    ["occurance"]="occurrence",["occurencee"]="occurrence",["ocurrence"]="occurrence",
    ["offficial"]="official",["offical"]="official",["oficial"]="official",["officail"]="official",
    ["ommision"]="omission",["ommission"]="omission",
    ["oppertunity"]="opportunity",["oppertunities"]="opportunities",
    ["paralell"]="parallel",["parralel"]="parallel",["paralel"]="parallel",
    ["parliment"]="parliament",["parlament"]="parliament",
    ["parliement"]="parliament",["parlimentt"]="parliament",
    ["particullar"]="particular",
    ["pasportt"]="passport",["pasport"]="passport",
    ["peculier"]="peculiar",["pecular"]="peculiar",
    ["perfomance"]="performance",["perfom"]="perform",
    ["personel"]="personnel",["personnell"]="personnel",
    ["persistant"]="persistent",["persistantt"]="persistent",
    ["phsyical"]="physical",["phsical"]="physical",
    ["posession"]="possession",["possesion"]="possession",
    ["posibility"]="possibility",["posible"]="possible",
    ["prefered"]="preferred",["preferredd"]="preferred",
    ["preciouus"]="precious",["preciouse"]="precious",
    ["privelege"]="privilege",["priviledge"]="privilege",["privelegee"]="privilege",
    ["probaly"]="probably",
    ["proffesional"]="professional",
    ["propoganda"]="propaganda",
    ["psycology"]="psychology",
    ["publically"]="publicly",["publicaly"]="publicly",["publickly"]="publicly",
    ["publicallyy"]="publicly",
    ["questionaire"]="questionnaire",["quesitons"]="questions",["quesiton"]="question",
    ["quik"]="quick",["quikc"]="quick",["qick"]="quick",
    ["qucikly"]="quickly",["quckly"]="quickly",["quikly"]="quickly",
    ["raely"]="really",
    ["reccomend"]="recommend",["recomend"]="recommend",["recmmend"]="recommend",
    ["recomendd"]="recommend",
    ["recieve"]="receive",["recive"]="receive",["reieve"]="receive",["recieeve"]="receive",
    ["recieved"]="received",
    ["reciept"]="receipt",["receit"]="receipt",["recept"]="receipt",
    ["relevent"]="relevant",["releventt"]="relevant",
    ["religous"]="religious",["religouss"]="religious",
    ["remeber"]="remember",["remmber"]="remember",
    ["repitition"]="repetition",
    ["resistence"]="resistance",["resistantt"]="resistant",
    ["responsability"]="responsibility",
    ["rythm"]="rhythm",["rythem"]="rhythm",["rythmic"]="rhythmic",
    ["safteey"]="safety",["saftey"]="safety",
    ["sargent"]="sergeant",
    ["scedule"]="schedule",["scheduel"]="schedule",["shcedule"]="schedule",
    ["secretaryy"]="secretary",["secretery"]="secretary",
    ["seperate"]="separate",["seperete"]="separate",["seperat"]="separate",
    ["seperated"]="separated",["sepereted"]="separated",
    ["seperately"]="separately",["seperatly"]="separately",["seperateley"]="separately",
    ["separatelyy"]="separately",
    ["sieze"]="seize",["siezz"]="seize",
    ["similliar"]="similar",["similiar"]="similar",
    ["sincerelly"]="sincerely",["sincerly"]="sincerely",
    ["societyy"]="society",["soceity"]="society",
    ["speach"]="speech",
    ["strenght"]="strength",["strengh"]="strength",
    ["studing"]="studying",
    ["succesful"]="successful",["sucessful"]="successful",["succesfull"]="successful",
    ["suprise"]="surprise",["suprised"]="surprised",
    ["suprisingly"]="surprisingly",["suprisinglyy"]="surprisingly",
    ["taht"]="that",["tath"]="that",
    ["tatoo"]="tattoo",["tatto"]="tattoo",
    ["tehcnology"]="technology",["tehcnical"]="technical",
    ["temperment"]="temperament",
    ["tendancy"]="tendency",
    ["therefor"]="therefore",
    ["threashold"]="threshold",
    ["tommorrow"]="tomorrow",["tommorow"]="tomorrow",["tomorow"]="tomorrow",
    ["tomorroww"]="tomorrow",
    ["tounge"]="tongue",["toungee"]="tongue",
    ["transfered"]="transferred",
    ["transistion"]="transition",["trasition"]="transition",
    ["truely"]="truly",["trulyy"]="truly",["truelyy"]="truly",
    ["twelth"]="twelfth",
    ["tyrany"]="tyranny",["tyran"]="tyrant",["tyrantt"]="tyrant",
    ["unneccessary"]="unnecessary",["unneccessarry"]="unnecessary",
    ["unfortunatly"]="unfortunately",["unfortunatlyy"]="unfortunately",
    ["univeristy"]="university",["univeristyy"]="university",
    ["untill"]="until",["untilll"]="until",["untl"]="until",
    ["usualy"]="usually",
    ["vaccum"]="vacuum",["vaccuum"]="vacuum",["vacum"]="vacuum",
    ["vaccuumed"]="vacuumed",
    ["vegitable"]="vegetable",
    ["vehiclle"]="vehicle",["vehicule"]="vehicle",
    ["visability"]="visibility",
    ["voilence"]="violence",
    ["volunter"]="volunteer",
    ["wellcome"]="welcome",
    ["wether"]="whether",
    ["wierd"]="weird",["weirdd"]="weird",["wird"]="weird",["wierdd"]="weird",["wirred"]="weird",
    ["wier"]="wire",["wiire"]="wire",["wre"]="wire",
    ["wich"]="which",
    ["writting"]="writing",["writen"]="written",["writtingg"]="writing",
    ["xmas"]="Christmas",["chrismas"]="Christmas",["christmass"]="Christmas",
    ["xylaphone"]="xylophone",["xylaphon"]="xylophone",["xylopone"]="xylophone",
    ["yatch"]="yacht",["yaht"]="yacht",
    ["yeild"]="yield",["yeilded"]="yielded",
    ["yesturday"]="yesterday",["yesterdayy"]="yesterday",["yestday"]="yesterday",
    ["lettter"]="letter",["leter"]="letter",["latterr"]="letter",
    ["ploblem"]="problem",["prblm"]="problem",["problm"]="problem",
    ["plobems"]="problems",
    ["mistkae"]="mistake",["msitake"]="mistake",["mistaek"]="mistake",
    ["wrd"]="word",["wrod"]="word",["woord"]="word",
    ["texxt"]="text",["teext"]="text",
    ["nad"]="and",["ahve"]="have",
    ["thsi"]="this",["hte"]="the",["tje"]="the",["tjhe"]="the",["thr"]="the",
    -- ── Extra entries from all user lists ────────────────────
    ["gud"]="good",["goood"]="good",["gdoo"]="good",["godo"]="good",
    ["gd"]="good",["gooodd"]="good",["guddd"]="good",
    ["bn"]="been",["ben"]="been",["bne"]="been",
    ["nife"]="knife",["kife"]="knife",["knfe"]="knife",
    ["tru"]="true",["truue"]="true",["treu"]="true",["truu"]="true",
    ["wier"]="wire",["wiire"]="wire",["wre"]="wire",
    ["liek"]="like",["lik"]="like",["liik"]="like",["likke"]="like",["lkike"]="like",["liike"]="like",
    ["liekly"]="likely",
    ["quik"]="quick",["quikc"]="quick",["qick"]="quick",
    ["qucikly"]="quickly",["quckly"]="quickly",["quikly"]="quickly",
    ["teh"]="the",["th"]="the",["te"]="the",
    ["adn"]="and",["ad"]="and",["annd"]="and",
    ["sory"]="sorry",["sry"]="sorry",["soorry"]="sorry",["srry"]="sorry",
    ["srryy"]="sorry",["soory"]="sorry",["soree"]="sorry",["soryy"]="sorry",
    ["sawry"]="sorry",["sorri"]="sorry",
    ["tht"]="that",["thit"]="that",
    ["wat"]="what",["wut"]="what",["whaat"]="what",["wha"]="what",["whatt"]="what",
    ["plz"]="please",["pls"]="please",["plss"]="please",["plase"]="please",
    ["pleeze"]="please",["pleez"]="please",["plees"]="please",["plese"]="please",
    ["pleass"]="please",
    ["ty"]="thank you",["thanx"]="thanks",["thnx"]="thanks",["thanq"]="thanks",
    ["thannks"]="thanks",["thasnk"]="thanks",["thansk"]="thanks",["thnks"]="thanks",
    ["thxx"]="thanks",["tx"]="thanks",
    ["kk"]="okay",["okey"]="okay",["oke"]="okay",["okkk"]="okay",
    ["okayy"]="okay",["kkk"]="okay",["kkay"]="okay",["ay"]="okay",
    ["omg"]="oh my god",["omgg"]="oh my god",["ohmygod"]="oh my god",["ohmygodd"]="oh my god",
    ["ohh"]="oh",
    ["heeey"]="hey",["heyy"]="hey",["hii"]="hi",["hiii"]="hi",
    ["helloo"]="hello",["helo"]="hello",["heloo"]="hello",
    ["yess"]="yes",["yeess"]="yes",["yee"]="yes",
    ["nooo"]="no",["noo"]="no",["naah"]="nah",["naa"]="nah",
    ["idk"]="I don't know",["dunno"]="don't know",
    ["cuz"]="because",["bcuz"]="because",["bcoz"]="because",["bcz"]="because",["bec"]="because",
    ["tho"]="though",["thou"]="though",["thogh"]="though",["thuh"]="though",
    ["btw"]="by the way",["bty"]="by the way",
    ["im"]="I'm",
    ["ive"]="I've",
    ["ur"]="your",["yr"]="your",
    ["yo"]="your",
    ["r"]="are",
    ["thx"]="thanks",
    ["nm"]="not much",["nvm"]="never mind",
    ["btwn"]="between",["bwen"]="between",
    ["fr"]="for",["fo"]="for",["fow"]="for",
    ["frum"]="from",["frm"]="from",
    ["thru"]="through",["thruu"]="through",["thruugh"]="through",
    ["somethin"]="something",["somthing"]="something",["sumthing"]="something",
    ["anythin"]="anything",["anythng"]="anything",
    ["nothin"]="nothing",["nuthing"]="nothing",["notting"]="nothing",
    ["kinda"]="kind of",["kindaa"]="kind of",["kinnda"]="kind of",
    ["gonna"]="going to",["gona"]="going to",["gon"]="going to",
    ["wanna"]="want to",["wannaah"]="want to",["wan"]="want to",["wannaaa"]="want to",
    ["wonna"]="want to",
    ["becaus"]="because",["becaue"]="because",["becuase"]="because",
    ["tbh"]="to be honest",["idc"]="I don't care",
    ["whn"]="when",["wen"]="when",["wne"]="when",["whe"]="when",
    ["wut"]="what",["whatt"]="what",
    ["whch"]="which",
    ["alot"]="a lot",["alottt"]="a lot",
    ["thnk"]="thank",["than"]="thanks",
    ["frnd"]="friend",["fren"]="friend",["bff"]="best friend",
    ["mthod"]="method",["mthd"]="method",
    ["enviro"]="environment",["environmnt"]="environment",
    ["defintly"]="definitely",
    ["fal"]="false",["fals"]="false",["fale"]="false",
    ["happe"]="happy",["hapy"]="happy",["happpy"]="happy",
    ["sadn"]="sad",["saad"]="sad",["sadd"]="sad",
    ["exited"]="excited",["exiteed"]="excited",["exitd"]="excited",
    ["relly"]="really",["realy"]="really",["reely"]="really",
    ["completly"]="completely",["completlyy"]="completely",["completley"]="completely",
    ["importnt"]="important",["imprtnt"]="important",["imprtant"]="important",
    ["somhow"]="somehow",["somhoww"]="somehow",["sumhow"]="somehow",
    ["prolly"]="probably",["probaly"]="probably",["probbly"]="probably",
    ["curently"]="currently",["currntly"]="currently",
    ["goimng"]="going",["goin"]="going",["goinng"]="going",
    ["comig"]="coming",["cming"]="coming",
    ["thik"]="think",["thnk"]="think",["thnking"]="thinking",
    ["wud"]="would",["wld"]="would",["wuld"]="would",["whould"]="would",["woul"]="would",
    ["cud"]="could",["coudl"]="could",["coul"]="could",["coud"]="could",
    ["shud"]="should",["shoudl"]="should",["shoud"]="should",["shul"]="should",
    ["hav"]="have",["havv"]="have",["haave"]="have",["hve"]="have",
    ["ned"]="need",["needd"]="need",["nead"]="need",
    ["jist"]="just",["jst"]="just",["jus"]="just",["jusst"]="just",
    ["frst"]="first",["frist"]="first",["frstt"]="first",["firt"]="first",
    ["latly"]="lately",["latelyy"]="lately",
    ["imporant"]="important",["importannt"]="important",["impotant"]="important",
    ["ploblem"]="problem",["prblm"]="problem",["problm"]="problem",
    ["plobems"]="problems",
    ["defintion"]="definition",["defint"]="definition",
    ["exmaple"]="example",["exmple"]="example",
    ["raely"]="really",
    ["adrees"]="address",
    ["reciept"]="receipt",["receit"]="receipt",["recept"]="receipt",
    ["tehcnology"]="technology",["tehcnical"]="technical",
    ["messgae"]="message",["msgae"]="message",
    ["posibility"]="possibility",["posible"]="possible",
    ["accross"]="across",["acrosss"]="across",["acros"]="across",
    ["threashold"]="threshold",
    ["strenght"]="strength",["strengh"]="strength",
    ["approriate"]="appropriate",["approrpiate"]="appropriate",
    ["conncet"]="connect",["connecct"]="connect",
    ["functoin"]="function",["functin"]="function",
    ["managament"]="management",["managemnt"]="management",
    ["diferent"]="different",["diffrent"]="different",
    ["reccomend"]="recommend",["recomend"]="recommend",["recmmend"]="recommend",
    ["perfomance"]="performance",["perfom"]="perform",
    ["beleif"]="belief",
    ["enviromental"]="environmental",["enviromentl"]="environmental",
    ["transistion"]="transition",["trasition"]="transition",
    ["yw"]="you're welcome",["yorw"]="you're welcome",["urw"]="you're welcome",
    ["yrw"]="you're welcome",
    ["dnt"]="don't",["dno't"]="don't",
    ["cantt"]="can't",["wudnt"]="wouldn't",["wldnt"]="wouldn't",
    ["aight"]="alright",["alrighty"]="alright",
    ["mhmm"]="mhmm",
    ["realli"]="really",["reaally"]="really",["reeliy"]="really",["realyy"]="really",
    ["gooodd"]="good",
    ["thenn"]="then",["thennn"]="then",["thn"]="then",["tehn"]="then",
    ["wnt"]="want",["wntt"]="want",
    ["wudnt"]="wouldn't",["wuldnt"]="wouldn't",
    ["sawry"]="sorry",
    ["lately"]="lately",
    ["plann"]="plan",["plannn"]="plan",["plaen"]="plan",["plean"]="plan",
    ["bcause"]="because",["becauss"]="because",
    ["thats"]="that's",["thatss"]="that's",
    ["wich"]="which",["whitch"]="which",
    ["thier"]="their",["ther"]="their",["theire"]="their",
    ["hteir"]="their",["thir"]="their",["thar"]="their",
    ["shoudl"]="should",
    ["writen"]="written",
    ["msg"]="message",["mesage"]="message",["mesagee"]="message",["massage"]="message",
    ["absolutly"]="absolutely",
    ["acess"]="access",["acesss"]="access",
    ["adres"]="address",
    ["appologies"]="apologies",
    ["appriciate"]="appreciate",
    ["arguemented"]="argument",
    ["artical"]="article",
    ["assasinate"]="assassinate",
    ["assit"]="assist",
    ["atempt"]="attempt",
    ["attatched"]="attached",
    ["avalible"]="available",["avialable"]="available",["avalable"]="available",
    ["awesom"]="awesome",
    ["beautifull"]="beautiful",["beutiful"]="beautiful",["biutiful"]="beautiful",
    ["benifit"]="benefit",
    ["beter"]="better",
    ["caluclate"]="calculate",
    ["carrer"]="career",
    ["catagory"]="category",
    ["celabrate"]="celebrate",
    ["charachter"]="character",
    ["chating"]="chatting",
    ["childern"]="children",["chldren"]="children",["childrn"]="children",
    ["cirlce"]="circle",
    ["colleg"]="college",["collage"]="college",
    ["comand"]="command",
    ["commited"]="committed",
    ["concieve"]="conceive",
    ["congradulations"]="congratulations",
    ["coninute"]="continue",
    ["controversal"]="controversial",
    ["corupt"]="corrupt",
    ["correspondance"]="correspondence",
    ["creat"]="create",["creavite"]="creative",
    ["curiouse"]="curious",
    ["decission"]="decision",
    ["deliever"]="deliver",
    ["descover"]="discover",
    ["dimention"]="dimension",
    ["disapoint"]="disappoint",["disapointed"]="disappointed",
    ["dissapearing"]="disappearing",
    ["exagerate"]="exaggerate",
    ["excllent"]="excellent",["excellant"]="excellent",
    ["familar"]="familiar",
    ["fasion"]="fashion",
    ["felxible"]="flexible",
    ["finacial"]="financial",
    ["finnaly"]="finally",
    ["focous"]="focus",
    ["formaly"]="formally",
    ["funtional"]="functional",
    ["gaurantee"]="guarantee",
    ["gentel"]="gentle",
    ["geniusss"]="genius",
    ["hesistate"]="hesitate",
    ["honestley"]="honestly",
    ["humerus"]="humorous",["humorouse"]="humorous",
    ["idicate"]="indicate",["identifiy"]="identify",
    ["imaginativee"]="imaginative",
    ["inconvience"]="inconvenience",
    ["innocense"]="innocence",
    ["introducion"]="introduction",
    ["knwo"]="know",["kown"]="know",["knw"]="know",
    ["lenght"]="length",["lengthh"]="length",["lenghth"]="length",
    ["littel"]="little",["littlee"]="little",
    ["livly"]="lively",["livelyy"]="lively",
    ["manouver"]="manoeuvre",["manovre"]="manoeuvre",["manoevre"]="manoeuvre",
    ["manoevour"]="manoeuvre",
    ["marraige"]="marriage",["marraigee"]="marriage",
    ["medeval"]="medieval",["medival"]="medieval",["medievall"]="medieval",
    ["miniture"]="miniature",["minituree"]="miniature",
    ["momment"]="moment",
    ["naturaly"]="naturally",
    ["neigbourhood"]="neighbourhood",
    ["ocassionally"]="occasionally",
    ["officail"]="official",
    ["ommision"]="omission",["ommission"]="omission",
    ["oppertunities"]="opportunities",
    ["paralell"]="parallel",["parralel"]="parallel",["paralel"]="parallel",
    ["parliement"]="parliament",["parlimentt"]="parliament",
    ["particullar"]="particular",
    ["pasportt"]="passport",
    ["peculier"]="peculiar",
    ["personel"]="personnel",
    ["phsyical"]="physical",["phsical"]="physical",
    ["posession"]="possession",
    ["prefered"]="preferred",["preferredd"]="preferred",
    ["preciouus"]="precious",["preciouse"]="precious",
    ["privelegee"]="privilege",
    ["proffesional"]="professional",
    ["propoganda"]="propaganda",
    ["psycology"]="psychology",
    ["publicallyy"]="publicly",["publickly"]="publicly",
    ["questionaire"]="questionnaire",["quesitons"]="questions",
    ["reeliy"]="really",
    ["recomendd"]="recommend",
    ["recieved"]="received",
    ["releventt"]="relevant",
    ["religouss"]="religious",
    ["remmber"]="remember",
    ["repitition"]="repetition",
    ["resistantt"]="resistant",
    ["responsability"]="responsibility",
    ["rythmic"]="rhythmic",
    ["safteey"]="safety",
    ["secretaryy"]="secretary",
    ["seperateley"]="separately",
    ["siezz"]="seize",
    ["similliar"]="similar",
    ["sincerelly"]="sincerely",
    ["societyy"]="society",
    ["succesfull"]="successful",
    ["suprisinglyy"]="surprisingly",
    ["tatoo"]="tattoo",["tatto"]="tattoo",
    ["temperment"]="temperament",
    ["tendancy"]="tendency",
    ["milleniume"]="millennium",
    ["tyrantt"]="tyrant",["tyran"]="tyrant",
    ["unneccessarry"]="unnecessary",
    ["unfortunatlyy"]="unfortunately",
    ["univeristyy"]="university",
    ["vaccuumed"]="vacuumed",
    ["vehiclle"]="vehicle",["vehicule"]="vehicle",
    ["visability"]="visibility",
    ["voilence"]="violence",
    ["womenn"]="women",["womans"]="women",
    ["writtingg"]="writing",
    ["realy"]="really",["reeli"]="really",["reelly"]="really",
    ["acknowledgge"]="acknowledge",
    ["buisy"]="busy",
    ["bakc"]="back",["blanck"]="blank",
    ["berief"]="brief",
    ["augest"]="august",
    ["attentivee"]="attentive",["attractivee"]="attractive",
    ["catagorys"]="categories",
    ["ceratain"]="certain",
    ["choosen"]="chosen",
    ["equiptment"]="equipment",
    ["existancee"]="existence",
    ["extreem"]="extreme",
    ["govermental"]="governmental",
    ["imporant"]="important",
    ["independet"]="independent",
    ["labratoryy"]="laboratory",
    ["lightining"]="lightning",
    ["maintainancee"]="maintenance",
    ["neccessity"]="necessity",
    ["offficial"]="official",
    ["oppertunity"]="opportunity",
    ["persistantt"]="persistent",
    ["publicallyy"]="publicly",
    ["quesiton"]="question",
    ["releventt"]="relevant",
    ["secretaryy"]="secretary",
    ["seperately"]="separately",
    ["suprise"]="surprise",["suprised"]="surprised",
    ["toungee"]="tongue",
    ["truelyy"]="truly",
    ["unneccessary"]="unnecessary",
    ["univeristy"]="university",
    ["vaccuumed"]="vacuumed",
}

local WORD_UPGRADES = {
    ["very big"]={s="enormous"},["very small"]={s="tiny"},
    ["very fast"]={s="rapid"},["very slow"]={s="sluggish"},
    ["very good"]={s="excellent"},["very bad"]={s="terrible"},
    ["very happy"]={s="elated"},["very sad"]={s="devastated"},
    ["very angry"]={s="furious"},["very tired"]={s="exhausted"},
    ["very scared"]={s="terrified"},["very pretty"]={s="gorgeous"},
    ["very smart"]={s="brilliant"},["very cold"]={s="freezing"},
    ["very hot"]={s="scorching"},["very old"]={s="ancient"},
    ["very important"]={s="crucial"},["very loud"]={s="deafening"},
    ["very quiet"]={s="silent"},["really good"]={s="excellent"},
    ["really bad"]={s="terrible"},["really big"]={s="massive"},
    ["a lot of"]={s="numerous"},["lots of"]={s="numerous"},
    ["kind of"]={s="somewhat"},["sort of"]={s="somewhat"},
    ["a bit"]={s="slightly"},["a little bit"]={s="slightly"},
}
local SINGLE_UPGRADES = {
    ["make"]="create",["get"]="obtain",["use"]="utilize",
    ["show"]="demonstrate",["tell"]="inform",["ask"]="inquire",
    ["try"]="attempt",["want"]="desire",["need"]="require",
    ["help"]="assist",["start"]="commence",["end"]="conclude",
    ["stop"]="cease",["think"]="consider",["know"]="understand",
    ["see"]="observe",["look"]="examine",["say"]="state",
    ["talk"]="communicate",["give"]="provide",["take"]="acquire",
    ["put"]="place",["go"]="proceed",["come"]="arrive",
    ["find"]="locate",["keep"]="maintain",["thing"]="element",
    ["stuff"]="material",["things"]="elements",["big"]="significant",
    ["small"]="minor",["good"]="excellent",["bad"]="poor",
    ["nice"]="pleasant",["cool"]="impressive",["awesome"]="remarkable",
    ["hard"]="difficult",["easy"]="simple",["fast"]="rapid",
    ["slow"]="gradual",["old"]="aged",["new"]="recent",
    ["many"]="numerous",["few"]="limited",["ok"]="acceptable",
    ["okay"]="acceptable",["problem"]="issue",["chance"]="opportunity",
    ["done"]="completed",["fix"]="resolve",["check"]="verify",
    ["change"]="modify",["move"]="relocate",["win"]="succeed",
    ["lose"]="fail",["meet"]="encounter",["plan"]="intend",
    ["hope"]="anticipate",["buy"]="purchase",["build"]="construct",
    ["care"]="concern",["pick"]="select",
}

local PATTERN_RULES = {
    {"(%a)%1%1+","%1%1"},{"%.%.%.+","..."},
    {"%!%!+","!"},  {"%?%?+","?"},
    {"stoped","stopped"},{"droped","dropped"},{"skiped","skipped"},
    {"runing","running"},{"siting","sitting"},{"geting","getting"},
    {"recieve","receive"},{"beleive","believe"},{"wierd","weird"},
    {"freind","friend"},{"peice","piece"},{"usefull","useful"},
    {"helpfull","helpful"},{"beautifull","beautiful"},
    {"successfull","successful"},{"carefull","careful"},
    {"gratefull","grateful"},{"mispell","misspell"},
}

local IMPROVE_PHRASES = {
    {"^I think that ","I believe "},{"^I think ","I believe "},
    {"^I feel like ","I believe "},{"^There are ","Numerous "},
    {"^So ",""},{"^Well, ",""},{"^Basically, ",""},
    {"^Honestly, ",""},{"^Actually, ",""},{"^Like, ",""},
    {"in order to ","to "},{"due to the fact that","because"},
    {"in the event that ","if "},{"for the purpose of ","to "},
    {"with regard to ","regarding "},{"a large number of","many"},
    {"make a decision","decide"},{"make an attempt","attempt"},
    {"take into consideration","consider"},{"prior to","before"},
    {"subsequent to","after"},{"in addition,","furthermore,"},
    {"but ","however, "},{"and also","and"},{"each and every","every"},
    {"first and foremost","primarily"},{"last but not least","finally"},
}

-- ============================================================
-- SECTION 3: CORRECTION ENGINE
-- ============================================================
local function trim(s) return (s:match("^%s*(.-)%s*$")) end
local function hasTerminal(s) return s:match("[%.%!%?]%s*$") ~= nil end
local function capFirst(s)
    if not s or #s == 0 then return s end
    return s:sub(1,1):upper()..s:sub(2)
end
local function matchCase(orig, repl)
    if #orig > 1 and orig == orig:upper() then return repl:upper() end
    if orig:sub(1,1) == orig:sub(1,1):upper() then return capFirst(repl) end
    return repl
end

local function applyPatternRules(text)
    for _, r in ipairs(PATTERN_RULES) do
        text = text:gsub(r[1], r[2])
    end
    return text
end

local function applyWordUpgrades(text)
    local sugs = {}
    local low = text:lower()
    for phrase, data in pairs(WORD_UPGRADES) do
        local esc = phrase:gsub("([%(%)%.%%%+%-%*%?%[%^%$])","%%%1")
        if low:find(esc) then
            table.insert(sugs, {original=phrase, suggested=data.s})
        end
    end
    local seen = {}
    text:gsub("%f[%a][%a]+%f[%A]", function(w)
        local lw = w:lower()
        local s  = SINGLE_UPGRADES[lw]
        if s and not seen[lw] then seen[lw]=true
            table.insert(sugs, {original=w, suggested=s})
        end
    end)
    local out = {}
    for i=1, math.min(#sugs,6) do out[i]=sugs[i] end
    return out
end

local function improveOffline(text)
    local t = text
    for _, r in ipairs(IMPROVE_PHRASES) do t = t:gsub(r[1], r[2]) end
    t = trim(t)
    if #t > 0 then t = t:sub(1,1):upper()..t:sub(2) end
    if not hasTerminal(t) then t = t.."." end
    return t
end

local function correctText(input)
    if not input or trim(input)=="" then return input,{},input,{} end
    local text = trim(input:gsub("  +"," "))
    local changes = {}

    if togAC then
        text = text:gsub("%f[%a][%a']+%f[%A]", function(w)
            local lw = w:lower()
            local fix = WORD_FIXES[lw]
            if fix and fix ~= lw then
                local r = matchCase(w,fix)
                if r ~= w then table.insert(changes,{original=w,corrected=r}) end
                return r
            end
            return w
        end)
        local b = text; text = applyPatternRules(text)
        if text ~= b then table.insert(changes,{original="typos",corrected="fixed"}) end
    end

    if togCap then
        text = text:gsub("^i([%s%p])","I%1"):gsub("([%s])i([%s%p])","I%2")
              :gsub("([%s])i$","%1I"):gsub("^i$","I")
              :gsub("^i'","I'"):gsub("([%s])i'","%1I'")
        if #text>0 then text = text:sub(1,1):upper()..text:sub(2) end
        text = text:gsub("([%.%!%?]%s+)(%a)", function(p,l) return p..l:upper() end)
    end

    if togPunct then
        text = text:gsub("([%,%;%:])([%a%d])","%1 %2")
                   :gsub("([%.%!%?])([%a%d])","%1 %2")
                   :gsub("%s+([%,%.%!%?%;%:])","1")
        text = trim(text)
        if #text>0 and not hasTerminal(text) then text = text.."." end
    else
        text = trim(text)
    end

    return text, changes, improveOffline(text), applyWordUpgrades(text)
end

-- ============================================================
-- SECTION 4: CHAT SENDER
-- ============================================================
local function sendToChat(msg)
    if not msg or trim(msg) == "" then return false end

    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return false end

    -- Find Roblox chat TextBox
    local chatBox = nil
    for _, v in ipairs(gui:GetDescendants()) do
        if v:IsA("TextBox") and v.Visible and v ~= inputBox then
            local name = v.Name:lower()
            local ph   = v.PlaceholderText:lower()
            if name == "chatbar" or name == "chatinput" or name == "input"
            or ph:find("chat") or ph:find("say") or ph:find("to chat")
            or ph:find("message") or ph:find("press") or ph:find("type") then
                chatBox = v
                break
            end
        end
    end

    -- Fallback: any visible TextBox that isn't ours
    if not chatBox then
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("TextBox") and v.Visible and v ~= inputBox then
                chatBox = v; break
            end
        end
    end

    if chatBox then
        chatBox:CaptureFocus()
        task.wait(0.05)
        chatBox.Text = msg
        task.wait(0.05)
        -- Try VirtualInputManager first (some executors support this)
        local vim = game:GetService("VirtualInputManager")
        if vim then
            pcall(function()
                vim:SendKeyEvent(true,  Enum.KeyCode.Return, false, game)
                vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end)
        end
        -- Always also call ReleaseFocus as backup
        chatBox:ReleaseFocus(true)
        return true
    end

    -- Last resort: TextChannel SendAsync
    local ok = false
    pcall(function()
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels then
            for _, ch in ipairs(channels:GetChildren()) do
                if ch:IsA("TextChannel") then
                    ch:SendAsync(msg); ok = true; break
                end
            end
        end
    end)
    return ok
end

-- ============================================================
-- SECTION 4B: AI CORRECTION ENGINE  (executor http.request)
-- Uses Groq free API — llama-3.3-70b — called directly from
-- the LocalScript. No server bridge needed with an executor.
-- ============================================================
local GROQ_KEY   = "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"   -- ← 
local GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions"
local GROQ_MODEL = "llama-3.3-70b-versatile"
local togAI      = true   -- controlled by the AI toggle in Settings

-- Four prompt variants: punct on/off × cap on/off
local AI_PROMPTS = {
    -- punct=true, cap=true
    [true] = {
        [true]  = [[You are a real-time chat corrector for a Roblox game.
Return ONLY the corrected message — no explanation, no quotes, no extra text.
RULES:
- Fix every spelling mistake, typo, and grammatical error
- Fix punctuation — add periods, commas, apostrophes where needed
- Always capitalize the start of sentences and the pronoun I
- Preserve the original tone — keep slang and casual language natural
- Remove filler sounds like uh, um, er but keep the speaker's voice
- If already correct, return it unchanged
- Never add words not implied by the original]],
        -- punct=true, cap=false
        [false] = [[You are a real-time chat corrector for a Roblox game.
Return ONLY the corrected message — no explanation, no quotes, no extra text.
RULES:
- Fix every spelling mistake, typo, and grammatical error
- Fix punctuation — add periods, commas, apostrophes where needed
- Do NOT change any capitalization — leave uppercase and lowercase exactly as the user typed
- Preserve the original tone — keep slang and casual language natural
- Remove filler sounds like uh, um, er but keep the speaker's voice
- If already correct, return it unchanged
- Never add words not implied by the original]],
    },
    -- punct=false, cap=true
    [false] = {
        [true]  = [[You are a real-time chat corrector for a Roblox game.
Return ONLY the corrected message — no explanation, no quotes, no extra text.
RULES:
- Fix every spelling mistake, typo, and grammatical error
- Do NOT change or add any punctuation — leave it exactly as the user typed
- Always capitalize the start of sentences and the pronoun I
- Preserve the original tone — keep slang and casual language natural
- Remove filler sounds like uh, um, er but keep the speaker's voice
- If already correct, return it unchanged
- Never add words not implied by the original]],
        -- punct=false, cap=false
        [false] = [[You are a real-time chat corrector for a Roblox game.
Return ONLY the corrected message — no explanation, no quotes, no extra text.
RULES:
- Fix every spelling mistake, typo, and grammatical error only
- Do NOT change or add any punctuation — leave it exactly as the user typed
- Do NOT change any capitalization — leave uppercase and lowercase exactly as the user typed
- Preserve the original tone — keep slang and casual language natural
- Remove filler sounds like uh, um, er but keep the speaker's voice
- If already correct, return it unchanged
- Never add words not implied by the original]],
    },
}

local HttpService = game:GetService("HttpService")

local function aiCorrect(text, onSuccess, onFail)
    -- Executors expose http.request, request, or syn.request
    local httpFunc = (syn and syn.request)
                  or (http and http.request)
                  or (type(request)=="function" and request)
                  or nil
    if not httpFunc then
        onFail("No HTTP function found — make sure your executor supports http.request")
        return
    end
    if GROQ_KEY == "YOUR_API_KEY_HERE" or #GROQ_KEY < 20 then
        onFail("Groq API key not set — paste your key into GROQ_KEY at the top of the script")
        return
    end

    local body = HttpService:JSONEncode({
        model       = GROQ_MODEL,
        messages    = {
            {role="system", content=AI_PROMPTS[togPunct][togCap]},
            {role="user",   content=text},
        },
        max_tokens  = 300,
        temperature = 0.1,
    })

    task.spawn(function()
        local ok, res = pcall(httpFunc, {
            Url     = GROQ_URL,
            Method  = "POST",
            Headers = {
                ["Content-Type"]  = "application/json",
                ["Authorization"] = "Bearer "..GROQ_KEY,
            },
            Body = body,
        })

        if not ok or not res then
            onFail("HTTP request failed: "..tostring(res):sub(1,80))
            return
        end

        local rawBody = (type(res)=="table") and (res.Body or res.body) or tostring(res)
        if not rawBody or #rawBody == 0 then
            onFail("Empty response from Groq")
            return
        end

        local parseOk, data = pcall(function() return HttpService:JSONDecode(rawBody) end)
        if not parseOk or type(data) ~= "table" then
            onFail("Failed to parse JSON response")
            return
        end

        if data.error then
            onFail("Groq error: "..(data.error.message or "unknown"))
            return
        end

        local choice = data.choices and data.choices[1]
        local content = choice and choice.message and choice.message.content
        if not content then
            onFail("No content in Groq response")
            return
        end

        -- Strip accidental surrounding quotes / whitespace
        content = content:match('^["\']?(.-)["\'%s]*$') or content
        content = content:match("^%s*(.-)%s*$") or content
        onSuccess(content)
    end)
end

-- ============================================================
-- SECTION 5: COLOURS
-- ============================================================
-- Roblox chat exact colours
local C_TAB_BG   = Color3.fromRGB(30,  30,  30)   -- tab bar background
local C_CHAT_BG  = Color3.fromRGB(25,  34,  44)   -- chat area (semi-transparent)
local C_INPUT_BG = Color3.fromRGB(36,  36,  36)   -- input bar
local C_BORDER   = Color3.fromRGB(55,  55,  55)
local C_TEXT     = Color3.fromRGB(230, 230, 230)
local C_DIM      = Color3.fromRGB(160, 160, 160)
local C_WHITE    = Color3.fromRGB(255, 255, 255)
-- Content colours
local C_GREEN    = Color3.fromRGB(80,  215, 120)
local C_BLUE     = Color3.fromRGB(100, 170, 255)
local C_PURPLE   = Color3.fromRGB(190, 125, 255)
local C_YELLOW   = Color3.fromRGB(255, 210, 60)
local C_TAG_BG   = Color3.fromRGB(65,  42,  0)
local C_TAG_TXT  = Color3.fromRGB(255, 190, 50)
local C_OK       = Color3.fromRGB(46,  210, 110)
local C_BUSY     = Color3.fromRGB(255, 195, 45)
local C_ERR      = Color3.fromRGB(255, 75,  75)
-- Button colours
local C_SEND     = Color3.fromRGB(0,   145, 90)
local C_COPY     = Color3.fromRGB(50,  110, 210)
local C_PASTE    = Color3.fromRGB(120, 70,  200)
local C_CLEAR    = Color3.fromRGB(180, 50,  50)
local C_USE      = Color3.fromRGB(70,  45,  140)
local C_TOG_ON   = Color3.fromRGB(0,   162, 255)
local C_TOG_OFF  = Color3.fromRGB(55,  55,  55)
local C_KNOB     = Color3.fromRGB(230, 230, 230)
local C_SUGGEST  = Color3.fromRGB(36,  24,  50)
local C_PREV_BG  = Color3.fromRGB(20,  35,  20)
local C_IMP_BG   = Color3.fromRGB(18,  25,  42)

-- ============================================================
-- SECTION 6: UI  — Roblox Chat Window Layout
--
--  ┌─────────────────────────────────────┐  ← panel
--  │  • Correct  │  Settings         [✕] │  ← tabBar  (42px)
--  ├─────────────────────────────────────┤
--  │                                     │
--  │         chat / content area         │  ← chatArea (fills middle)
--  │                                     │
--  ├─────────────────────────────────────┤
--  │  Copy  Paste  Clear  UseImprv   [▶] │  ← inputBar (44px)
--  └─────────────────────────────────────┘
-- ============================================================
local existingGui = PlayerGui:FindFirstChild("KojiUI")
if existingGui then existingGui:Destroy() end

local PANEL_W = 360
local PANEL_H = 420
local TAB_H   = 36
local INP_H   = 38

local sg = Instance.new("ScreenGui")
sg.Name="KojiUI"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.DisplayOrder=99; sg.Parent=PlayerGui

-- Shadow
local shadow = Instance.new("Frame")
shadow.Name="Shadow"
shadow.Size=UDim2.new(0,PANEL_W+10,0,PANEL_H+10)
shadow.Position=UDim2.new(0,15,1,-PANEL_H-15)
shadow.BackgroundColor3=Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency=0.6
shadow.BorderSizePixel=0; shadow.ZIndex=1; shadow.Parent=sg
Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,10)

-- Main panel
local panel = Instance.new("Frame")
panel.Name="KojiPanel"
panel.Size=UDim2.new(0,PANEL_W,0,PANEL_H)
panel.Position=UDim2.new(0,20,1,-PANEL_H-20)
panel.BackgroundColor3=C_TAB_BG
panel.BorderSizePixel=0; panel.ClipsDescendants=true
panel.ZIndex=2; panel.Parent=sg
do
    Instance.new("UICorner",panel).CornerRadius=UDim.new(0,8)
    local s=Instance.new("UIStroke",panel)
    s.Color=C_BORDER; s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
end

-- ── TAB BAR ─────────────────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Name="TabBar"
tabBar.Size=UDim2.new(1,0,0,TAB_H)
tabBar.Position=UDim2.new(0,0,0,0)
tabBar.BackgroundColor3=C_TAB_BG
tabBar.BorderSizePixel=0; tabBar.ZIndex=3; tabBar.Parent=panel

-- Bottom divider line under tab bar
local tabDiv = Instance.new("Frame",tabBar)
tabDiv.Size=UDim2.new(1,0,0,1)
tabDiv.Position=UDim2.new(0,0,1,-1)
tabDiv.BackgroundColor3=C_BORDER; tabDiv.BorderSizePixel=0; tabDiv.ZIndex=4

-- Active white dot (left of active tab label)
local activeDot = Instance.new("Frame",tabBar)
activeDot.Size=UDim2.new(0,8,0,8)
activeDot.Position=UDim2.new(0,10,0.5,-4)
activeDot.BackgroundColor3=C_WHITE; activeDot.BorderSizePixel=0; activeDot.ZIndex=5
Instance.new("UICorner",activeDot).CornerRadius=UDim.new(1,0)

-- Status dot (far right, flashes on correction activity)
local statusDot = Instance.new("Frame",tabBar)
statusDot.Size=UDim2.new(0,8,0,8)
statusDot.Position=UDim2.new(1,-22,0.5,-4)
statusDot.BackgroundColor3=C_OK; statusDot.BorderSizePixel=0; statusDot.ZIndex=5
Instance.new("UICorner",statusDot).CornerRadius=UDim.new(1,0)

-- Close button
local closeBtn = Instance.new("TextButton",tabBar)
closeBtn.Size=UDim2.new(0,22,0,22)
closeBtn.Position=UDim2.new(1,-10,0.5,-11)
closeBtn.AnchorPoint=Vector2.new(1,0.5)
closeBtn.BackgroundColor3=Color3.fromRGB(180,50,50)
closeBtn.BorderSizePixel=0; closeBtn.Text="✕"
closeBtn.TextColor3=C_WHITE; closeBtn.Font=Enum.Font.GothamBold
closeBtn.TextSize=11; closeBtn.ZIndex=6
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,5)
closeBtn.Activated:Connect(function() sg:Destroy() end)

-- Tab buttons — each takes half the bar (minus the dot space and close btn)
local TAB_AREA_X = 24   -- start x (after the dot)
local TAB_AREA_W = PANEL_W - 24 - 36  -- minus dot area and close btn
local TAB_W = math.floor(TAB_AREA_W / 2)

local function makeTabBtn(label, xOff)
    local btn = Instance.new("TextButton",tabBar)
    btn.Size=UDim2.new(0,TAB_W,1,0)
    btn.Position=UDim2.new(0,TAB_AREA_X+xOff,0,0)
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0
    btn.Text=label; btn.TextColor3=C_DIM
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=14; btn.ZIndex=4
    -- underline indicator
    local ul = Instance.new("Frame",btn)
    ul.Size=UDim2.new(0.6,0,0,2)
    ul.Position=UDim2.new(0.2,0,1,-2)
    ul.BackgroundColor3=C_WHITE; ul.BorderSizePixel=0; ul.ZIndex=5; ul.Visible=false
    return btn, ul
end

-- Vertical separator between tabs
local sep = Instance.new("Frame",tabBar)
sep.Size=UDim2.new(0,1,0,TAB_H-14)
sep.Position=UDim2.new(0,TAB_AREA_X+TAB_W,0,7)
sep.BackgroundColor3=C_BORDER; sep.BorderSizePixel=0; sep.ZIndex=4

local tabCorrect,  ulCorrect  = makeTabBtn("Correct",  0)
local tabSettings, ulSettings = makeTabBtn("Settings", TAB_W+1)

-- ── CHAT AREA (fills between tab bar and input bar) ──────────
local chatArea = Instance.new("Frame",panel)
chatArea.Name="ChatArea"
chatArea.Size=UDim2.new(1,0,0,PANEL_H-TAB_H-INP_H)
chatArea.Position=UDim2.new(0,0,0,TAB_H)
chatArea.BackgroundColor3=C_CHAT_BG
chatArea.BackgroundTransparency=0.15
chatArea.BorderSizePixel=0; chatArea.ClipsDescendants=true; chatArea.ZIndex=2

-- ── INPUT BAR (pinned to bottom of panel) ────────────────────
local inputBar = Instance.new("Frame",panel)
inputBar.Name="InputBar"
inputBar.Size=UDim2.new(1,0,0,INP_H)
inputBar.Position=UDim2.new(0,0,1,-INP_H)
inputBar.BackgroundColor3=C_INPUT_BG
inputBar.BorderSizePixel=0; inputBar.ZIndex=3
do
    Instance.new("UICorner",inputBar).CornerRadius=UDim.new(0,8)
    local s=Instance.new("UIStroke",inputBar)
    s.Color=C_BORDER; s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    local tl=Instance.new("Frame",inputBar)
    tl.Size=UDim2.new(1,0,0,1); tl.Position=UDim2.new(0,0,0,0)
    tl.BackgroundColor3=C_BORDER; tl.BorderSizePixel=0; tl.ZIndex=4
end

-- Input bar buttons
local IB_PAD=5; local IB_H=INP_H-IB_PAD*2; local IB_W=62
local function makeIBBtn(lbl,col,xOff)
    local b=Instance.new("TextButton",inputBar)
    b.Size=UDim2.new(0,IB_W,0,IB_H)
    b.Position=UDim2.new(0,IB_PAD+xOff,0,IB_PAD)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=lbl; b.TextColor3=C_WHITE
    b.Font=Enum.Font.GothamSemibold; b.TextSize=11; b.ZIndex=4
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local bc=col
    b.MouseEnter:Connect(function()
        b.BackgroundColor3=Color3.new(math.min(1,bc.R+0.12),math.min(1,bc.G+0.12),math.min(1,bc.B+0.12))
    end)
    b.MouseLeave:Connect(function() b.BackgroundColor3=bc end)
    return b
end

local btnCopy  = makeIBBtn("⧉ Copy",  C_COPY,  0)
local btnPaste = makeIBBtn("⏎ Paste", C_PASTE, IB_W+IB_PAD)
local btnClear = makeIBBtn("✕ Clear", C_CLEAR, (IB_W+IB_PAD)*2)

-- Use Improved button (right side, before send)
local UI_W=106
local btnUseImp=Instance.new("TextButton",inputBar)
btnUseImp.Size=UDim2.new(0,UI_W,0,IB_H)
btnUseImp.Position=UDim2.new(1,-(UI_W+IB_PAD+38+IB_PAD),0,IB_PAD)
btnUseImp.BackgroundColor3=C_USE; btnUseImp.BorderSizePixel=0
btnUseImp.Text="✦ Use Improved"; btnUseImp.TextColor3=C_WHITE
btnUseImp.Font=Enum.Font.GothamSemibold; btnUseImp.TextSize=11; btnUseImp.ZIndex=4
Instance.new("UICorner",btnUseImp).CornerRadius=UDim.new(0,6)
local uc=C_USE
btnUseImp.MouseEnter:Connect(function()
    btnUseImp.BackgroundColor3=Color3.new(math.min(1,uc.R+0.12),math.min(1,uc.G+0.12),math.min(1,uc.B+0.12))
end)
btnUseImp.MouseLeave:Connect(function() btnUseImp.BackgroundColor3=uc end)

-- Send arrow (far right)
local btnSend=Instance.new("TextButton",inputBar)
btnSend.Size=UDim2.new(0,38,0,IB_H)
btnSend.Position=UDim2.new(1,-(38+IB_PAD),0,IB_PAD)
btnSend.BackgroundColor3=C_SEND; btnSend.BorderSizePixel=0
btnSend.Text="▶"; btnSend.TextColor3=C_WHITE
btnSend.Font=Enum.Font.GothamBold; btnSend.TextSize=16; btnSend.ZIndex=4
Instance.new("UICorner",btnSend).CornerRadius=UDim.new(0,6)

-- ── RESIZE HANDLE ────────────────────────────────────────────
local resizeBtn=Instance.new("TextButton",panel)
resizeBtn.Size=UDim2.new(0,24,0,24)
-- Sits just above the input bar on the right side, not overlapping any buttons
resizeBtn.Position=UDim2.new(1,-28,1,-(INP_H+28))
resizeBtn.BackgroundColor3=Color3.fromRGB(60,60,70)
resizeBtn.BackgroundTransparency=0; resizeBtn.BorderSizePixel=0
resizeBtn.Text="⇲"; resizeBtn.TextColor3=Color3.fromRGB(180,180,190)
resizeBtn.Font=Enum.Font.GothamBold; resizeBtn.TextSize=13; resizeBtn.ZIndex=20
Instance.new("UICorner",resizeBtn).CornerRadius=UDim.new(0,5)

-- Invisible drag strip across the full top of the panel (sits above tab buttons)
-- No dragHandle needed — drag from the panel's tabBar background directly
-- Tab buttons have their own Activated so they won't interfere

-- ============================================================
-- SECTION 6B: PAGE CONTENTS
-- Helper to make a label inside a page
-- ============================================================
local function lbl(parent,text,y,col)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,-20,0,15); l.Position=UDim2.new(0,10,0,y)
    l.BackgroundTransparency=1; l.Text=text
    l.TextColor3=col or C_DIM; l.Font=Enum.Font.GothamSemibold
    l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end
local function box(parent,col,y,h,border)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,-20,0,h); f.Position=UDim2.new(0,10,0,y)
    f.BackgroundColor3=col; f.BorderSizePixel=0; f.ClipsDescendants=true
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)
    if border then
        local s=Instance.new("UIStroke",f)
        s.Color=border; s.Thickness=1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    end
    return f
end
local function innerText(parent,col)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,-16,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text=""
    l.TextColor3=col; l.Font=Enum.Font.Gotham; l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Top
    l.TextWrapped=true
    Instance.new("UIPadding",l).PaddingTop=UDim.new(0,6)
    return l
end

-- ── PAGE: CORRECT ─────────────────────────────────────────────
local pageCorrect=Instance.new("Frame",chatArea)
pageCorrect.Size=UDim2.new(1,0,1,0); pageCorrect.Position=UDim2.new(0,0,0,0)
pageCorrect.BackgroundTransparency=1; pageCorrect.BorderSizePixel=0
pageCorrect.ClipsDescendants=true

-- Input textbox
lbl(pageCorrect,"✎  YOUR MESSAGE",8)
local inputBox=Instance.new("TextBox",pageCorrect)
inputBox.Size=UDim2.new(1,-20,0,62); inputBox.Position=UDim2.new(0,10,0,25)
inputBox.BackgroundColor3=Color3.fromRGB(40,40,40); inputBox.BorderSizePixel=0
inputBox.Text=""; inputBox.PlaceholderText="Type your message here..."
inputBox.PlaceholderColor3=C_DIM; inputBox.TextColor3=C_TEXT
inputBox.Font=Enum.Font.Gotham; inputBox.TextSize=13
inputBox.TextXAlignment=Enum.TextXAlignment.Left
inputBox.TextYAlignment=Enum.TextYAlignment.Top
inputBox.MultiLine=true; inputBox.ClearTextOnFocus=false; inputBox.TextWrapped=true
do
    Instance.new("UICorner",inputBox).CornerRadius=UDim.new(0,7)
    local p=Instance.new("UIPadding",inputBox)
    p.PaddingLeft=UDim.new(0,9); p.PaddingTop=UDim.new(0,7); p.PaddingRight=UDim.new(0,9)
    local s=Instance.new("UIStroke",inputBox)
    s.Color=C_BORDER; s.Thickness=1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
end

-- Corrected preview
lbl(pageCorrect,"✓  CORRECTED",95)
local prevFrame=box(pageCorrect,C_PREV_BG,112,44,Color3.fromRGB(30,80,40))
local prevText=innerText(prevFrame,C_GREEN)

-- Improved preview
lbl(pageCorrect,"✦  IMPROVED",164)
local impFrame=box(pageCorrect,C_IMP_BG,181,44,Color3.fromRGB(30,50,110))
local impText=innerText(impFrame,C_BLUE)

-- Corrections made
lbl(pageCorrect,"⚡  CORRECTIONS MADE",233)
local chgScroll=Instance.new("ScrollingFrame",pageCorrect)
chgScroll.Size=UDim2.new(1,-20,0,35); chgScroll.Position=UDim2.new(0,10,0,250)
chgScroll.BackgroundColor3=Color3.fromRGB(40,40,40); chgScroll.BorderSizePixel=0
chgScroll.ScrollBarThickness=3; chgScroll.ScrollBarImageColor3=C_BLUE
chgScroll.CanvasSize=UDim2.new(0,0,0,0); chgScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
chgScroll.ClipsDescendants=true
Instance.new("UICorner",chgScroll).CornerRadius=UDim.new(0,6)
do
    local layout=Instance.new("UIListLayout",chgScroll)
    layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,4)
    local p=Instance.new("UIPadding",chgScroll)
    p.PaddingLeft=UDim.new(0,6); p.PaddingTop=UDim.new(0,5)
end
local noChgLbl=Instance.new("TextLabel",chgScroll)
noChgLbl.Name="NoChg"; noChgLbl.Size=UDim2.new(1,0,1,0)
noChgLbl.BackgroundTransparency=1; noChgLbl.Text="No corrections yet — type above."
noChgLbl.TextColor3=C_DIM; noChgLbl.Font=Enum.Font.Gotham
noChgLbl.TextSize=11; noChgLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Word upgrades
lbl(pageCorrect,"💡  WORD UPGRADES",293)
local upgScroll=Instance.new("ScrollingFrame",pageCorrect)
upgScroll.Size=UDim2.new(1,-20,0,62); upgScroll.Position=UDim2.new(0,10,0,310)
upgScroll.BackgroundColor3=C_SUGGEST; upgScroll.BorderSizePixel=0
upgScroll.ScrollBarThickness=3; upgScroll.ScrollBarImageColor3=C_PURPLE
upgScroll.CanvasSize=UDim2.new(0,0,0,0); upgScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
upgScroll.ClipsDescendants=true
do
    Instance.new("UICorner",upgScroll).CornerRadius=UDim.new(0,6)
    local s=Instance.new("UIStroke",upgScroll)
    s.Color=Color3.fromRGB(70,30,110); s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    local layout=Instance.new("UIListLayout",upgScroll)
    layout.FillDirection=Enum.FillDirection.Vertical; layout.Padding=UDim.new(0,2)
    local p=Instance.new("UIPadding",upgScroll)
    p.PaddingLeft=UDim.new(0,8); p.PaddingTop=UDim.new(0,5)
    p.PaddingBottom=UDim.new(0,4); p.PaddingRight=UDim.new(0,8)
end
local noUpgLbl=Instance.new("TextLabel",upgScroll)
noUpgLbl.Name="NoUpg"; noUpgLbl.Size=UDim2.new(1,0,0,20)
noUpgLbl.BackgroundTransparency=1; noUpgLbl.Text="No upgrade suggestions yet."
noUpgLbl.TextColor3=C_DIM; noUpgLbl.Font=Enum.Font.Gotham
noUpgLbl.TextSize=11; noUpgLbl.TextXAlignment=Enum.TextXAlignment.Left

-- AI status bar (shows while Groq is working)
local aiStatusBar=Instance.new("Frame",pageCorrect)
aiStatusBar.Size=UDim2.new(1,-20,0,26); aiStatusBar.Position=UDim2.new(0,10,0,380)
aiStatusBar.BackgroundColor3=Color3.fromRGB(20,20,30); aiStatusBar.BorderSizePixel=0
aiStatusBar.Visible=false
Instance.new("UICorner",aiStatusBar).CornerRadius=UDim.new(0,6)
local aiStatusTxt=Instance.new("TextLabel",aiStatusBar)
aiStatusTxt.Size=UDim2.new(1,-10,1,0); aiStatusTxt.Position=UDim2.new(0,8,0,0)
aiStatusTxt.BackgroundTransparency=1; aiStatusTxt.Text="⏳  Sending to AI..."
aiStatusTxt.TextColor3=C_BUSY; aiStatusTxt.Font=Enum.Font.GothamSemibold
aiStatusTxt.TextSize=11; aiStatusTxt.TextXAlignment=Enum.TextXAlignment.Left

-- ── PAGE: SETTINGS ────────────────────────────────────────────
local pageSettings=Instance.new("Frame",chatArea)
pageSettings.Size=UDim2.new(1,0,1,0); pageSettings.Position=UDim2.new(0,0,0,0)
pageSettings.BackgroundTransparency=1; pageSettings.BorderSizePixel=0
pageSettings.ClipsDescendants=true; pageSettings.Visible=false

lbl(pageSettings,"CORRECTION TOGGLES",12,C_DIM)

local function makeToggle(parent,title,desc,yPos,getF,setF)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,-20,0,50); row.Position=UDim2.new(0,10,0,yPos)
    row.BackgroundColor3=Color3.fromRGB(38,38,38); row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    do
        local s=Instance.new("UIStroke",row)
        s.Color=C_BORDER; s.Thickness=1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    end
    local tl=Instance.new("TextLabel",row)
    tl.Size=UDim2.new(1,-75,0,22); tl.Position=UDim2.new(0,12,0,6)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=C_TEXT
    tl.Font=Enum.Font.GothamSemibold; tl.TextSize=13
    tl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",row)
    dl.Size=UDim2.new(1,-75,0,16); dl.Position=UDim2.new(0,12,0,30)
    dl.BackgroundTransparency=1; dl.Text=desc; dl.TextColor3=C_DIM
    dl.Font=Enum.Font.Gotham; dl.TextSize=11
    dl.TextXAlignment=Enum.TextXAlignment.Left
    local track=Instance.new("TextButton",row)
    track.Size=UDim2.new(0,46,0,25); track.Position=UDim2.new(1,-58,0.5,-12)
    track.BackgroundColor3=getF() and C_TOG_ON or C_TOG_OFF
    track.BorderSizePixel=0; track.Text=""
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,19,0,19)
    knob.Position=getF() and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3=C_KNOB; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    track.Activated:Connect(function()
        local v=not getF(); setF(v)
        track.BackgroundColor3=v and C_TOG_ON or C_TOG_OFF
        knob.Position=v and UDim2.new(1,-22,0.5,-9) or UDim2.new(0,3,0.5,-9)
    end)
end

makeToggle(pageSettings,"Punctuation Correction",
    "Adds/fixes end punctuation and spacing.",34,
    function() return togPunct end, function(v) togPunct=v end)
makeToggle(pageSettings,"Auto-Correct",
    "Fixes typos, contractions, and misspellings.",92,
    function() return togAC end, function(v) togAC=v end)
makeToggle(pageSettings,"Capitalization",
    "Corrects sentence starts and the pronoun \"I\".",150,
    function() return togCap end, function(v) togCap=v end)
makeToggle(pageSettings,"AI Correction (Groq)",
    "Sends message to AI before sending — catches everything.",208,
    function() return togAI end, function(v) togAI=v end)

local note=Instance.new("TextLabel",pageSettings)
note.Size=UDim2.new(1,-20,0,44); note.Position=UDim2.new(0,10,0,270)
note.BackgroundTransparency=1
note.Text="ℹ  AI mode requires your Groq key set in GROQ_KEY at the top of the script. Offline corrections run instantly as you type regardless."
note.TextColor3=C_DIM; note.Font=Enum.Font.Gotham; note.TextSize=11
note.TextXAlignment=Enum.TextXAlignment.Left; note.TextWrapped=true

-- ============================================================
-- SECTION 7: REAL-TIME PREVIEW
-- ============================================================
local isUpdating=false; local debounce=0; local DEBOUNCE=0.3
local currentImproved=""

local function setStatus(col)
    statusDot.BackgroundColor3=col
    task.delay(1.2,function() statusDot.BackgroundColor3=C_OK end)
end

local function updateChangeTags(changes)
    for _,ch in ipairs(chgScroll:GetChildren()) do
        if ch:IsA("TextButton") or (ch:IsA("TextLabel") and ch.Name~="NoChg") then
            ch:Destroy()
        end
    end
    noChgLbl.Visible=#changes==0
    for _,c in ipairs(changes) do
        local tag=Instance.new("TextButton",chgScroll)
        tag.AutomaticSize=Enum.AutomaticSize.X
        tag.Size=UDim2.new(0,0,0,24); tag.BackgroundColor3=C_TAG_BG
        tag.BorderSizePixel=0; tag.TextColor3=C_TAG_TXT
        tag.Text=("  %s → %s  "):format(c.original,c.corrected)
        tag.Font=Enum.Font.Gotham; tag.TextSize=11
        Instance.new("UICorner",tag).CornerRadius=UDim.new(0,5)
    end
end

local function updateUpgradeTags(sugs)
    for _,ch in ipairs(upgScroll:GetChildren()) do
        if ch:IsA("Frame") or (ch:IsA("TextLabel") and ch.Name~="NoUpg") then
            ch:Destroy()
        end
    end
    noUpgLbl.Visible=#sugs==0
    for _,s in ipairs(sugs) do
        local row=Instance.new("Frame",upgScroll)
        row.Size=UDim2.new(1,0,0,18); row.BackgroundTransparency=1
        row.BorderSizePixel=0
        local layout=Instance.new("UIListLayout",row)
        layout.FillDirection=Enum.FillDirection.Horizontal
        layout.VerticalAlignment=Enum.VerticalAlignment.Center
        layout.Padding=UDim.new(0,4)
        local function addW(txt,col,bold)
            local l=Instance.new("TextLabel",row)
            l.AutomaticSize=Enum.AutomaticSize.X; l.Size=UDim2.new(0,0,1,0)
            l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=col
            l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
            l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
        end
        addW(s.original,C_DIM,false)
        addW("→",Color3.fromRGB(150,90,210),false)
        addW(s.suggested,C_PURPLE,true)
    end
end

local function runPreview()
    isUpdating=true
    local raw=inputBox.Text
    if trim(raw)==""  then
        prevText.Text=""; impText.Text=""; currentImproved=""
        updateChangeTags({}); updateUpgradeTags({})
        isUpdating=false; return
    end
    local corrected,changes,improved,upgrades=correctText(raw)
    prevText.Text=corrected; impText.Text=improved; currentImproved=improved
    if corrected~=raw then
        statusDot.BackgroundColor3=C_BUSY
        task.delay(0.6,function() statusDot.BackgroundColor3=C_OK end)
    end
    updateChangeTags(changes); updateUpgradeTags(upgrades)
    isUpdating=false
end

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
    if isUpdating then return end; debounce=tick()
end)
RunService.Heartbeat:Connect(function()
    if debounce>0 and (tick()-debounce)>=DEBOUNCE then debounce=0; runPreview() end
end)

-- ============================================================
-- SECTION 8: BUTTON ACTIONS
-- ============================================================
local function clearAll()
    inputBox.Text=""; prevText.Text=""; impText.Text=""
    currentImproved=""; updateChangeTags({}); updateUpgradeTags({})
    aiStatusBar.Visible=false
end

-- Send: if AI is on → call Groq → send result; fallback to offline on failure
btnSend.Activated:Connect(function()
    local raw=inputBox.Text; if trim(raw)==""  then return end

    if togAI then
        -- Lock the button while waiting
        btnSend.Text="⏳"; btnSend.Active=false
        aiStatusBar.Visible=true
        aiStatusTxt.Text="⏳  AI is correcting your message..."
        aiStatusTxt.TextColor3=C_BUSY
        statusDot.BackgroundColor3=C_BUSY

        aiCorrect(raw, function(aiResult)
            -- Success — send the AI-corrected message
            aiStatusTxt.Text="✓  AI corrected — sending..."
            aiStatusTxt.TextColor3=C_OK
            task.wait(0.3)
            if sendToChat(aiResult) then
                setStatus(C_OK); clearAll()
            else
                setStatus(C_ERR)
                aiStatusTxt.Text="✕  Chat send failed."
                aiStatusTxt.TextColor3=C_ERR
            end
            btnSend.Text="▶"; btnSend.Active=true
            task.delay(1.5,function() aiStatusBar.Visible=false end)
        end, function(errMsg)
            -- AI failed — fall back to offline correction silently
            aiStatusTxt.Text="⚠  AI failed — using offline correction."
            aiStatusTxt.TextColor3=C_ERR
            warn("[Koji AI] "..tostring(errMsg))
            local corrected=correctText(raw)
            task.wait(0.5)
            if sendToChat(corrected) then
                setStatus(C_OK); clearAll()
            else setStatus(C_ERR) end
            btnSend.Text="▶"; btnSend.Active=true
            task.delay(2,function() aiStatusBar.Visible=false end)
        end)
    else
        -- AI off — pure offline correction
        local corrected=correctText(raw)
        if sendToChat(corrected) then
            setStatus(C_OK); clearAll()
        else setStatus(C_ERR) end
    end
end)

btnCopy.Activated:Connect(function()
    local raw=inputBox.Text; if trim(raw)==""  then return end
    local corrected=correctText(raw)
    pcall(function() setclipboard(corrected) end)
    btnCopy.BackgroundColor3=C_OK
    task.delay(0.5,function() btnCopy.BackgroundColor3=C_COPY end)
    setStatus(C_OK)
end)

btnPaste.Activated:Connect(function()
    local ok,pasted=pcall(function() return getclipboard() end)
    if ok and type(pasted)=="string" and #pasted>0 then
        inputBox.Text=pasted; runPreview(); setStatus(C_OK)
    else setStatus(C_ERR) end
end)

btnClear.Activated:Connect(function() clearAll() end)

btnUseImp.Activated:Connect(function()
    if trim(currentImproved)==""  then return end
    inputBox.Text=currentImproved; runPreview(); setStatus(C_OK)
end)

-- Enter key: send while input focused
inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then btnSend:Activate() end
end)

-- ============================================================
-- SECTION 9: TAB SWITCHING
-- ============================================================
local function setTab(tab)
    local onCorrect=(tab=="correct")
    pageCorrect.Visible=onCorrect; pageSettings.Visible=not onCorrect
    tabCorrect.TextColor3=onCorrect and C_WHITE or C_DIM
    tabSettings.TextColor3=onCorrect and C_DIM or C_WHITE
    ulCorrect.Visible=onCorrect; ulSettings.Visible=not onCorrect
    -- Slide the active dot under the correct tab label
    if onCorrect then
        activeDot.Position=UDim2.new(0,10,0.5,-4)
    else
        activeDot.Position=UDim2.new(0,TAB_AREA_X+TAB_W+10,0.5,-4)
    end
end

tabCorrect.Activated:Connect(function()  setTab("correct")  end)
tabSettings.Activated:Connect(function() setTab("settings") end)
setTab("correct")

-- ============================================================
-- SECTION 10: DRAG  (tabBar background — avoid tab button areas)
-- ============================================================
local dragging=false; local dragStart=Vector2.new(); local panelStart=Vector2.new()

tabBar.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1
    and inp.UserInputType~=Enum.UserInputType.Touch then return end
    -- Only start drag if click is NOT inside a tab button
    local clickX = inp.Position.X - tabBar.AbsolutePosition.X
    local tabCorrectRight = tabCorrect.AbsolutePosition.X + tabCorrect.AbsoluteSize.X - tabBar.AbsolutePosition.X
    local tabSettingsLeft = tabSettings.AbsolutePosition.X - tabBar.AbsolutePosition.X
    local tabSettingsRight = tabSettings.AbsolutePosition.X + tabSettings.AbsoluteSize.X - tabBar.AbsolutePosition.X
    local onTab = (clickX >= 0 and clickX <= tabCorrectRight)
               or (clickX >= tabSettingsLeft and clickX <= tabSettingsRight)
    if onTab then return end
    dragging=true; dragStart=inp.Position
    panelStart=Vector2.new(panel.AbsolutePosition.X,panel.AbsolutePosition.Y)
end)
tabBar.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType~=Enum.UserInputType.MouseMovement
    and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local d=Vector2.new(inp.Position.X-dragStart.X,inp.Position.Y-dragStart.Y)
    local vp=workspace.CurrentCamera.ViewportSize
    local nx=math.clamp(panelStart.X+d.X, 0, vp.X-panel.AbsoluteSize.X)
    local ny=math.clamp(panelStart.Y+d.Y, 0, vp.Y-panel.AbsoluteSize.Y)
    panel.Position=UDim2.new(0,nx,0,ny)
    shadow.Position=UDim2.new(0,nx-5,0,ny-5)
end)

-- ============================================================
-- SECTION 11: RESIZE  (drag ⇲ corner handle)
-- ============================================================
local MIN_W=160; local MIN_H=180; local MAX_W=900; local MAX_H=960
local resizing=false; local rsStart=Vector2.new()
local rsPanelW=PANEL_W; local rsPanelH=PANEL_H

resizeBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        resizing=true; rsStart=Vector2.new(inp.Position.X,inp.Position.Y)
        rsPanelW=panel.AbsoluteSize.X; rsPanelH=panel.AbsoluteSize.Y
    end
end)
resizeBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then resizing=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not resizing then return end
    if inp.UserInputType~=Enum.UserInputType.MouseMovement
    and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local nw=math.clamp(rsPanelW+(inp.Position.X-rsStart.X),MIN_W,MAX_W)
    local nh=math.clamp(rsPanelH+(inp.Position.Y-rsStart.Y),MIN_H,MAX_H)
    local px=panel.AbsolutePosition.X; local py=panel.AbsolutePosition.Y
    panel.Size=UDim2.new(0,nw,0,nh)
    panel.Position=UDim2.new(0,px,0,py)
    -- Recalculate chat area height
    chatArea.Size=UDim2.new(1,0,0,nh-TAB_H-INP_H)
    shadow.Size=UDim2.new(0,nw+10,0,nh+10)
    shadow.Position=UDim2.new(0,px-5,0,py-5)
end)

-- ============================================================
-- SECTION 12: BACKGROUND CHAT PATCH
-- ============================================================
local function patchChannel(ch)
    if ch:GetAttribute("KojiPatched") then return end
    ch:SetAttribute("KojiPatched",true)
    local orig=ch.SendAsync; local guard=false
    ch.SendAsync=function(self,msg,...)
        if guard then return orig(self,msg,...) end
        guard=true; local fixed=correctText(msg)
        local r=orig(self,fixed,...); guard=false; return r
    end
end
local function initPatch()
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
task.spawn(initPatch)

print("[Koji v4.1] ✓ Loaded. 600+ word fixes, AI correction, Roblox Chat UI — paste your key into GROQ_KEY.")

end, function(e)
    warn("[Koji] Fatal: "..tostring(e))
    warn(debug.traceback())
end)
