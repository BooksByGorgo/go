-- lulu-codebreak.lua --- allow line breaks inside long inline code spans.
--
-- The 7x10 lulu trim has a 5.5in text block, so long unbreakable
-- \texttt tokens (module paths, chained method calls) that fit the
-- letter build overflow into lulu's 0.5in safety margin or past the
-- trim edge. Split code spans of 12+ characters after '/', '.', '('
-- and spaces with \allowbreak so TeX can wrap them at sensible points
-- (pandoc renders code spaces as unbreakable '\ ').
-- Headings are skipped so PDF bookmarks stay free of raw latex.
-- Only the lulu build uses this filter; the letter build is untouched.

local MIN = 12

-- Only cut after ASCII delimiters, so multi-byte UTF-8 sequences
-- inside the span are never split.
local function breakup(text, attr, pattern)
  local out = pandoc.Inlines({})
  local start = 1
  while true do
    local pos = text:find(pattern, start)
    if not pos or pos >= #text then break end
    out:insert(pandoc.Code(text:sub(start, pos), attr))
    out:insert(pandoc.RawInline("latex", "\\allowbreak{}"))
    start = pos + 1
  end
  out:insert(pandoc.Code(text:sub(start), attr))
  return out
end

return {
  {
    traverse = "topdown",
    Header = function(h)
      return h, false
    end,
    Code = function(c)
      if #c.text < MIN then
        return nil
      end
      if c.text:find("[./( ]") then
        return breakup(c.text, c.attr, "[./( ]")
      end
      -- No delimiter at all (e.g. IllegalArgumentException): fall back
      -- to breaking after a lowercase letter at a camelCase boundary.
      if c.text:find("[a-z][A-Z]") then
        return breakup(c.text, c.attr, "[a-z]%u")
      end
      return nil
    end,
  },
}
