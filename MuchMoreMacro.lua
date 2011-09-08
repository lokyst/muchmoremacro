MMMacro = LibStub("AceAddon-3.0"):NewAddon("MMMacro", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MMMacro", true)

-- Set up DataBroker object
local MuchMoreMacroLDB = LibStub("LibDataBroker-1.1"):NewDataObject("MuchMoreMacro", {
    type = "data source",
    text = "",
    label = "MuchMoreMacro",
    icon = "Interface\\MacroFrame\\MacroFrame-Icon",
    OnClick = function(frame, button)
        if button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory("MuchMoreMacro")
        end
    end,
})
local mmmacroDBIcon = LibStub("LibDBIcon-1.0")


local options = {
    name = "MuchMoreMacro",
    handler = MMMacro,
    type = 'group',
    args = {
        main = {
            name = L['Edit Macro'],
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
                    type = 'keybinding',
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

        generalOptions = {
            name = L['General'],
            type = 'group',
            args = {
		showMinimapIcon = {
		    name = L['Show Minimap Icon'],
                    type = 'toggle',
                    desc = L['Show or hide minimap icon'],
		    width = 'full',
                    set = 'SetMinimapIconShow',
                    get = 'GetMinimapIconShow',
                    order = 100,
		},

            },
        },

    },
}

local defaults = {
    profile = {
        macroTable = {},
	minimap = {
	    hide = false,
	},
    },
}

local macroList = {}

-- Button functions
local function getButton(index)
	local button
	if (_G["MMMacroButton"..index]) then
		button = _G["MMMacroButton" .. index]
	else
		button = CreateFrame("CheckButton", "MMMacroButton" .. index, UIParent, "SecureActionButtonTemplate")
	end

    return button
end

local function deleteButton(index)
    local button = getButton(index)
    if button then
        button:SetAttribute("type", nil)
        button:SetAttribute("macrotext", nil)
        ClearOverrideBindings(button)
        return true
    end
    return false
end



-- Initialization and event handling
function MMMacro:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
    self.db = LibStub("AceDB-3.0"):New("MMMacroDB", defaults)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("MMMacro", options, nil)

    -- Add dual-spec support
    local LibDualSpec = LibStub('LibDualSpec-1.0')
    LibDualSpec:EnhanceDatabase(self.db, "MMMacroDB")
    LibDualSpec:EnhanceOptions(options.args.profile, self.db)

    -- initialize flags
    self.inCombat = nil
    self.selectedMacro = nil
    self.selectedMacroName = nil
    self.selectedMacroBody = nil
    self.delayedMacroUpdate = false

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
    ACD:AddToBlizOptions("MMMacro", "MuchMoreMacro", nil, "main")
    ACD:AddToBlizOptions("MMMacro", L["General"], "MuchMoreMacro", "generalOptions")
    ACD:AddToBlizOptions("MMMacro", L["Profile"], "MuchMoreMacro", "profile")

    self:RegisterChatCommand("mmmacro", "ChatCommand")
    self:RegisterChatCommand("muchmoremacro", "ChatCommand")

    -- Populate lists
    self:UpdateDisplayedMacro()
    self:UpdateMacroList()

    -- Register the minimap icon
    mmmacroDBIcon:Register("MuchMoreMacro", MuchMoreMacroLDB, self.db.profile.minimap)

end

function MMMacro:OnEnable()
    -- Called when the addon is enabled
    self:RefreshBindings()
end

function MMMacro:OnDisable()
    -- Called when the addon is disabled
    self:ClearMacros()
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
        -- self:UpdateAll()
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

    if not(self.db.profile.macroTable[name]) then
        self.db.profile.macroTable[name] = {
            body = "",
            bindings = {},
        }
        self:UpdateMacroList()
    end

    self.selectedMacroName = name
    self:UpdateDisplayedMacro()
end

function MMMacro:GetSelectMacro(info)
    return self.selectedMacro
end

function MMMacro:SetSelectMacro(info, key)
    -- Update contents of macro edit box
    local name = options.args.main.args.macroSelectBox.values[key]
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
    local bindings = self.db.profile.macroTable[self.selectedMacroName].bindings
    self.db.profile.macroTable[name] = {}
    self.db.profile.macroTable[name].body = body
    self.db.profile.macroTable[name].bindings = bindings

    -- Erases the old name and sets the new name as the selection
    deleteButton(self.selectedMacroName)
    self.db.profile.macroTable[self.selectedMacroName] = nil

    self.selectedMacroName = name
    self:UpdateMacroList()
    self:UpdateDisplayedMacro()
end

function MMMacro:GetMacroBody(info)
    return self.selectedMacroBody
end

function MMMacro:SetMacroBody(info, body)
    if not self.selectedMacroName then return end

    self.db.profile.macroTable[self.selectedMacroName].body = body
    self.selectedMacroBody = body
    self:UpdateDisplayedMacro()
end

function MMMacro:GetMacroBinding(info)
    if not self.selectedMacroName then return end

    local string = ""
    local bindings = self.db.profile.macroTable[self.selectedMacroName].bindings
    if #bindings > 0 then
        for _, key in ipairs(bindings) do
            string = string .. " " .. key
        end
    end

    return string
end

function MMMacro:SetMacroBinding(info, key)
    local name = self.selectedMacroName
    if name == "" then return end

    if key == "" then
        self.db.profile.macroTable[name].bindings = {}
    else
        for _, binding in ipairs(self.db.profile.macroTable[name].bindings) do
            if key == binding then return end
        end
        table.insert(self.db.profile.macroTable[name].bindings, key)
    end

    self:BindMacro(name, self.db.profile.macroTable[name].bindings)
end

function MMMacro:GetMacroDelete(info)
    return nil
end

function MMMacro:SetMacroDelete(info, key)
    local name = options.args.main.args.macroDeleteBox.values[key]
    self.db.profile.macroTable[name] = nil

    deleteButton(name)

    self:UpdateMacroList()
    self:UpdateDisplayedMacro()
end


function MMMacro:GetMinimapIconShow(info)
    return not self.db.profile.minimap.hide
end

function MMMacro:SetMinimapIconShow(info, value)
    self.db.profile.minimap.hide = not value
    if self.db.profile.minimap.hide then
	    mmmacroDBIcon:Hide("MuchMoreMacro")
    else
	    mmmacroDBIcon:Show("MuchMoreMacro")
    end
end


-- Macro Processing
function MMMacro:BindMacro(name, bindings)
    local macro = self.db.profile.macroTable[name]
    local button = getButton(name)

    if #bindings == 0 then
        ClearOverrideBindings(button)
    else
        button:SetAttribute("type","macro")
        button:SetAttribute("macrotext", self.db.profile.macroTable[name].body)
        ClearOverrideBindings(button)
        for _, key in ipairs(self.db.profile.macroTable[name].bindings) do
            SetOverrideBindingClick(button, false, key, button:GetName())
        end
    end
end

function MMMacro:RefreshBindings()
    for name, macro in pairs(self.db.profile.macroTable) do
        self:BindMacro(name, macro.bindings)
    end
end

function MMMacro:GetMacroListKeyByName(name)
    local index = nil

    for i, macroName in ipairs(options.args.main.args.macroSelectBox.values) do
        if macroName == name then
            index = i
            break
        end
    end

    return index
end

function MMMacro:UpdateMacroList()
    wipe(macroList)
    for name, _ in pairs(self.db.profile.macroTable) do
        table.insert(macroList, name)
    end

    table.sort(macroList)
    options.args.main.args.macroSelectBox.values = macroList
    options.args.main.args.macroDeleteBox.values = macroList
end

function MMMacro:UpdateDisplayedMacro()
    local name = self.selectedMacroName
    self.selectedMacro = self:GetMacroListKeyByName(name)
    if self.selectedMacro then
        self.selectedMacroBody = self.db.profile.macroTable[name].body
        options.args.main.args.macroName.disabled = false
        options.args.main.args.macroEditBox.disabled = false
        options.args.main.args.macroBinding.disabled = false
    else
        self.selectedMacroName = nil
        self.selectedMacroBody = nil
        options.args.main.args.macroName.disabled = true
        options.args.main.args.macroEditBox.disabled = true
        options.args.main.args.macroBinding.disabled = true
    end
    self:RefreshBindings()
end

-- Chat command handling
function MMMacro:ChatCommand(input)
    if not input or input:trim() == "" then
	InterfaceOptionsFrame_OpenToCategory("MuchMoreMacro")
    else
	LibStub("AceConfigCmd-3.0").HandleCommand(MuchMoreMacro, "mmmacro", "MMMacro", input)
    end
end

-- Profile Handling
function MMMacro:InitializePresets(db, profile)
    self:RefreshConfig()
end

function MMMacro:RefreshConfig()
    self:ClearMacros()
    self:UpdateMacroList()
    self:UpdateDisplayedMacro()
end

function MMMacro:ClearMacros()
    for _, name in ipairs(macroList) do
        deleteButton(name)
    end
end