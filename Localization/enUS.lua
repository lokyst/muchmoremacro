local L = LibStub("AceLocale-3.0"):NewLocale("MMMacro", "enUS", true)

if L then

L['General'] = true
L['New Macro'] = true
L['Create a new empty macro'] = true
L['Existing Macros'] = true
L['Select a macro to edit'] = true
L['Macro Name'] = true
L['Macro being edited'] = true
L['Macro Text'] = true
L['Edit your macro. Valid placeholders are:\n\n<hpp> - health potions\n<hps> - healthstones\n<mpp> - mana potions\n<mps> - mana gems\n<hpf> - health food\n<mpf> - mana food\n<b> - bandage\n\nMultiple placeholders can be combined for use in a castsequence, e.g. <hps,hpp>'] = true
L['Delete macro'] = true
L['Select a macro to be deleted'] = true
L['Are you sure you wish to delete the selected macro?'] = true
L['Preview Macro'] = true
L['Create Macro'] = true
L['Creates a macro that can be dragged onto your action bar'] = true
L["Profile"] = true
L["Blizzard macro update aborted: An unrecognised macro called %s already exists. Please rename your macro."] =
    function(s)
        return "Blizzard macro update aborted: An unrecognised macro called "..s.." already exists. Please rename your macro."
    end
L['Macro Binding'] = true

end
