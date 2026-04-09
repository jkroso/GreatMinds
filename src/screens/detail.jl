function render_detail(m::GreatMindsApp, area::Rect, buf::Buffer)
    result = m.search_results[m.selected_result]
    threshold = m.config.similarity_threshold
    pct = string(round(Int, result.similarity * 100)) * "%"

    layout = Layout(Vertical, [Fixed(3), Fixed(6), Fill()])
    rects = split_layout(layout, area)

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
    tweet_layout = Layout(Vertical, [Fill(), Fixed(1)])
    tweet_rects = split_layout(tweet_layout, tweet_inner)
    render(Paragraph(result.text; wrap=word_wrap), tweet_rects[1], buf)
    render(Paragraph(result.url; style=tstyle(:text_dim)), tweet_rects[2], buf)

    # Bottom section: phrasings + replies
    bottom_layout = Layout(Vertical, [Fixed(1), Fill(), Fixed(1), Fill()])
    bottom_rects = split_layout(bottom_layout, rects[3])

    # Similar phrasings
    phrasing_label = "Similar phrasings ($(length(m.similar_phrasings)))"
    render(Paragraph(phrasing_label; style=tstyle(:text_dim)), bottom_rects[1], buf)

    if !isempty(m.similar_phrasings)
        phrasing_block = Block(border_style=tstyle(:accent))
        phrasing_inner = render(phrasing_block, bottom_rects[2], buf)
        lines = [Span("\u201c$(p.text)\u201d $(p.author)\n", tstyle(:text)) for p in m.similar_phrasings]
        render(Paragraph(lines; wrap=word_wrap, scroll_offset=m.detail_scroll), phrasing_inner, buf)
    end

    # Clustered replies
    if m.replies_loading
        reply_label = "Replies (loading...)"
    else
        reply_label = "Replies ($(length(m.clustered_replies)) clusters)"
    end
    render(Paragraph(reply_label; style=tstyle(:text_dim)), bottom_rects[3], buf)

    if !isempty(m.clustered_replies)
        reply_block = Block(border_style=tstyle(:border))
        reply_inner = render(reply_block, bottom_rects[4], buf)
        reply_lines = Span[]
        for rc in m.clustered_replies
            count_str = rc.similar_count > 1 ? " (+$(rc.similar_count - 1) similar)" : ""
            push!(reply_lines, Span("$(rc.author)$count_str\n", tstyle(:text_dim)))
            push!(reply_lines, Span("  $(rc.text)\n\n", tstyle(:text)))
        end
        render(Paragraph(reply_lines; wrap=word_wrap), reply_inner, buf)
    end
end

function update_detail!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.screen = results
    elseif e.key == :up && m.detail_scroll > 0
        m.detail_scroll -= 1
    elseif e.key == :down
        m.detail_scroll += 1
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
