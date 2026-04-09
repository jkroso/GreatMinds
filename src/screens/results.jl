function render_results(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    threshold = m.config.similarity_threshold
    has_duplicates = any(r.similarity >= threshold for r in m.search_results)
    verdict = results_verdict(tier, !has_duplicates)

    # Center content like the other screens
    content_width = min(80, area.width - 4)
    content_area = center(area, content_width, area.height)

    layout = Layout(Vertical, [Fixed(3), Fixed(2), Fill()])
    rects = split_layout(layout, content_area)

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

    # Results as scrollable paragraphs
    if isempty(m.search_results)
        render(Paragraph("No results found."; alignment=align_center, style=tstyle(:text_dim)), rects[3], buf)
    else
        block = Block(border_style=tstyle(:border))
        inner = render(block, rects[3], buf)
        spans = Span[]
        for (i, r) in enumerate(m.search_results)
            pct = string(round(Int, r.similarity * 100)) * "%"
            badge_style = r.similarity >= threshold ? tstyle(:error, bold=true) : tstyle(:primary, bold=true)
            selected = i == m.selected_result

            # Selection marker
            marker = selected ? "▶ " : "  "
            marker_style = selected ? tstyle(:accent, bold=true) : tstyle(:text)
            push!(spans, Span(marker, marker_style))

            # Badge
            push!(spans, Span("[$pct] ", badge_style))

            # Author
            push!(spans, Span("$(r.author) ", tstyle(:text_dim)))

            # Tweet text — use accent style if selected
            text_style = selected ? tstyle(:accent) : tstyle(:text)
            push!(spans, Span(r.text, text_style))

            # Separator between results
            if i < length(m.search_results)
                push!(spans, Span("\n\n", tstyle(:text)))
            end
        end
        render(Paragraph(spans; wrap=word_wrap, scroll_offset=m.detail_scroll), margin(inner; left=1, right=1), buf)
    end
end

function update_results!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.screen = groking
    elseif e.key == :enter && !isempty(m.search_results)
        m.detail_scroll = 0
        m.phrasing_index = 1
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
