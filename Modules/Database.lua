local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local DB = GT:NewModule('Database')
GT.DB = DB

function DB:OnEnable(force)
	if force == nil then
		force = false
	end
	-- GT.Log:Info('DB_OnEnable', force)

	DB.db = LibStub('AceDB-3.0'):New('GTDB')

	if DB.db.char == nil or force then
		DB.db.char = {}
	end

	if DB.db.global == nil or force then
		DB.db.global = {}
	end

	if DB.db.char.characters == nil or force then
		DB.db.char.characters = {}
	end

	if DB.db.char.search == nil then
		DB.db.char.search = {}
	end

	if DB.db.global.professions == nil or force then
		DB.db.global.professions = {}
	end

	DB.valid = DB:Validate()
end

function DB:Reset(force)
	GT.Log:Info('DB_Reset', force)
	DB.db.char.characters = {}
	DB.db.global.professions = {}
	DB.valid = true
end

function DB:GetSearch(searchField)
	if DB.db.char.search[searchField] == nil then
		return nil
	end
	return DB.db.char.search[searchField]
end

function DB:SetSearch(searchField, searchTerm)
	DB.db.char.search[searchField] = searchTerm
end

function DB:GetCharacters()
	-- GT.Log:Info('DB_GetCharacters')
	return DB.db.char.characters
end

function DB:ResetCharacter(characterName)
	for tempCharacterName, _ in pairs(DB.db.char.characters) do
		if string.lower(tempCharacterName) == string.lower(characterName) then
			DB.db.char.characters[characterName] = {}
			return true
		end
	end
	return false
end

function DB:GetProfessions()
	-- GT.Log:Info('DB_GetProfessions')
	return DB.db.global.professions
end

function DB:GetCharacter(characterName)
	-- GT.Log:Info('DB_GetCharacter', characterName)
	if DB.db.char.characters[characterName] == nil then
		return DB:AddCharacter(characterName)
	end
	return DB.db.char.characters[characterName]
end

function DB:AddCharacter(characterName)
	-- GT.Log:Info('DB_AddCharacter', characterName)
	if DB.db.char.characters[characterName] == nil then
		DB.db.char.characters[characterName] = {}
	end

	local character = DB.db.char.characters[characterName]
	character.characterName = characterName
	if character.professions == nil then
		character.professions = {}
	end

	if character.deletedProfessions == nil then
		character.deletedProfessions = {}
	end
	return character
end

function DB:GetProfession(characterName, professionName)
	-- GT.Log:Info('DB_GetProfession', characterName, professionName)

	DB:_GetProfession(professionName)

	if characterName == nil then
		return DB:_GetProfession(professionName)
	else
		local professions = DB:GetCharacter(characterName).professions
		if professions[professionName] == nil then
			-- GT.Log:Info('DB_GetProfession_Nil', characterName, professionName)
			return nil
		end
		return professions[professionName]
	end
end

function DB:GetProfessions()
	return DB.db.global.professions
end

function DB:_GetProfession(professionName)
	-- GT.Log:Info('DB__GetProfession', professionName)
	if DB.db.global.professions[professionName] == nil then
		-- GT.Log:Info('DB__GetProfession_NilProfession', professionName)
		DB.db.global.professions[professionName] = {}
	end
	local profession = DB.db.global.professions[professionName]
	if profession.skills == nil then
		profession.skills = {}
	end
	return profession
end

function DB:AddProfession(characterName, professionName)
	-- GT.Log:Info('DB_AddProfession', characterName, professionName)

	DB:_GetProfession(professionName)

	if characterName ~= nil then
		local character = DB:GetCharacter(characterName)
		character.deletedProfessions = GT.Table:RemoveByValue(character.deletedProfessions, professionName)
		local professions = character.professions
		if professions[professionName] == nil then
			professions[professionName] = {}
			professions[professionName].professionName = professionName
			professions[professionName].lastUpdate = time()
		end
		local profession = professions[professionName]
		if profession.skills == nil then
			profession.skills = {}
		end
		return profession
	end
	return DB:_GetProfession(professionName)
end

function DB:DeleteProfession(characterName, professionName)
	-- GT.Log:Info('DB_DeleteProfession', characterName, professionName)
	local character = DB:GetCharacter(characterName)
	for dbProfessionName, _ in pairs(character.professions) do
		if dbProfessionName == professionName then
			table.insert(character.deletedProfessions, professionName)
			character.professions[professionName] = nil
			return true
		end
	end
	return false
end

function DB:ResetProfession(professionName)
	for tempProfessionName, _ in pairs(DB.db.global.professions) do
		if string.lower(tempProfessionName) == string.lower(professionName) then
			DB.db.global.professions[tempProfessionName] = {}
			return true
		end
	end
	return false
end

function DB:GetSkill(characterName, professionName, skillName)
	-- GT.Log:Info('DB_GetSkill', characterName, professionName, skillName)

	DB:_GetSkill(professionName, skillName)

	profession = DB:GetProfession(characterName, professionName)
	if profession == nil then
		-- GT.Log:Info('DB_GetSkill_ProfessionNil', characterName, professionName, skillName)
		return nil
	end
	if not GT.Table:Contains(profession.skills, skillName) then
		-- GT.Log:Info('DB_GetSkill_SkillNil', characterName, professionName, skillName)
		return nil
	end
	return DB:_GetSkill(professionName, skillName)
end

function DB:_GetSkill(professionName, skillName, skillLink)
	-- GT.Log:Info('DB__GetSkill', professionName, skillName, skillLink)
	local profession = DB:_GetProfession(professionName)
	if profession.skills[skillName] == nil then
		profession.skills[skillName] = {}
	end
	local skill = profession.skills[skillName]
	skill.skillName = skillName
	if skillLink then
		skill.skillLink = skillLink
	end
	if skill.reagents == nil then
		skill.reagents = {}
	end
	return skill
end

function DB:AddSkill(characterName, professionName, skillName, skillLink)
	-- GT.Log:Info('DB_AddSkill', characterName, professionName, skillName, skillLink)

	profession = DB:GetProfession(characterName, professionName)
	if profession == nil then
		GT.Log:Error('DB_AddSkill_ProfessionNil', characterName, professionName, skillName, skillLink)
		return nil
	end
	local skills = profession.skills
	if characterName ~= nil then
		if not GT.Table:Contains(skills, skillName) then
			table.insert(skills, skillName)
			profession.lastUpdate = time()
		end
	end
	return DB:_GetSkill(professionName, skillName, skillLink)
end

function DB:GetReagent(professionName, skillName, reagentName)
	-- GT.Log:Info('DB_GetReagent', professionName, skillName, reagentName)
	
	return DB:_GetReagent(professionName, skillName, reagentName)
end

function DB:_GetReagent(professionName, skillName, reagentName, reagentCount)
	-- GT.Log:Info('DB__GetReagent', professionName, skillName, reagentName, reagentCount)
	local skill = DB:_GetSkill(professionName, skillName)
	if skill.reagents == nil then
		skill.reagents = {}
	end
	local reagents = skill.reagents
	if reagents[reagentName] == nil then
		reagents[reagentName] = {}
	end
	local reagent = reagents[reagentName]
	reagent.reagentName = reagentName
	if reagentCount then
		reagent.reagentCount = reagentCount
	end
	return reagent
end

function DB:AddReagent(professionName, skillName, reagentName, reagentCount)
	-- GT.Log:Info('DB_AddReagent', professionName, skillName, reagentName, reagentCount)

	return DB:_GetReagent(professionName, skillName, reagentName, reagentCount)
end

function DB:Validate()
	local structureValid = DB:_ValidateStructure()
	local dataValid = DB:_ValidateData()
	return structureValid and dataValid
end

function DB:_ValidateStructure()
	local valid = true
	for characterName, _ in pairs(DB.db.char.characters) do
		local character = DB.db.char.characters[characterName]
		if character.professions == nil then
			character.professions = {}
			valid = false
		end
		if character.deletedProfessions == nil then
			character.deletedProfessions = {}
			valid = false
		end
		local professions = character.professions
		for professionName, _ in pairs(professions) do
			local profession = professions[professionName]
			if profession.skills == nil then
				profession.skills = {}
				valid = false
			end
		end
	end

	for professionName, _ in pairs(DB.db.global.professions) do
		local profession = DB.db.global.professions[professionName]
		if profession.skills == nil then
			profession.skills = {}
			valid = false
		end
		local skills = profession.skills
		for skillName, _ in pairs(skills) do
			local skill = skills[skillName]
			if skill.reagents == nil then
				skill.reagents = {}
				valid = false
			end
		end
	end
	return valid
end

function DB:_ValidateData()
	local valid = true
	for characterName, _ in pairs(DB.db.char.characters) do
		if tonumber(characterName) ~= nil then
			GT.Log:Error('Invalid character name', characterName)
			valid = false
		end
		local professions = DB.db.char.characters[characterName].professions
		for professionName, _ in pairs(professions) do
			if tonumber(professionName) ~= nil then
				GT.Log:Error('Invalid character profession name', characterName, professionName)
				valid = false
			end
			local profession = professions[professionName]
			if profession.lastUpdate ==  nil
				or tonumber(profession.lastUpdate) == nil then
				profession.lastUpdate = 0
			end

			if profession.professionName == nil
				or tonumber(profession.professionName)
				or string.find(profession.professionName, ']')
			then
				profession.professionName = professionName
			end

			local skills = profession.skills
			for _, skillName in pairs(skills) do
				if string.find(skillName, ']')
					or tonumber(skillName) ~= nil
				then
					GT.Log:Error('Invalid character profession skill name', characterName, professionName, skillName)
					valid = false
				end
			end
		end
	end

	for professionName, _ in pairs(DB.db.global.professions) do
		if tonumber(professionName) ~= nil
			or string.find(professionName, ']') then
			GT.Log:Error('Invalid profession name', professionName)
			valid = false
		end
		local profession = DB.db.global.professions[professionName]

		if profession.professionName == nil
			or tonumber(profession.professionName) ~= nil
			or string.find(profession.professionName, ']')
		then
			profession.professionName = professionName
		end

		local skills = profession.skills
		for skillName, _ in pairs(skills) do
			if string.find(skillName, ']')
				or tonumber(skillName) ~= nil
			then
				GT.Log:Error('Invalid profession skill name', professionName, skillName)
				valid = false
			end

			local skill = skills[skillName]
			if skill.skillName == nil
				or string.find(skill.skillName, ']')
				or tonumber(skill.skillName) ~= nil
			then
				skill.skillName = skillName
			end

			if skill.skillLink == nil 
				or tonumber(skill.skillLink) ~= nil 
				or not string.find(skill.skillLink, ']')
			then
				GT.Log:Error('Invalid profession skill skillLink', professionName, skillName, skill.skillLink)
				valid = false
			end

			local reagents = skill.reagents
			for reagentName in pairs(reagents) do
				if string.find(reagentName, ']')
					or tonumber(reagentName) ~= nil
				then
					GT.Log:Error('Invalid profession skill reagentName', professionName, skillName, reagentName)
				end

				local reagent = reagents[reagentName]

				if reagent.reagentName == nil
					or tonumber(reagent.reagentName) ~= nil
					or string.find(reagent.reagentName, ']')
				then
					reagent.reagentName = reagentName
				end

				if reagent.reagentCount == nil
					or tonumber(reagent.reagentCount) == nil
				then
					GT.Log:Error('Invalid profession skill reagentCount', professionName, skillName, reagent.reagentCount)
					valid = false
				end
			end
		end
	end
	return valid
end

function DB:GetChatFrameNumber()
	if DB.db == nil then return 1 end
	if DB.db.global == nil then return 1 end
	if DB.db.global.chatFrameNumber == nil then return 1 end
	return DB.db.global.chatFrameNumber
end

function DB:SetChatFrameNumber(frameNumber)
	-- GT.Log:Info('DB_SetChatFrame', frameNumber)
	DB.db.global.chatFrameNumber = frameNumber
end

function DB:InitVersion(version)
	GT.Log:Info('DB_InitVersion', version)
	if DB.db.global.versionNotification == nil then
		DB.db.global.versionNotification = version
	end
end

function DB:ShouldNotifyUpdate(version)
	--@debug@
	if true then
		return false
	end
	--@end-debug@
	local vNotification = DB.db.global.versionNotification
	GT.Log:Info('DB_ShouldNotifyUpdate', vNotification, version)
	if vNotification < version then
		return true
	end
	return false
end

function DB:UpdateNotified(version)
	DB.db.global.versionNotification = version
end