-- Custom pandoc writer used by build-site.sh: emits a <ul> of links to a
-- chapter's level-2 headings for the book's table of contents page.
-- The page URL comes in via -M page-url=/<book>/<chapter>.html and is
-- wrapped in Jekyll's relative_url filter. Heading ids are the ones the
-- markdown reader assigns, so they match the chapter page's anchors as
-- long as both are built with the same reader options.

function Writer(doc, opts)
  local page = pandoc.utils.stringify(doc.meta['page-url'] or '')
  local items = {}

  doc:walk {
    Header = function(h)
      if h.level == 2 and h.identifier ~= '' then
        local text = pandoc.write(pandoc.Pandoc { pandoc.Plain(h.content) }, 'html')
        text = text:gsub('%s+$', '')
        items[#items + 1] = string.format(
          "      <li><a href=\"{{ '%s' | relative_url }}#%s\">%s</a></li>",
          page, h.identifier, text)
      end
    end,
  }

  if #items == 0 then
    return ''
  end
  return '    <ul class="section-list">\n' .. table.concat(items, '\n') .. '\n    </ul>\n'
end
