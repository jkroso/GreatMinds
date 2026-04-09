mutable struct GreatMindsApp <: Model
    screen::Screen
    quit::Bool
    # Input
    input::TextArea
    # Groking
    original_text::String
    distilled_text::String
    groking_loading::Bool
    # Search
    search_results::Vector{SearchResult}
    searching::Bool
    search_count::Int
    # Results
    selected_result::Int
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
        TextArea(label=""),
        "", "", false,
        SearchResult[], false, 0,
        1,
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
    elseif m.screen == groking
        render_groking(m, rects[1], f.buffer)
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
    screen == home      ? "Esc: quit  Enter: grok it" :
    screen == groking   ? "Esc: back  R: regenerate  Enter: search" :
    screen == searching ? "Esc: cancel" :
    screen == results   ? "Esc: back  ↑↓: navigate  Enter: detail" :
    "Esc: back  ↑↓: scroll  O: open in browser"
end

function update!(m::GreatMindsApp, e::KeyEvent)
    (e.action == key_press || e.action == key_repeat) || return

    if m.screen == home
        update_home!(m, e)
    elseif m.screen == groking
        update_groking!(m, e)
    elseif m.screen == searching
        update_searching!(m, e)
    elseif m.screen == results
        update_results!(m, e)
    elseif m.screen == detail
        update_detail!(m, e)
    end
end

function update!(m::GreatMindsApp, e::TaskEvent)
    if e.id == :rewrite && m.screen == groking
        m.distilled_text = e.value::String
        m.groking_loading = false
    elseif e.id == :search && m.screen == searching
        m.search_results = e.value::Vector{SearchResult}
        m.searching = false
        m.search_count = length(m.search_results)
        max_sim = isempty(m.search_results) ? 0.0 : maximum(r.similarity for r in m.search_results)
        record = ThoughtRecord(
            m.original_text, m.distilled_text, max_sim,
            length(m.search_results), Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"),
        )
        push!(m.history, record)
        save_history(m.history)
        m.originality_score = compute_originality(m.history)
        m.screen = results
    elseif e.id == :replies && m.screen == detail
        m.clustered_replies = e.value::Vector{ReplyCluster}
        m.replies_loading = false
    end
end

function main(config_path::String="config.toml")
    config = load_config(config_path)
    model = GreatMindsApp(config)
    app(model)
end
