local Industry = {}

-- Example static values (can later become dynamic/simulated)
Industry.manufacturingOutput = 1500
Industry.employmentRate = 0.25
Industry.exports = 300

function Industry.draw(x, y, width)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Industry Overview", x, y + 20, width, "center")

    local info = string.format(
        "Manufacturing output: %d units\nEmployment: %.0f%%\nExports: %d units",
        Industry.manufacturingOutput,
        Industry.employmentRate * 100,
        Industry.exports
    )

    love.graphics.printf(info, x + 50, y + 80, width - 100, "left")
end

-- Optional: Weekly update simulation
function Industry.updateByWeeks(weeks)
    -- You could simulate changes in output, employment, exports etc.
    -- e.g. Industry.manufacturingOutput = Industry.manufacturingOutput + weeks * 10
end

needs_pyramid = {
    {
        level = 1,
        name = "Basisbehoeften",
        examples = {
            "Voedsel",
            "Water",
            "Energie (brandstof/stroom)",
            "Huur / onderdak",
            "Kleding (minimaal)",
            "Basale zorg (vaccinaties, eerste hulp)"
        }
    },
    {
        level = 2,
        name = "Veiligheid & Zekerheid",
        examples = {
            "Woningverbetering / beveiliging",
            "Zorgverzekering",
            "Spaarrekening",
            "Vaste baan / inkomen",
            "School voor kinderen (basis)",
            "Transport (fiets, OV)"
        }
    },
    {
        level = 3,
        name = "Sociale binding & status",
        examples = {
            "Feesten / bruiloften / cadeaus",
            "Relatievorming / dating / bruidsprijs",
            "Communicatiemiddelen (telefoon, internet)",
            "Kleding (modieus)",
            "Religieuze giften",
            "Sociale bijdragen (familie steunen)"
        }
    },
    {
        level = 4,
        name = "Ontwikkeling & onderwijs",
        examples = {
            "Hoger onderwijs / bijles",
            "Privé-onderwijs voor kinderen",
            "Computer / boeken",
            "Talen leren",
            "Cursussen / certificaten"
        }
    },
    {
        level = 5,
        name = "Zelfontplooiing & luxe",
        examples = {
            "Vakanties",
            "Luxe goederen (auto, sieraden)",
            "Fitness & sportclubs",
            "Entertainment (games, films, concerten)",
            "Hobby’s & creativiteit",
            "Designmeubels"
        }
    }
}


-- function Company:updateWeek()
--     self:calculateRevenue()
--     self:calculateCosts()
--     self:calculateNetProfit()
--     self:distributeProfit()
--     self:adjustStrategy()
-- end

return Industry