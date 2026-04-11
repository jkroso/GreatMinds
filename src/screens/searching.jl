function render_searching(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    status = searching_status(tier)

    content_area = center(area, min(50, area.width), 7)

    layout = Layout(Vertical, [Fixed(3), Fixed(1), Fixed(1), Fixed(1)])
    rects = split_layout(layout, content_area)

    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Searching", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    render(Paragraph(status; alignment=align_center, style=tstyle(:accent)), rects[2], buf)

    gauge = Gauge(0.5; filled_style=tstyle(:accent), label="")
    render(gauge, rects[3], buf)

    count_msg = m.search_count > 0 ? "Found $(m.search_count) results so far..." : ""
    render(Paragraph(count_msg; alignment=align_center, style=tstyle(:text_dim)), rects[4], buf)
end

function update_searching!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.searching = false
        m.screen = home
    end
end
