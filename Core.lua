local AddOnName, GT = ...

GT = LibStub('AceAddon-3.0'):NewAddon(AddOnName, 'AceComm-3.0', 'AceConsole-3.0', 'AceEvent-3.0')

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

---------- START LOAD LIBRARIES ----------

GT.Text = LibStub:GetLibrary('GTText')
GT.Table = LibStub:GetLibrary('GTTable')

---------- END LOAD LIBRARIES ----------

GT.resetWarned = false
GT.version = '@project-version@'

local INITIAL_DELAY = 15

function GT:OnInitialize()
	GT.Log:Enable()

	GT.Log:Info('GT_OnInitialize')

	GT.Command:Enable()
	GT.Event:Enable()

	GT:Wait(INITIAL_DELAY, GT['InitMessages'], 'Hello')
end

local waitTable = {};
local waitFrame = nil;

function GT:InitMessages()
	GT.Comm:SendTimestamps()
	GT.Comm:SendVersion()
end

function GT:OnDisable()
	GT.Log:Info('GT_OnDisable')
end

function GT:InitReset(tokens)
	local token = GT.Table:RemoveToken(tokens)
	--@debug@
	if string.lower(token) == L['FORCE'] then
		GT:Reset(true)
		return
	end
	--@end-debug@
	if not GT.resetWarned then
		GT.Log:PlayerWarn(L['RESET_WARN'])
		GT.resetWarned = true
		return
	end
	GT.resetWarned = false

	if token == nil then
		GT.Log:PlayerWarn(L['RESET_NO_TOKEN'])
		return
	end
	if string.lower(token) == string.lower(L['RESET_EXPECT_CANCEL']) then
		GT.Log:PlayerInfo(L['RESET_CANCEL'])
		return
	end
	if string.lower(token) == string.lower(L['RESET_EXPECT_COMFIRM']) then
		GT:Reset()
		return
	end

	local message = string.gsub(L['RESET_UNKNOWN'], '%{{token}}', token)
	GT.Log:PlayerWarn(message)
end

function GT:Reset(force)
	GT.Log:PlayerWarn(L['RESET_FINAL'], force)

	GT.Log:Reset(force)
	GT.DB:Reset(force)
end

function GT:ConvertVersion(releaseVersion, betaVersion, alphaVersion)
	local rVersion = tonumber(releaseVersion) * 10000
	local bVersion = tonumber(betaVersion) * 100
	local aVersion = tonumber(alphaVersion)

	return rVersion + bVersion + aVersion
end

function GT:DeconvertVersion(version)
	GT.Log:Info('v', version)
	local rVersion = math.floor(version / 10000)
	GT.Log:Info('rVersion', rVersion)
	version = version - (rVersion * 10000)
	GT.Log:Info('v', version)
	local bVersion = math.floor(version / 100)
	GT.Log:Info('bVersion', bVersion)
	local aVersion = version - (bVersion * 100)
	GT.Log:Info('aVersion', aVersion)
	return rVersion, bVersion, aVersion
end

function GT:GetCurrentVersion()
	local version = GT:ConvertVersion(98, 99, 99)
	--@debug@
	if true then
		GT.DB:InitVersion(version)
		GT.Log:Info('GT_GetCurrentVersion', version)
		return version
	end
	--@end-debug@
	local tokens = GT.Text:Tokenize(GT.version, '_')
	local version = tokens[2]
	tokens = GT.Text:Tokenize(version, '.')
	rVersion, tokens = GT.Table:RemoveToken(tokens)
	bVersion, tokens = GT.Table:RemoveToken(tokens)
	aVersion, tokens = GT.Table:RemoveToken(tokens)

	version = GT:ConvertVersion(rVersion, bVersion, aVersion)
	GT.Log:Info('GT_GetCurrentVersion', version)

	GT.DB:InitVersion(version)

	return version
end

function GT:Wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end