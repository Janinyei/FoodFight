local modules = {}



for _,v in pairs(script.Modules:Descendants()) do
    require(v)
end