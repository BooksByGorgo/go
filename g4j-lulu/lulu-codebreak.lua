-- lulu-codebreak.lua --- allow line breaks inside long inline code spans.
--
-- The 7x10 lulu trim has a 5.5in text block, so long unbreakable
-- \texttt tokens (module paths, chained method calls) that fit the
-- letter build overflow into lulu's 0.5in safety margin or past the
-- trim edge. Split code spans of 12+ characters after '/', '.', '(',
-- and spaces, and before camel-case capitals, so TeX can wrap them at
-- sensible points (pandoc renders code spaces as unbreakable '\ ').
-- Headings are skipped so PDF bookmarks stay free of raw latex.
-- Only the lulu build uses this filter; the letter build is untouched.

local MIN = 12

-- Only cut at ASCII boundaries, so multi-byte UTF-8 sequences inside
-- the span are never split.
local function breakup(text, attr)
  local breaks = {}
  for i = 1, #text - 1 do
    local char = text:sub(i, i)
    local following = text:sub(i + 1, i + 1)
    if char:find("[./( ]") or (char:find("%l") and following:find("%u")) then
      breaks[i] = true
    end
  end

  -- "Unauthenticated" has no punctuation or camel-case boundary, but
  -- occurs in a narrow status-code table cell. Its prefix is a natural
  -- place to wrap without changing the identifier shown to the reader.
  if next(breaks) == nil and text:find("^Un%l") then
    breaks[2] = true
  end

  if next(breaks) == nil then
    return nil
  end

  local out = pandoc.Inlines({})
  local start = 1
  for i = 1, #text - 1 do
    if breaks[i] then
      out:insert(pandoc.Code(text:sub(start, i), attr))
      out:insert(pandoc.RawInline("latex", "\\allowbreak{}"))
      start = i + 1
    end
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
      return breakup(c.text, c.attr)
    end,
  },
}
