const INPUT_WIDTH = 80

function render_home(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    prompt = input_prompt(tier)

    # Size the input box to fit content (border=2, cursor=1 minimum line)
    input_height = max(3, length(m.input.lines) + 2)
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
        m.pending_newlines = 0
        m.quit = true
    elseif e.key == :enter && !isempty(strip(value(m.input)))
        m.pending_newlines += 1
        m.pending_submit_at = time()
    else
        if m.pending_newlines > 0
            # More input arrived after enter — it was a paste, not a submit.
            # Insert all deferred newlines into the textarea.
            for _ in 1:m.pending_newlines
                handle_key!(m.input, KeyEvent(:enter))
            end
            m.pending_newlines = 0
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

    # Group lines into paragraphs (runs of non-empty lines),
    # tracking how many blank lines precede each paragraph.
    paragraphs = Tuple{Int, Vector{String}}[]  # (preceding_blanks, lines)
    current_para = String[]
    blank_count = 0
    for line in ta.lines
        s = String(line)
        if isempty(s)
            if !isempty(current_para)
                push!(paragraphs, (blank_count, current_para))
                current_para = String[]
                blank_count = 0
            end
            blank_count += 1
        else
            push!(current_para, s)
        end
    end
    push!(paragraphs, (blank_count, current_para))

    # Compute cursor offset as a flat character position across all lines
    cursor_offset = 0
    for i in 1:length(ta.lines)
        if i < ta.cursor_row
            cursor_offset += length(ta.lines[i]) + 1  # +1 for the join char
        elseif i == ta.cursor_row
            cursor_offset += ta.cursor_col
            break
        end
    end

    # Word-wrap each paragraph independently, preserving blank lines
    new_lines = Vector{Char}[]
    for (blanks, para) in paragraphs
        for _ in 1:blanks
            push!(new_lines, Char[])
        end
        isempty(para) && continue
        flat = join(para, ' ')
        words = split(flat, ' ')
        current_line = Char[]
        for word in words
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
    end
    isempty(new_lines) && push!(new_lines, Char[])

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
        remaining -= line_len + 1
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
