
--good players(guildies/friends), maybe(for processing)
local good, maybe, filterTable = {}, {}, {}
local login = nil
local whisp = "BadBoy_Levels: You need to be level %d to whisper me."
local err = "You have reached the maximum amount of friends, remove 2 for this addon to function properly!"

--- these variables for debug, should be removed future
badboy_good = good
badboy_filter = filterTable
badboy_last_wisper = ""

do
	local L = GetLocale()
	if L == "esES" or L == "esMX" then
		whisp = "BadBoy_Levels: Necesitas ser nivel %d para susurrarme."
		err = "Has llegado a la cantidad máxima de amigos, quita 2 amigos para que este addon funcione propiamente."
	elseif L == "ptBR" then
		whisp = "BadBoy_Levels: Você precisa ter nível %d para me sussurrar."
		err = "Você atingiu o numero máximo de amigos, remova 2 para este addon funcionar corretamente!"
	elseif L == "deDE" then
		whisp = "BadBoy_Levels: Du musst Level %d sein, um mir etwas flüstern zu können."
		err = "Du hast die maximale Anzahl an Freunden erreicht, bitte entferne 2, damit dieses Addon richtig funktioniert!"
	elseif L == "frFR" then
		whisp = "BadBoy_Levels: Vous devez être au moins de niveau %d pour me chuchoter."
		err = "Vous avez atteint la limite de contenu de votre liste d'amis. Enlevez-en 2 pour que cet addon fonctionne correctement !"
	elseif L == "ruRU" then
		whisp = "BadBoy_Levels: Вы должны быть уровнем не ниже %d, что бы шептать мне."
		err = "Вы достигли максимального количества друзей, удалите двоих для нормальной работы аддона!"
	elseif L == "koKR" then
		whisp = "BadBoy_Levels: 저에게 귓속말을 보내기 위해서는 레벨 %d이 필요합니다."
		err = "친구 목록이 최대한도에 도달했습니다. 제대로 애드온이 작업을 하기 위해서는 2명을 제거해야 합니다!"
	elseif L == "zhTW" then
		whisp = "BadBoy_Levels: 你起碼要達到 %d 級才能密我。"
		err = "你的好友列表滿了，此插件需要你騰出2個好友空位!"
	elseif L == "zhCN" then
		whisp = "BadBoy_Levels: 你起码要达到 %d 级才能和我讲话。"
		err = "你的好友列表满了，此插件模块需要你腾出2个好友空位！"
	elseif L == "itIT" then
		whisp = "BadBoy_Levels: E' necessario che tu sia di livello %d per sussurrarmi."
		err = "Hai raggiunto il limite massimo di amici, rimuovine 2 per permettere a questo addon di funzionare correttamente!"
	end
end

local wipeAndLog =
   function(player)
      local debug = ""
      for _, v in pairs(maybe[player]) do
         for _, p in pairs(v) do
            local _,_,msg = unpack(p)
            debug = msg
            wipe(p) --remove player data table
         end
         wipe(v) --remove player data table
      end
      if BadBoyLog and not myDebug then
         BadBoyLog("BadBoy", "CHAT_MSG_WHISPER", player, debug)
      end
   end

local sendReservedMsg =
   function(player)
      --get all the frames, incase whispers are being recieved in more that one chat frame
      for _, v in pairs(maybe[player]) do
         --get all the chat lines (queued if multiple) for restoration back to the chat frame
         for _, p in pairs(v) do
            --this player is good, we must restore the whisper(s) back to chat
            if IsAddOnLoaded("WIM") then --WIM compat
               WIM.modules.WhisperEngine:CHAT_MSG_WHISPER(select(3, unpack(p)))
            elseif IsAddOnLoaded("Cellular") then --Cellular compat
               local _,_,a1,a2,_,_,_,a6,_,_,_,_,a11,a12 = unpack(p)
               Cellular:IncomingMessage(a2, a1, a6, nil, a11, a12)
            else
               ChatFrame_MessageEventHandler(unpack(p))
            end
            wipe(p) --remove player data table
         end
         wipe(v) --remove player data table
      end
   end

local checkLevel =
   function(level)
      if type(level) ~= "number" then
         print("|cFF33FF99BadBoy_Levels|r: Level wasn't a number, tell BadBoy author! It was:", level)
         error("|cFF33FF99BadBoy_Levels|r: Level wasn't a number, tell BadBoy author! It was: ".. tostring(level))
      end
   end

-- rewrite logic of add friend
-- chat_msg_system filter will act both on badboy add friend and user add friend
-- so we should check if maybe msg is pending
-- should be local, global for debug
pendingRequests = 0
local badboyAddFriend, hookBadboyAddFriend
do
   hookBadboyAddFriend = function(...)
      if(pendingRequests <= 0) then
         pendingRequests = 1
      else
         pendingRequests = pendingRequests + 1
      end
      return badboyAddFriend(...)
   end
end

if not badboyAddFriend then
   badboyAddFriend = AddFriend
   AddFriend = hookBadboyAddFriend
end

ChatFrame_AddMessageEventFilter(
   "CHAT_MSG_SYSTEM",
   function(frame, event, msg, ...)
      local prePendingRequests = pendingRequests

      -- friend is full
      if (msg == ERR_FRIEND_LIST_FULL) then
         pendingRequests = pendingRequests - 1
         --print a warning if we see a friends full message
         print("|cFF33FF99BadBoy_Levels|r: ", err)
         return
      end

      -- friend not found
      if(msg == ERR_FRIEND_NOT_FOUND) then
         pendingRequests = pendingRequests - 1
      end

      -- friend already exists
      if(msg:match(ERR_FRIEND_ALREADY_S:format("(.*)"))) then
         pendingRequests = pendingRequests - 1
      end

      local pattern = ERR_FRIEND_ADDED_S:format("(.*)")
      local added = msg:match(pattern)
      if(added) then
         pendingRequests = pendingRequests - 1
         local trimmedAdded = Ambiguate(added, "none")
         if(maybe[trimmedAdded]) then
            local num = GetNumFriends() --get total friends
            local findAdded = false
            for i = 1, num do
               local player, level = GetFriendInfo(i)
               if(trimmedAdded == player) then
                  findAdded = true
                  RemoveFriend(player, true) --Remove player from friends list, the 2nd arg "true" is a fake arg added by request of tekkub, author of FriendsWithBenefits
                  checkLevel(level)
                  if level < filterTable[player] then
                     --lower than level 2, or a level defined by the user = bad,
                     --or lower than 58 and class is a Death Knight,
                     --so whisper the bad player what level they must be to whisper us
                     badboy_last_wisper = player
                     SendChatMessage(whisp:format(filterTable[player]), "WHISPER", nil, player)
                     wipeAndLog(player)
                  else
                     good[player] = true --higher = good
                     sendReservedMsg(player)
                  end
                  wipe(maybe[player]) --remove player data table
                  maybe[player] = nil --remove remaining empty table
                  return true
               end
            end
            if(not findAdded) then
               print("not matched in player " .. trimmedAdded)
               wipeAndLog(player)
               wipe(maybe[player])
               maybe[player] = nil
               return true
            end
         end
      end

      if((prePendingRequests > 0) and (pendingRequests == 0)) then
         local flushes = 0
         for player,_ in pairs(maybe) do
            flushes = flushes + 1
            wipeAndLog(player)
            wipe(maybe[player])
            maybe[player] = nil
         end
         if(flushes > 0) then
            return true
         end
      end
      return
end)

--incoming whisper filtering function
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(...)
	local f, _, _, player, _, _, _, flag, _, _, _, _, id, guid = ...
	local trimmedPlayer = Ambiguate(player, "none")
	--don't filter if good, GM, guild member, or x-server
	if good[trimmedPlayer] or UnitIsInMyGuild(trimmedPlayer) then return end
	if flag == "GM" or flag == "DEV" then return end
	--RealID support, don't scan people that whisper us via their character instead of RealID
	--that aren't on our friends list, but are on our RealID list.
	local _, num = BNGetNumFriends()
	for i=1, num do
     local toon = BNGetNumFriendToons(i)
     for j=1, toon do
        local _, rName, rGame, rServer = BNGetFriendToonInfo(i, j)
        if rName == trimmedPlayer and rGame == "WoW" and rServer == GetRealmName() then
           good[trimmedPlayer] = true
           return
        end
     end
  end

  local num = GetNumFriends() --get total friends
  for i = 1, num do
     local player2 = GetFriendInfo(i)
     local trimmedPlayer2 = Ambiguate(player2, "none")
     if(trimmedPlayer2 == trimmedPlayer) then
        good[trimmedPlayer] = true
        return
     end
  end

	f = f:GetName()
	if not f then f = "?" end
	if f == "WIM3_HistoryChatFrame" then return end -- Ignore WIM history frame
	if not f:find("^ChatFrame%d+$") and f ~= "WIM_workerFrame" and f ~= "Cellular" then
		print("|cFF33FF99BadBoy_Levels|r: ERROR, tell BadBoy author, new frame found:", f)
		error("|cFF33FF99BadBoy_Levels|r: Tell BadBoy author, new frame found: ".. f)
		return
	end
	if IsAddOnLoaded("WIM") and f ~= "WIM_workerFrame" then return true end --WIM compat
	if IsAddOnLoaded("Cellular") and f ~= "Cellular" then return true end --Cellular compat
	if not maybe[trimmedPlayer] then maybe[trimmedPlayer] = {} end --added to maybe
	--one table per chatframe, incase we got whispers on 2+ chatframes
	if not maybe[trimmedPlayer][f] then maybe[trimmedPlayer][f] = {} end
	--one table per id, incase we got more than one whisper from a player whilst still processing
	maybe[trimmedPlayer][f][id] = {}
	for i = 1, select("#", ...) do
		--store all the chat arguments incase we need to add it back (if it's a new good guy)
		maybe[trimmedPlayer][f][id][i] = select(i, ...)
	end
	--Decide the level to be filtered
	local _, englishClass = GetPlayerInfoByGUID(guid)
	local level = BADBOY_LEVEL_ADVANCED and tonumber(BADBOY_LEVEL_ADVANCED)+1 or 2
	if englishClass == "DEATHKNIGHT" and level < 58 then level = 58 end
	--Don't try to add a player to friends several times for 1 whisper (registered to more than 1 chat frame)

	if not filterTable[trimmedPlayer] or filterTable[trimmedPlayer] ~= level then
     filterTable[trimmedPlayer] = level
     AddFriend(trimmedPlayer, true) --add player to friends, the 2nd arg "true" is a fake arg added by request of tekkub, author of FriendsWithBenefits
	end
	return true --filter everything not good (maybe) and not GM
end)

ChatFrame_AddMessageEventFilter(
   "CHAT_MSG_AFK",
   function(_, _, msg, player)
      if good[player] then return end
      if filterTable[player] then return true end
end)

ChatFrame_AddMessageEventFilter(
   "CHAT_MSG_DND",
   function(_, _, msg, player)
      print("dnd " .. msg)
      if good[player] then return end
      if filterTable[player] then return true end
end)

--outgoing whisper filtering function
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(_,_,msg,player)
	local trimmedPlayer = Ambiguate(player, "none")
	if good[trimmedPlayer] then return end --Do nothing if on safe list
	if filterTable[trimmedPlayer] and msg:find("^BadBoy.*"..filterTable[trimmedPlayer]) then return true end --Filter auto-response
	good[trimmedPlayer] = true --If we want to whisper someone, they're good
end)
