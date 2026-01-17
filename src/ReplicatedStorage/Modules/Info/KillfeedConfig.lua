local KillFeedConfig = {
    -- Templates use %v for Victim and %k for Killer
    Foods = {
        ["Banana"] = {
            "%v slipped on %k's banana peel!",
            "%k made %v peel out of existence.",
            "%v couldn't find the grip against %k's banana!"
        },
        ["Pizza"] = {
            "%v was delivered a world of hurt by %k!",
            "%k served %v a spicy slice of defeat.",
            "%v got cheesed by %k!"
        },
        ["Donut"] = {
            "%k put a hole through %v's defenses!",
            "%v found %k's attack a bit too sweet to handle.",
            "%v is glazed and confused thanks to %k."
        }
    },
    
    SelfKills = {
        "%v took themselves out of the menu.",
        "%v had a terminal kitchen accident.",
        "%v decided they'd had enough.",
        "%v fumbled the ingredients."
    },

    Environment = {
        "%v was consumed by the void.",
        "%v tripped into the abyss.",
        "%v forgot how physics works."
    }
}

return KillFeedConfig