MMMacro = LibStub("AceAddon-3.0"):NewAddon("MMMacro", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MMMacro", true)

local options = {
    name = "MuchMoreMacro",
    handler = MMMacro,
    type = 'group',
    args = {
        general = {
            name = L['General'],
            type = 'group',
            args = {
                newMacro = {
                    name = L['New Macro'],
                    type = 'input',
                    desc = L['Create a new empty macro'],
                    set = 'SetNewMacro',
                    get = 'GetNewMacro',
                    order = 10,
                },
                macroSelectBox = {
                    name = L['Existing Macros'],
                    type = 'select',
                    desc = L['Select a macro to edit'],
                    set = 'SetSelectMacro',
                    get = 'GetSelectMacro',
                    style = 'dropdown',
                    values = {},
                    order = 20,
                },
                macroName = {
                    name = L['Macro Name'],
                    type = 'input',
                    desc = L['Macro being edited'],
                    set = 'SetMacroName',
                    get = 'GetMacroName',
                    order = 30,
                },

                macroBinding = {
                    name = L['Macro Binding'],
                    type = 'input',
                    desc = L['Bind the macro to key combination'],
                    set = 'SetMacroBinding',
                    get = 'GetMacroBinding',
                    order = 31,
                },

                macroEditBox = {
                    name = L['Macro Text'],
                    type = 'input',
                    desc = "",
                    set = 'SetMacroBody',
                    get = 'GetMacroBody',
                    multiline = true,
                    width = 'full',
                    order = 32
                },

                macroDeleteBox = {
                    name = L['Delete macro'],
                    type = 'select',
                    desc = L['Select a macro to be deleted'],
                    set = 'SetMacroDelete',
                    get = 'GetMacroDelete',
                    style = 'dropdown',
                    values = {},
                    order = 40,
                    confirm = true,
                    confirmText = L['Are you sure you wish to delete the selected macro?']
                },



            },
        },

    },
}

local defaults = {
    profile = {
        macroTable = {},
    },
}

local function createButton(index)
	local button

	if (_G["MMMacroButton"..index]) then
		button = _G["MMMacroButton" .. index]
	else
		button = CreateFrame("CheckButton", "MMMacroButton" .. index, UIParent, "SecureActionButtonTemplate")
	end

    return button
end

function MMMacro:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
    self.db = LibStub("AceDB-3.0"):New("MMMacroDB", defaults)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("MMMacro", options, nil)

    -- initialize flags
    self.inCombat = nil
    self.selectedMacro = nil
    self.selectedMacroName = ""
    self.selectedMacroBody = ""
    self.delayedMacroUpdate = false
    self.defaultMacroBody = ""

    -- Register events
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayerEnterCombat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerLeaveCombat")

    self.db.RegisterCallback(self, "OnNewProfile", "InitializePresets")
    self.db.RegisterCallback(self, "OnProfileReset", "InitializePresets")
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")

    -- Create Interface Config Options
    local ACD = LibStub("AceConfigDialog-3.0")
    ACD:AddToBlizOptions("MMMacro", "MuchMoreMacro", nil, "general")
    ACD:AddToBlizOptions("MMMacro", L["Profile"], "MuchMoreMacro", "profile")

    self:RegisterChatCommand("mmmacro", function() InterfaceOptionsFrame_OpenToCategory("MuchMoreMacro") end)
    self:RegisterChatCommand("muchmoremacro", function() InterfaceOptionsFrame_OpenToCategory("MuchMoreMacro") end)

    -- Populate lists
    self:UpdateMacroList()
end

function MMMacro:OnEnable()
    -- Called when the addon is enabled

    for name, macro in pairs(self.db.profile.macroTable) do
        if macro.binding == "" then
        else
            self:BindMacro(name, macro.binding)
        end
    end
end

function MMMacro:OnDisable()
    -- Called when the addon is disabled
end

function MMMacro:OnPlayerLogin()
    -- this space for rent
end

function MMMacro:OnPlayerEnterCombat()
    self.inCombat = true
end

function MMMacro:OnPlayerLeaveCombat()
    self.inCombat = false
    if self.delayedMacroUpdate == true then
        self:UpdateAll()
        self.delayedMacroUpdate = false
    end
end

function MMMacro:UpdateAll()
    self:UpdateDisplayedMacro()
end



-- Config dialog UI getters and setters
function MMMacro:GetNewMacro(info)
    return ""
end

function MMMacro:SetNewMacro(info, name)
    if strtrim(name) == "" then return end

    local body = self.defaultMacroBody
    self.db.profile.macroTable[name] = {
        body = "",
        binding = "",
    }
    self.db.profile.macroTable[name].body = body
    self:UpdateMacroList()

    self.selectedMacroName = name
    self:UpdateDisplayedMacro()
end

function MMMacro:UpdateDisplayedMacro()
    name = self.selectedMacroName
    self.selectedMacro = self:GetMacroListKeyByName(name)
    if self.selectedMacro then
        self.selectedMacroBody = self.db.profile.macroTable[name].body
        options.args.general.args.macroName.disabled = false
        options.args.general.args.macroEditBox.disabled = false
    else
        self.selectedMacroName = nil
        self.selectedMacroBody = nil
        options.args.general.args.macroName.disabled = true
        options.args.general.args.macroEditBox.disabled = true
    end
end

function MMMacro:GetSelectMacro(info)
    return self.selectedMacro
end

function MMMacro:SetSelectMacro(info, key)
    -- Update contents of macro edit box
    local name = options.args.general.args.macroSelectBox.values[key]
    self.selectedMacroName = name
    self:UpdateDisplayedMacro()
end

function MMMacro:GetMacroName(info)
    return self.selectedMacroName
end

function MMMacro:SetMacroName(info, name)
    if strtrim(name) == "" then return end

    -- Grabs the macro text stored under the old name and stores it under the new name
    local body = self.db.profile.macroTable[self.selectedMacroName].body
    self.db.profile.macroTable[name].body = body

    -- Erases the old name and sets the new name as the selection
    self.db.profile.macroTable[self.selectedMacroName] = nil
    self.selectedMacroName = name
    self:UpdateMacroList()
    self:UpdateDisplayedMacro()
end

function MMMacro:GetMacroBody(info)
    return self.selectedMacroBody
end

function MMMacro:SetMacroBody(info, body)
    self.db.profile.macroTable[self.selectedMacroName].body = body
    self.selectedMacroBody = body
    self:UpdateDisplayedMacro()
end

function MMMacro:UpdateMacroList()
    local macroList = {}
    for name, _ in pairs(self.db.profile.macroTable) do
        table.insert(macroList, name)
    end

    table.sort(macroList)
    options.args.general.args.macroSelectBox.values = macroList
    options.args.general.args.macroDeleteBox.values = macroList
end

function MMMacro:GetMacroListKeyByName(name)
    local index = nil

    for i, macroName in ipairs(options.args.general.args.macroSelectBox.values) do
        if macroName == name then
            index = i
            break
        end
    end

    return index
end

function MMMacro:GetMacroBinding(info)
    if self.selectedMacroName == "" then return "" end

    return self.db.profile.macroTable[self.selectedMacroName].binding
end

function MMMacro:SetMacroBinding(info, macroBinding)
    local name = self.selectedMacroName
    if name == "" then return end
    self.db.profile.macroTable[name].binding = macroBinding

    self:BindMacro(name, macroBinding)
end



-- Macro Processing
function MMMacro:GetMacroDelete(info)
    return nil
end

function MMMacro:SetMacroDelete(info, key)
    local name = options.args.general.args.macroDeleteBox.values[key]
    self.db.profile.macroTable[name] = nil

    self:UpdateMacroList()
    self:UpdateDisplayedMacro()

    -- Do not add deletion of the blizzard macro!
    -- The action bar is tied to the macroID which changes when the macro is re-created
end

function MMMacro:BindMacro(name, binding)
    local macro = self.db.profile.macroTable[name]
    local button = createButton(name)

    if binding == "" then
        ClearOverrideBindings(button)
    else
        button:SetAttribute("type","macro")
        button:SetAttribute("*macrotext*", self.db.profile.macroTable[name].body)
        SetOverrideBindingClick(button, false, binding, button:GetName())
    end
end

-- Profile Handling
function MMMacro:InitializePresets(db, profile)
    self:RefreshConfig()
end

function MMMacro:RefreshConfig()
    self:UpdateMacroList()
    self:UpdateDisplayedMacro()
end