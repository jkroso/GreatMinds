function tone_tier(score::Float64)::ToneTier
    score <= 0.25 ? npc :
    score <= 0.40 ? normie :
    score <= 0.60 ? neutral :
    score <= 0.75 ? freethinker :
    insane
end

function input_prompt(tier::ToneTier)::String
    tier == npc         ? "What's your take, NPC?" :
    tier == normie      ? "Go on then, what's your take?" :
    tier == neutral     ? "What's your take?" :
    tier == freethinker ? "What's your take, original?" :
    "What's your take, you absolute psycho?"
end

function searching_status(tier::ToneTier)::String
    tier == npc         ? "Searching for who said it first..." :
    tier == normie      ? "Let's see how common this is..." :
    tier == neutral     ? "Searching X..." :
    tier == freethinker ? "Scanning the timeline for fellow travelers..." :
    "Let's see if anyone else is this unhinged..."
end

function results_verdict(tier::ToneTier, is_original::Bool)::String
    if is_original
        tier == npc         ? "Wait... did you just have an original thought?" :
        tier == normie      ? "Huh, that's actually kind of fresh" :
        tier == neutral     ? "Original take!" :
        tier == freethinker ? "Another original — you're on a streak" :
        "Nobody. You're alone out here. Again."
    else
        tier == npc         ? "Called it. NPC confirmed." :
        tier == normie      ? "Yeah, a few people beat you to it" :
        tier == neutral     ? "Already expressed" :
        tier == freethinker ? "Even originals overlap sometimes" :
        "Even geniuses repeat sometimes"
    end
end

function score_label(tier::ToneTier)::String
    tier == npc         ? "NPC" :
    tier == normie      ? "Normie" :
    tier == neutral     ? "Thinker" :
    tier == freethinker ? "Free Thinker" :
    "Insane"
end
