local stringFuncs = {}



function stringFuncs.formatText(text)
    local ot = text

    text = string.gsub(text, "(%d+)[.,](%d+)",
        function(n1,n2)
            --don't call console from here!!!!
            local ns = n1.."."..n2
            local n = tonumber(ns) 
            --nf = string.format(n, "%.1f") 
            nf = string.format("%."..globalDecimals.."f", n) 
            return nf
        end
        )

    return text
end

return stringFuncs
