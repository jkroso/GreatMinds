function render_groking(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    label = groking_label(tier)

    layout = Layout(Vertical, [Fixed(3), Fixed(1), Fill(), Fixed(1), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Groking", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Label
    render(Paragraph(label; alignment=align_center), rects[2], buf)

    # Original text (dimmed, bordered)
    orig_block = Block(title="Your thought", border_style=tstyle(:text_dim))
    orig_inner = render(orig_block, rects[3], buf)
    render(Paragraph(m.original_text; wrap=word_wrap, style=tstyle(:text_dim)), orig_inner, buf)

    # Distilled text or loading
    if m.groking_loading
        dist_block = Block(title="Distilling...", border_style=tstyle(:accent))
        dist_inner = render(dist_block, rects[5], buf)
        render(Paragraph("Groking your thought..."; wrap=word_wrap, style=tstyle(:text_dim, italic=true)), dist_inner, buf)
    else
        dist_block = Block(title="Core idea", border_style=tstyle(:accent))
        dist_inner = render(dist_block, rects[5], buf)
        render(Paragraph(m.distilled_text; wrap=word_wrap, style=tstyle(:text_bright)), dist_inner, buf)
    end
end

function update_groking!(m::GreatMindsApp, e::KeyEvent)
    m.groking_loading && return

    if e.key == :escape
        m.screen = home
    elseif e.key == :enter && !isempty(m.distilled_text)
        m.searching = true
        m.search_results = SearchResult[]
        m.search_count = 0
        m.selected_result = 1
        m.screen = searching
        spawn_task!(m.task_queue_ref, :search) do
            search_similar(m.config, m.distilled_text)
        end
    elseif e.key == :char && lowercase(e.char) == 'r'
        m.groking_loading = true
        m.distilled_text = ""
        spawn_task!(m.task_queue_ref, :rewrite) do
            rewrite(m.config, m.original_text)
        end
    end
end
