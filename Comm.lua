local GT_Name, GT = ...

GT.comm = {}
GT.comm.state = {}
GT.comm.state.initialized = false

GT.comm.aceComm = LibStub("AceAddon-3.0"):NewAddon("TSWL", "AceComm-3.0")

GT.comm.PREFIX = 'GT'
GT.comm.DELIMITER = '?'
GT.comm.REAGENT_COUNT = 'REAGENT_COUNT'

GT.comm.COMMAND_TIMESTAMP = 'TIMESTAMP'
GT.comm.COMMAND_GET = 'GET'
GT.comm.COMMAND_POST = 'POST'

GT.comm.COMMAND_MAP = {}

function GT.comm.init()
	if GT.comm.state.initialized then
		return
	end
	GT.logging.info('GT_Comm_Init')

	GT.comm.COMMAND_MAP = {
		TIMESTAMP = GT.comm.onTimestampsReceived,
		GET = GT.comm.onGetReceived,
		POST = GT.comm.onPostReceived,
	}

	GT.comm.aceComm:RegisterComm(GT.comm.PREFIX, GT.comm.aceComm:OnCommReceived())

	GT.comm.state.initialized = true
end

function GT.comm.aceComm:OnCommReceived(prefix, message, distribution, sender)
	if prefix == nil or message == nil or distribution == nil or sender == nil then
		return
	end
	GT.logging.info('GT_Comm_OnCommReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender)

	local tokens = GT.textUtils.tokenize(message, GT.comm.DELIMITER)
	local command = tokens[1]
	local tokens = GT.tableUtils.removeToken(tokens)
	local commandFound = false
	for mapCommand, fn in pairs(GT.comm.COMMAND_MAP) do
		if command == mapCommand then
			fn(prefix, tokens, distribution, sender)
			commandFound = true
		end
	end
	if not commandFound then
		GT.logging.warn('GT_Comm_OnCommReceived: Unknown command: ' .. command)
	end
end

function GT.comm.sendTimestamps()
	GT.logging.info('GT_Comm_SendTimestamps')
	local characters = GT.database.getGuild(GT_Character.realmName, GT_Character.factionName, GT_Character.guildName)
	if characters == nil then
		GT.logging.error('No characters found.')
		return
	end
	characters = characters.characters
	local msg = GT.comm.COMMAND_TIMESTAMP
	for characterName, _ in pairs(characters) do
		local professions = characters[characterName].professions
		for professionName, _ in pairs(professions) do
			msg = msg .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName .. GT.comm.DELIMITER .. professions[professionName].lastUpdate
		end
	end

	local totalGuildMembers = GetNumGuildMembers()
	for i = 1, totalGuildMembers do
		local characterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		local tempCharacterName = GT.textUtils.convertCharacterName(characterName)
		if online and tempCharacterName ~= GT_Character.characterName then
			-- GT.logging.info('GT_Comm_AceComm_SendCommMessage ' .. characterName .. ': ' .. msg)
			GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', characterName, 'NORMAL')
		end
	end
end

function GT.comm.onTimestampsReceived(prefix, tokens, distribution, sender)
	GT.logging.info('GT_Comm_OnTimestampsReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender)
	local charactersToPost = {}
	local charactersToGet = {}
	local charactersReceived = {}
	while #tokens > 0 do
		local characterName = tokens[1]
		tokens = GT.tableUtils.removeToken(tokens)
		local professionName = tokens[1]
		tokens = GT.tableUtils.removeToken(tokens)
		local lastUpdate = tonumber(tokens[1])
		tokens = GT.tableUtils.removeToken(tokens)

		charactersReceived[characterName] = {}
		table.insert(charactersReceived[characterName], professionName)

		local profession = GT.database.getProfession(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName,
			professionName
		)
		if profession == nil then
			charactersToGet[characterName] = {}
			table.insert(charactersToGet[characterName], professionName)
		else
			-- if lastUpdate < profession.lastUpdate then
			if lastUpdate < time() then
				charactersToPost[characterName] = {}
				table.insert(charactersToPost[characterName], professionName)
			elseif lastUpdate > profession.lastUpdate then
				charactersToGet[characterName] = {}
				table.insert(charactersToGet[characterName], professionName)
			else
				GT.logging.info('No update: ' .. characterName, ', ' .. professionName)
			end
		end
	end

	local guildCharacters = GT.database.getGuild(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName
	).characters
	for characterName, _ in pairs(guildCharacters) do
		local professions = guildCharacters[characterName].professions
		local characterReceived = GT.tableUtils.tableContains(charactersReceived, characterName)
		if not characterReceived then
			charactersToPost[characterName] = {}
		end
		for professionName, _ in pairs(professions) do
			local professionReceived = GT.tableUtils.tableContains(charactersReceived[characterName], professionName)
			if not professionReceived then
				table.insert(charactersToPost[characterName], professionName)
			end
		end
	end

	local msg = GT.comm.COMMAND_GET
	for characterName, _ in pairs(charactersToGet) do
		local professions = charactersToGet[characterName]
		for _, professionName in pairs(professions) do
			msg = msg .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName
		end
	end
	if msg ~= GT.comm.COMMAND_GET then
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', sender, 'NORMAL')
	end

	local msg = GT.comm.COMMAND_POST
	for characterName, _ in pairs(charactersToPost) do
		local professions = charactersToPost[characterName]
		for _, professionName in pairs(professions) do
			GT.comm.sendPost(characterName, professionName, sender)
		end
	end
end

function GT.comm.sendGet(characterName, professionName)
	GT.logging.info('GT_Comm_SendGet: ' .. characterName .. ', ' .. professionName)
end

function GT.comm.onGetReceived(prefix, tokens, distribution, sender)
	GT.logging.info('GT_Comm_OnGetReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender)
	while #tokens > 0 do
		local characterName = tokens[1]
		tokens = GT.tableUtils.removeToken(tokens)
		local professionName = tokens[1]
		tokens = GT.tableUtils.removeToken(tokens)

		GT.comm.sendPost(characterName, professionName, sender)
	end
end

function GT.comm.sendPost(characterName, professionName, recipient)
	GT.logging.info('GT_Comm_SendPost: ' .. characterName .. ', ' .. professionName .. ', ' .. recipient)

	local profession = GT.database.getProfession(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName,
		professionName
	)
	if profession ~= nil then
		msg = GT.comm.COMMAND_POST .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName .. GT.comm.DELIMITER .. profession.lastUpdate
		local skills = profession.skills
		for skillName, _ in pairs(skills) do
			local skill = skills[skillName]
			msg = msg .. GT.comm.DELIMITER .. skill.skillName .. GT.comm.DELIMITER .. skill.skillLink
			local reagents = skill.reagents
			local sendingReagents = {}
			local sendingReagentCount = 0
			for reagentName, _ in pairs(reagents) do
				local reagent = reagents[reagentName]
				if not reagent.isHidden then
					sendingReagents[reagentName] = reagent.reagentCount
					sendingReagentCount = sendingReagentCount + 1
				end
			end
			msg = msg .. GT.comm.DELIMITER .. sendingReagentCount
			for reagentName, reagentCount in pairs(sendingReagents) do
				msg = msg .. GT.comm.DELIMITER .. reagentName .. GT.comm.DELIMITER .. reagentCount
			end
		end
		if msg ~= GT.comm.COMMAND_POST .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName .. GT.comm.DELIMITER .. profession.lastUpdate then
			GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', recipient, 'ALERT')
		end
	end
end

function GT.comm.onPostReceived(prefix, tokens, distribution, sender)
	GT.logging.info('GT_Comm_OnPostReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender)
	local characterName = tokens[1]
	tokens = GT.tableUtils.removeToken(tokens)
	local professionName = tokens[1]
	tokens = GT.tableUtils.removeToken(tokens)
	local lastUpdate = tonumber(tokens[1])
	tokens = GT.tableUtils.removeToken(tokens)

	local character = GT.database.getCharacter(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName
	)

	if character == nil then
		character = GT.database.addCharacter(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName
		)
	end

	local professions = character.professions

	local profession = GT.database.getProfession(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName,
		professionName
	)
	if profession == nil then
		profession = GT.database.addProfession(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName,
			professionName
		)
	end

	local skills = profession.skills

	while #tokens > 0 do
		local skillName = tokens[1]
		tokens = GT.tableUtils.removeToken(tokens)
		local skillLink = tokens[1]
		tokens = GT.tableUtils.removeToken(tokens)
		local uniqueReagentCount = tonumber(tokens[1])
		tokens = GT.tableUtils.removeToken(tokens)

		local skill = GT.database.getSkill(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName,
			professionName,
			skillName
		)
		if skill == nil then
			skill = GT.database.addSkill(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName,
				professionName,
				skillName,
				skillLink
			)
		end

		local i = 0
		while i < uniqueReagentCount do
			local reagentName = tokens[1]
			tokens = GT.tableUtils.removeToken(tokens)
			local reagentCount = tokens[1]
			tokens = GT.tableUtils.removeToken(tokens)

			local reagent = GT.database.getReagent(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName,
				professionName,
				skillName,
				reagentName
			)

			if reagent == nil then
				GT.database.addReagent(
					GT_Character.realmName,
					GT_Character.factionName,
					GT_Character.guildName,
					characterName,
					professionName,
					skillName,
					reagentName,
					reagentCount
				)
			end

			i = i + 1
		end
	end
end