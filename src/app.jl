mutable struct GreatMindsApp <: Model
    screen::Screen
    quit::Bool
    # Input
    input::TextArea
    pending_submit_at::Float64   # 0.0 = not pending; otherwise time() of deferred Enter
    pending_newlines::Int        # number of deferred Enter presses to insert on next char
    # Search input
    original_text::String
    # Search
    search_results::Vector{SearchResult}
    searching::Bool
    search_count::Int
    # Results
    selected_result::Int
    results_scroll::Int
    # Detail
    similar_phrasings::Vector{Phrasing}
    clustered_replies::Vector{ReplyCluster}
    detail_scroll::Int
    phrasing_index::Int
    replies_loading::Bool
    # Personality
    history::Vector{ThoughtRecord}
    originality_score::Float64
    # Infra
    config::Config
    task_queue_ref::TaskQueue
    notify::Union{Function,Nothing}
end

function GreatMindsApp(config::Config)
    history = load_history()
    score = compute_originality(history)
    GreatMindsApp(
        home, false,
        TextArea(label=""), 0.0, 0,
        "",
        SearchResult[], false, 0,
        1, 0,
        Phrasing[], ReplyCluster[], 0, 1, false,
        history, score,
        config, TaskQueue(), nothing,
    )
end

function set_wake!(m::GreatMindsApp, notify::Function)
    m.notify = notify
    m.task_queue_ref = TaskQueue(on_ready=notify)
end

task_queue(m::GreatMindsApp) = m.task_queue_ref
should_quit(m::GreatMindsApp) = m.quit

function view(m::GreatMindsApp, f::Frame)
    layout = Layout(Vertical, [Fill(), Fixed(1)])
    rects = split_layout(layout, f.area)

    if m.screen == home
        render_home(m, rects[1], f.buffer)
    elseif m.screen == searching
        render_searching(m, rects[1], f.buffer)
    elseif m.screen == results
        render_results(m, rects[1], f.buffer)
    elseif m.screen == detail
        render_detail(m, rects[1], f.buffer)
    end

    render_status_bar(m, rects[2], f.buffer)
end

function render_status_bar(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    label = score_label(tier)
    score_str = string(round(m.originality_score, digits=2))
    filled = round(Int, m.originality_score * 10)
    gauge = "█"^filled * "░"^(10 - filled)

    bar = StatusBar(
        left=[Span("[$label $gauge $score_str]", tstyle(:accent, bold=true))],
        right=[Span(status_bar_keys(m.screen), tstyle(:text_dim))],
        style=tstyle(:text_dim),
    )
    render(bar, area, buf)
end

function status_bar_keys(screen::Screen)::String
    screen == home      ? "Esc: quit  Enter: search  ^H: clear history" :
    screen == searching ? "Esc: cancel" :
    screen == results   ? "Esc: back  ↑↓: navigate  Enter: detail" :
    "Esc: back  ↑↓: scroll  ◀▶: phrasings  O: open in browser"
end

const PASTE_GRACE_S = 0.05  # 50 ms — long enough for paste bytes to arrive across frames

function pre_render!(m::GreatMindsApp)
    # Deferred submit: wait for the grace period after Enter so that
    # newlines in pasted text aren't mistaken for a submit keypress.
    if m.pending_submit_at > 0.0 && m.screen == home &&
       time() - m.pending_submit_at >= PASTE_GRACE_S &&
       !isempty(strip(value(m.input)))
        m.pending_submit_at = 0.0
        m.pending_newlines = 0
        m.original_text = strip(value(m.input))
        m.searching = true
        m.search_results = SearchResult[]
        m.search_count = 0
        m.selected_result = 1
        m.screen = searching
        spawn_task!(m.task_queue_ref, :search) do
            search_similar(m.config, m.original_text)
        end
    end
end

function update!(m::GreatMindsApp, e::KeyEvent)
    (e.action == key_press || e.action == key_repeat) || return

    # Global hotkey: Ctrl+H clears history
    if e.key == :ctrl && e.char == 'h'
        m.history = ThoughtRecord[]
        save_history(m.history)
        m.originality_score = 0.5
        return
    end

    if m.screen == home
        update_home!(m, e)
    elseif m.screen == searching
        update_searching!(m, e)
    elseif m.screen == results
        update_results!(m, e)
    elseif m.screen == detail
        update_detail!(m, e)
    end
end

function update!(m::GreatMindsApp, e::TaskEvent)
    if e.id == :search && m.screen == searching
        m.search_results = e.value::Vector{SearchResult}
        m.searching = false
        m.search_count = length(m.search_results)
        max_sim = isempty(m.search_results) ? 0.0 : maximum(r.similarity for r in m.search_results)
        record = ThoughtRecord(
            m.original_text, "", max_sim,
            length(m.search_results), Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"),
        )
        push!(m.history, record)
        save_history(m.history)
        m.originality_score = compute_originality(m.history)
        m.results_scroll = 0
        m.screen = results
    elseif e.id == :replies && m.screen == detail
        m.clustered_replies = e.value::Vector{ReplyCluster}
        m.replies_loading = false
    end
end

const DEFAULT_CONFIG_PATH = joinpath(homedir(), ".greatminds", "config.toml")

function main(config_path::String=DEFAULT_CONFIG_PATH)
    if !isfile(config_path)
        # Try local config.toml as fallback (for development)
        if isfile("config.toml")
            config_path = "config.toml"
        end
    end
    config = load_config(config_path)
    model = GreatMindsApp(config)
    app(model)
end
