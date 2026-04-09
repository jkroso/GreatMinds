function render_home(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    prompt = input_prompt(tier)

    layout = Layout(Vertical, [Fixed(3), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Input area with prompt label
    m.input.label = prompt
    block = Block(title="Your thought", border_style=tstyle(:border))
    inner = render(block, rects[2], buf)
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
