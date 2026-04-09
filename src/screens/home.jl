function render_home(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    prompt = input_prompt(tier)

    # Center the content vertically — title + input block in the middle third
    input_height = 5
    total_height = 3 + 1 + input_height  # title + gap + input
    content_area = center(area, min(80, area.width - 4), total_height)

    layout = Layout(Vertical, [Fixed(3), Fixed(1), Fill()])
    rects = split_layout(layout, content_area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Prompt label centered above input
    render(Paragraph(prompt; alignment=align_center, style=tstyle(:text_dim)), rects[2], buf)

    # Input area
    block = Block(border_style=tstyle(:accent))
    inner = render(block, rects[3], buf)
    render(m.input, inner, buf)
end

function update_home!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.quit = true
    elseif e.key == :enter && !isempty(strip(value(m.input)))
        m.original_text = strip(value(m.input))
        m.groking_loading = true
        m.distilled_text = ""
        m.screen = groking
        spawn_task!(m.task_queue_ref, :rewrite) do
            rewrite(m.config, m.original_text)
        end
    else
        handle_key!(m.input, e)
    end
end
