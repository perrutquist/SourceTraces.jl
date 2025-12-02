module SourceTraces

export expression_line_spans

"""
    expression_line_spans(src::AbstractString) -> Vector{Pair{Int,Int}}

Return a vector of `UnitRange`s giving the `(start_line : end_line)` for each
top-level expression parsed from `src` using `Meta.parse(src, i; greedy=true)`
repeatedly.

Line numbers are 1-based and computed from the first and last non-whitespace
character of each expression.
"""
function expression_line_spans(src::AbstractString)
    newlines = _newline_indices(src)
    spans = UnitRange[]

    n = lastindex(src)
    i = firstindex(src)

    while i <= n
        expr, j = Meta.parse(src, i, greedy = true)

        # Stop if there are no more expressions
        expr === nothing && break
        j <= i && break

        # Region that Meta.parse consumed this round
        seg_start = i
        seg_end = j > n ? n : prevind(src, j)

        # Trim leading whitespace to find first character of the expression
        istart = seg_start
        while istart <= seg_end && isspace(src[istart])
            istart = nextind(src, istart)
        end

        # Trim trailing whitespace to find last character of the expression
        iend = seg_end
        while iend >= istart && isspace(src[iend])
            iend = prevind(src, iend)
        end

        # If there is any non-whitespace content, record its line span
        if istart <= iend
            start_line = _line_for_index(newlines, istart)
            end_line = _line_for_index(newlines, iend)
            push!(spans, start_line:end_line)

            # If this is a module expression, also parse its contents one level deeper
            if expr isa Expr && expr.head === :module
                # Heuristically take the lines between the `module` header and the final `end`
                first_nl_idx = searchsortedfirst(newlines, istart)
                if first_nl_idx <= length(newlines)
                    header_nl = newlines[first_nl_idx]
                    if header_nl < iend
                        last_body_nl_idx = searchsortedlast(newlines, iend - 1)
                        if last_body_nl_idx > first_nl_idx
                            body_start = nextind(src, header_nl)
                            body_end_nl = newlines[last_body_nl_idx]
                            body_end = prevind(src, body_end_nl)
                            if body_start <= body_end
                                body_src = src[body_start:body_end]
                                body_spans = expression_line_spans(body_src)
                                body_start_line = _line_for_index(newlines, body_start)
                                for span in body_spans
                                    push!(spans,
                                          (first(span) + body_start_line - 1):
                                          (last(span) + body_start_line - 1))
                                end
                            end
                        end
                    end
                end
            end
        end

        i = j
    end

    return spans
end

# --- Internal helpers --------------------------------------------------------

# Collect the indices of all newline characters in the source string.
function _newline_indices(src::AbstractString)
    idxs = Int[]
    for i in eachindex(src)
        src[i] == '\n' && push!(idxs, i)
    end
    return idxs
end

# Map a character index to a 1-based line number using precomputed newline indices.
@inline function _line_for_index(newlines::Vector{Int}, idx::Int)::Int
    # Number of newlines strictly before `idx`, plus 1
    return searchsortedlast(newlines, idx - 1) + 1
end

end
