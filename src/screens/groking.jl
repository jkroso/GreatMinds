function render_groking(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    label = groking_label(tier)

    content_width = min(80, area.width - 4)
    # Border(2) + margin(2) = 4 chars of horizontal chrome per box
    inner_width = content_width - 4

    # Build paragraphs so we can measure their wrapped height
    use_orig = m.groking_use_original
    orig_style = use_orig ? tstyle(:text_bright) : tstyle(:text_dim)
    orig_para = Paragraph(m.original_text; wrap=word_wrap, style=orig_style)
    orig_h = paragraph_line_count(orig_para, inner_width) + 2  # +2 for border

    dist_text = m.groking_loading ? "Groking your thought..." : m.distilled_text
    dist_style = m.groking_loading ? tstyle(:text_dim, italic=true) :
                 use_orig ? tstyle(:text_dim) : tstyle(:text_bright)
    dist_title = m.groking_loading ? "Distilling..." : "Core idea"
    dist_para = Paragraph(dist_text; wrap=word_wrap, style=dist_style)
    dist_h = paragraph_line_count(dist_para, inner_width) + 2  # +2 for border

    total_h = 3 + orig_h + 1 + dist_h  # title + orig + label + dist
    content_area = center(area, content_width, min(total_h, area.height - 2))

    layout = Layout(Vertical, [Fixed(3), Fixed(orig_h), Fixed(1), Fill()])
    rects = split_layout(layout, content_area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Groking", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Original text
    orig_border = use_orig ? tstyle(:accent) : tstyle(:text_dim)
    orig_block = Block(title="Your thought", border_style=orig_border)
    orig_inner = render(orig_block, rects[2], buf)
    render(orig_para, margin(orig_inner; left=1, right=1), buf)

    # Label between the two boxes
    render(Paragraph(label; alignment=align_center, style=tstyle(:text_dim)), rects[3], buf)

    # Distilled text or loading
    dist_border = use_orig ? tstyle(:text_dim) : tstyle(:accent)
    dist_block = Block(title=dist_title, border_style=dist_border)
    dist_inner = render(dist_block, rects[4], buf)
    render(dist_para, margin(dist_inner; left=1, right=1), buf)
end

function update_groking!(m::GreatMindsApp, e::KeyEvent)
    m.groking_loading && return

    if e.key == :escape
        m.screen = home
    elseif (e.key == :up || e.key == :down) && !m.groking_loading
        m.groking_use_original = !m.groking_use_original
    elseif e.key == :enter && !isempty(m.distilled_text)
        search_text = m.groking_use_original ? m.original_text : m.distilled_text
        m.searching = true
        m.search_results = SearchResult[]
        m.search_count = 0
        m.selected_result = 1
        m.screen = searching
        spawn_task!(m.task_queue_ref, :search) do
            search_similar(m.config, search_text)
        end
    end
end
