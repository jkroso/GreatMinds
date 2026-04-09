const HISTORY_DIR = joinpath(homedir(), ".greatminds")
const HISTORY_PATH = joinpath(HISTORY_DIR, "history.json")
const DECAY_FACTOR = 0.7

function load_history(path::String=HISTORY_PATH)::Vector{ThoughtRecord}
    isfile(path) || return ThoughtRecord[]
    data = JSON3.read(read(path, String), Vector{Dict{String,Any}})
    [ThoughtRecord(
        d["thought"],
        d["distilled"],
        d["max_similarity"],
        d["result_count"],
        d["timestamp"],
    ) for d in data]
end

function save_history(path::String, records::Vector{ThoughtRecord})
    dir = dirname(path)
    isdir(dir) || mkpath(dir)
    data = [Dict(
        "thought" => r.thought,
        "distilled" => r.distilled,
        "max_similarity" => r.max_similarity,
        "result_count" => r.result_count,
        "timestamp" => r.timestamp,
    ) for r in records]
    write(path, JSON3.write(data))
end

function save_history(records::Vector{ThoughtRecord})
    save_history(HISTORY_PATH, records)
end

function compute_originality(records::Vector{ThoughtRecord})::Float64
    isempty(records) && return 0.5
    total_weight = 0.0
    weighted_sum = 0.0
    n = length(records)
    for (i, r) in enumerate(records)
        weight = DECAY_FACTOR ^ (n - i)
        # Exponential curve: only near-perfect matches (>0.98) really punish you
        # 0.95 sim → 0.60 originality, 0.80 sim → 0.95, 0.99 sim → 0.14
        originality = (1.0 - r.max_similarity^20)
        weighted_sum += originality * weight
        total_weight += weight
    end
    weighted_sum / total_weight
end
