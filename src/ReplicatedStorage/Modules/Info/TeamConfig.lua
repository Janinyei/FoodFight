local TeamConfig = {

    ["red"] = {
        Name = "red",
        DisplayName = "Red",
        Color = Color3.fromRGB(255, 0, 0),
        CombatBlacklist = {"red"}
    },

    ["blue"] = {
          Name = "blue",
          DisplayName = "Blue",
          Color = Color3.fromRGB(10, 51, 255),
          CombatBlacklist = {"red"}
      },

      --for FFA
      ["fighter"] = {
        Name = "fighter",
        DisplayName = "Fighter",
        Color = Color3.fromRGB(151, 161, 153),

      },

      ["neutral"] = {

      }
}








return TeamConfig