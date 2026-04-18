function render_detail(m::GreatMindsApp, area::Rect, buf::Buffer)
    result = m.search_results[m.selected_result]
    threshold = m.config.similarity_threshold
    pct = string(round(Int, result.similarity * 100)) * "%"

    # Center content like the other screens
    content_width = min(80, area.width - 4)
    content_area = center(area, content_width, area.height)

    layout = Layout(Vertical, [Fixed(3), Fixed(6), Fill(), Fixed(3)])
    rects = split_layout(layout, content_area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Detail", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Tweet block
    tweet_block = Block(
        title="$(result.author) · $pct",
        border_style=result.similarity >= threshold ? tstyle(:error) : tstyle(:primary),
    )
    tweet_inner = render(tweet_block, rects[2], buf)
    padded_inner = margin(tweet_inner; left=1, right=1)
    tweet_layout = Layout(Vertical, [Fill(), Fixed(1)])
    tweet_rects = split_layout(tweet_layout, padded_inner)
    render(Paragraph(result.text; wrap=word_wrap), tweet_rects[1], buf)
    render(Paragraph(result.url; style=tstyle(:text_dim)), tweet_rects[2], buf)

    # Replies section (main content area)
    if m.replies_loading
        reply_block = Block(title="Replies (loading...)", border_style=tstyle(:border))
        reply_inner = render(reply_block, rects[3], buf)
        render(Paragraph("Fetching replies..."; style=tstyle(:text_dim, italic=true)), margin(reply_inner; left=1, right=1), buf)
    elseif !isempty(m.clustered_replies)
        reply_block = Block(title="Replies ($(length(m.clustered_replies)))", border_style=tstyle(:border))
        reply_inner = render(reply_block, rects[3], buf)
        reply_lines = Span[]
        for rc in m.clustered_replies
            count_str = rc.similar_count > 1 ? " (+$(rc.similar_count - 1) similar)" : ""
            push!(reply_lines, Span("$(rc.author)$count_str\n", tstyle(:text_dim)))
            push!(reply_lines, Span("  $(rc.text)\n\n", tstyle(:text)))
        end
        render(Paragraph(reply_lines; wrap=word_wrap, scroll_offset=m.detail_scroll), margin(reply_inner; left=1, right=1), buf)
    else
        reply_block = Block(title="Replies", border_style=tstyle(:border))
        reply_inner = render(reply_block, rects[3], buf)
        render(Paragraph("No replies found."; style=tstyle(:text_dim)), margin(reply_inner; left=1, right=1), buf)
    end

    # Similar phrasings carousel at bottom
    if !isempty(m.similar_phrasings)
        idx = clamp(m.phrasing_index, 1, length(m.similar_phrasings))
        p = m.similar_phrasings[idx]
        nav = "◀ $(idx)/$(length(m.similar_phrasings)) ▶"
        phrasing_block = Block(title="Similar phrasings", title_right=nav, border_style=tstyle(:accent))
        phrasing_inner = render(phrasing_block, rects[4], buf)
        render(Paragraph(
            [Span("$(p.author) ", tstyle(:text_dim)), Span(p.text, tstyle(:text))];
            wrap=word_wrap,
        ), margin(phrasing_inner; left=1, right=1), buf)
    end
end

function update_detail!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.screen = m.search_count == 0 ? home : results
    elseif e.key == :up && m.detail_scroll > 0
        m.detail_scroll -= 1
    elseif e.key == :down
        m.detail_scroll += 1
    elseif e.key == :right && !isempty(m.similar_phrasings)
        m.phrasing_index = m.phrasing_index >= length(m.similar_phrasings) ? 1 : m.phrasing_index + 1
    elseif e.key == :left && !isempty(m.similar_phrasings)
        m.phrasing_index = m.phrasing_index <= 1 ? length(m.similar_phrasings) : m.phrasing_index - 1
    elseif e.key == :char && lowercase(e.char) == 'o'
        result = m.search_results[m.selected_result]
        if !isempty(result.url)
            @static if Sys.isapple()
                run(`open $(result.url)`, wait=false)
            elseif Sys.islinux()
                run(`xdg-open $(result.url)`, wait=false)
            end
        end
    end
end
