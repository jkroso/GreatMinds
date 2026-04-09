function render_results(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    threshold = m.config.similarity_threshold
    has_duplicates = any(r.similarity >= threshold for r in m.search_results)
    verdict = results_verdict(tier, !has_duplicates)

    layout = Layout(Vertical, [Fixed(3), Fixed(2), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Results ($(length(m.search_results)) found)", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Verdict banner
    verdict_style = has_duplicates ? tstyle(:error, bold=true) : tstyle(:success, bold=true)
    dup_count = count(r -> r.similarity >= threshold, m.search_results)
    suffix = has_duplicates ? " — $dup_count posts ≥$(round(Int, threshold*100))% similar" : ""
    render(Paragraph([Span(verdict, verdict_style), Span(suffix, tstyle(:text_dim))]; alignment=align_center), rects[2], buf)

    # Results list
    if isempty(m.search_results)
        render(Paragraph("No results found."; alignment=align_center, style=tstyle(:text_dim)), rects[3], buf)
    else
        items = [format_result_line(r, threshold, area.width) for r in m.search_results]
        list = SelectableList(items;
            selected=m.selected_result,
            highlight_style=tstyle(:accent, bold=true),
            block=Block(border_style=tstyle(:border)),
        )
        render(list, rects[3], buf)
    end
end

function format_result_line(r::SearchResult, threshold::Float64, width::Int)::String
    pct = string(round(Int, r.similarity * 100)) * "%"
    badge = "[$pct]"
    author = r.author
    max_text = max(10, width - length(badge) - length(author) - 6)
    text = length(r.text) > max_text ? first(r.text, max_text) * "…" : r.text
    "$badge $author $text"
end

function update_results!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.screen = groking
    elseif e.key == :enter && !isempty(m.search_results)
        m.detail_scroll = 0
        m.similar_phrasings = Phrasing[]
        m.clustered_replies = ReplyCluster[]
        m.replies_loading = true
        m.screen = detail

        result = m.search_results[m.selected_result]
        spawn_task!(m.task_queue_ref, :replies) do
            fetch_replies(m.config, result.id)
        end

        threshold = m.config.similarity_threshold
        m.similar_phrasings = [
            Phrasing(r.text, r.author)
            for (i, r) in enumerate(m.search_results)
            if i != m.selected_result && r.similarity >= threshold
        ]
    elseif e.key == :up && m.selected_result > 1
        m.selected_result -= 1
    elseif e.key == :down && m.selected_result < length(m.search_results)
        m.selected_result += 1
    end
end
