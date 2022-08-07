local Translations = {
    notify = {
        ["no_money"] = "Don't not have enough money",
        ["refuel_cancel"] = "Refueling Canceled",
        ["jerrycan_full"] = "This jerry can is already full",
        ["jerrycan_empty"] = "This jerry can is empty",
        ["vehicle_full"] = "This vehicle is already full",
        ["already_full"] = "Gas Can is already full",
        ["no_nozzle"] = "You Don't Have Nozzle To Refuel The Vehicle",
        ["broke_nozle"] = "You Lost $100 For Losing The Nozzle",
        ["cant_havenozzle"] = "You Have Nozzle",
        ["cant_dontnozzle"] = "You Don't Have Nozzle",

    }
}
Lang = Locale:new({phrases = Translations, warnOnMissing = true})
