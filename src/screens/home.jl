const INPUT_WIDTH = 80

function render_home(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    prompt = input_prompt(tier)

    # Center the content vertically — title + input block in the middle third
    input_height = 7
    total_height = 3 + 1 + input_height  # title + gap + input
    content_area = center(area, min(INPUT_WIDTH, area.width - 4), total_height)

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
    render(m.input, margin(inner; left=1, right=1), buf)
end

function update_home!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.pending_submit_at = 0.0
        m.quit = true
    elseif e.key == :enter && !isempty(strip(value(m.input)))
        m.pending_submit_at = time()
    else
        if m.pending_submit_at > 0.0
            # More input arrived after enter — it was a paste, not a submit.
            # Insert the deferred newline into the textarea instead.
            handle_key!(m.input, KeyEvent(:enter))
            m.pending_submit_at = 0.0
        end
        handle_key!(m.input, e)
        # Soft-wrap: re-flow lines to fit within the visible width
        # Border(2) + padding(2) + cursor(1) = 5 chars of chrome
        soft_wrap_textarea!(m.input, INPUT_WIDTH - 5)
    end
end

"""
Re-flow TextArea lines so no line exceeds `width` characters.
Preserves cursor position across the reflow.
"""
function soft_wrap_textarea!(ta::TextArea, width::Int)
    width < 1 && return
    # Flatten all text into a single string, tracking cursor offset
    flat = ""
    cursor_offset = 0
    for (i, line) in enumerate(ta.lines)
        if i > 1
            flat *= " "
            if i <= ta.cursor_row
                cursor_offset += 1
            end
        end
        line_str = String(line)
        if i < ta.cursor_row
            cursor_offset += length(line)
        elseif i == ta.cursor_row
            cursor_offset += ta.cursor_col
        end
        flat *= line_str
    end

    # Word-wrap the flat string
    words = split(flat, ' ')
    new_lines = Vector{Char}[]
    current_line = Char[]
    for (wi, word) in enumerate(words)
        chars = collect(word)
        if isempty(current_line)
            append!(current_line, chars)
        elseif length(current_line) + 1 + length(chars) <= width
            push!(current_line, ' ')
            append!(current_line, chars)
        else
            push!(new_lines, current_line)
            current_line = copy(chars)
        end
    end
    push!(new_lines, current_line)

    # Map cursor_offset back to (row, col)
    remaining = cursor_offset
    new_row = 1
    new_col = 0
    for (i, line) in enumerate(new_lines)
        line_len = length(line)
        if remaining <= line_len
            new_row = i
            new_col = remaining
            break
        end
        remaining -= line_len + 1  # +1 for the space that became a line break
        if remaining < 0
            new_row = i
            new_col = line_len
            break
        end
        new_row = i + 1
        new_col = 0
    end

    ta.lines = new_lines
    ta.cursor_row = clamp(new_row, 1, length(ta.lines))
    ta.cursor_col = clamp(new_col, 0, length(ta.lines[ta.cursor_row]))
end
