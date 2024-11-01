local M = {}

local highlight_groups = {
  [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualTextError",
  [vim.diagnostic.severity.WARN] = "DiagnosticVirtualTextWarn",
  [vim.diagnostic.severity.INFO] = "DiagnosticVirtualTextInfo",
  [vim.diagnostic.severity.HINT] = "DiagnosticVirtualTextHint",
}

-- These don't get copied, do they? We only pass around and compare pointers, right?
local SPACE = "space"
local DIAGNOSTIC = "diagnostic"
local OVERLAP = "overlap"
local BLANK = "blank"

-- Deprecated. Use `setup()` instead.
M.register_lsp_virtual_lines = function()
  print("lsp_lines.register_lsp_virtual_lines() is deprecated. use lsp_lines.setup() instead.")
  M.setup()
end

local function column_to_cell(bufnr, lnum, col)
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)

  if not vim.tbl_isempty(lines) then
    local line = lines[1]
    local sub = string.sub(line, 1, col)
    return vim.fn.strdisplaywidth(sub, 0)
  end

  return col
end

M.setup = function()
  vim.diagnostic.handlers.virtual_lines = {
    show = function(namespace, bufnr, diagnostics, opts)
      vim.validate({
        namespace = { namespace, "n" },
        bufnr = { bufnr, "n" },
        diagnostics = {
          diagnostics,
          vim.tbl_islist,
          "a list of diagnostics",
        },
        opts = { opts, "t", true },
      })

      table.sort(diagnostics, function(a, b)
        if a.lnum ~= b.lnum then
          return a.lnum < b.lnum
        else
          return a.col < b.col
        end
      end)

      local ns = vim.diagnostic.get_namespace(namespace)
      if not ns.user_data.virt_lines_ns then
        ns.user_data.virt_lines_ns = vim.api.nvim_create_namespace("")
      end
      local virt_lines_ns = ns.user_data.virt_lines_ns

      vim.api.nvim_buf_clear_namespace(bufnr, virt_lines_ns, 0, -1)

      local line_stacks = {}
      local prev_lnum = -1
      local prev_col = -1
      for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.severity == vim.diagnostic.severity.ERROR then  -- Show only errors
          if line_stacks[diagnostic.lnum] == nil then
            line_stacks[diagnostic.lnum] = {}
          end

          local stack = line_stacks[diagnostic.lnum]
          local real_col = column_to_cell(bufnr, diagnostic.lnum, diagnostic.col)

          if diagnostic.lnum ~= prev_lnum then
            table.insert(stack, { SPACE, string.rep(" ", real_col) })
          elseif diagnostic.col ~= prev_col then
            table.insert(stack, { SPACE, string.rep(" ", real_col - prev_col - 1) })
          else
            table.insert(stack, { OVERLAP, diagnostic.severity })
          end

          if diagnostic.message:find("^%s*$") then
            table.insert(stack, { BLANK, diagnostic })
          else
            table.insert(stack, { DIAGNOSTIC, diagnostic })
          end

          prev_lnum = diagnostic.lnum
          prev_col = diagnostic.col
        end
      end

      for lnum, lelements in pairs(line_stacks) do
        local virt_lines = {}

        for i = #lelements, 1, -1 do
          if lelements[i][1] == DIAGNOSTIC then
            local diagnostic = lelements[i][2]
            local left = {}
            local overlap = false
            local multi = 0

            for j = 1, i - 1 do
              local type = lelements[j][1]
              local data = lelements[j][2]
              if type == SPACE then
                if multi == 0 then
                  table.insert(left, { data, "" })
                else
                  table.insert(left, { string.rep("─", data:len()), highlight_groups[diagnostic.severity] })
                end
              elseif type == DIAGNOSTIC then
                if lelements[j + 1][1] ~= OVERLAP then
                  table.insert(left, { "│", highlight_groups[data.severity] })
                end
                overlap = false
              elseif type == BLANK then
                if multi == 0 then
                  table.insert(left, { "└", highlight_groups[data.severity] })
                else
                  table.insert(left, { "┴", highlight_groups[data.severity] })
                end
                multi = multi + 1
              elseif type == OVERLAP then
                overlap = true
              end
            end

            local center_symbol
            if overlap and multi > 0 then
              center_symbol = "┼"
            elseif overlap then
              center_symbol = "├"
            elseif multi > 0 then
              center_symbol = "┴"
            else
              center_symbol = "└"
            end

            local center = {
              { string.format("%s%s", center_symbol, "──── "), highlight_groups[diagnostic.severity] },
            }

            for msg_line in diagnostic.message:gmatch("([^\n]+)") do
              local vline = {}
              vim.list_extend(vline, left)
              vim.list_extend(vline, center)
              vim.list_extend(vline, { { msg_line, highlight_groups[diagnostic.severity] } })

              table.insert(virt_lines, vline)

              if overlap then
                center = { { "│", highlight_groups[diagnostic.severity] }, { "     ", "" } }
              else
                center = { { "      ", "" } }
              end
            end
          end
        end

        vim.api.nvim_buf_set_extmark(bufnr, virt_lines_ns, lnum, 0, {
          id = lnum + 1, -- Must be positive; +1 covers line=0.
          virt_lines = virt_lines,
          virt_lines_above = false,
        })
      end
    end,
    hide = function(namespace, bufnr)
      local ns = vim.diagnostic.get_namespace(namespace)
      if ns.user_data.virt_lines_ns then
        vim.api.nvim_buf_clear_namespace(bufnr, ns.user_data.virt_lines_ns, 0, -1)
      end
    end,
  }
end

M.toggle = function()
  local config = vim.diagnostic.config()
  if config.virtual_lines then
    -- Disable virtual lines and enable virtual text for errors only
    vim.diagnostic.config({
      virtual_lines = false,
      virtual_text = { severity = { min = vim.diagnostic.severity.ERROR } },
    })
  else
    -- Enable virtual lines (only for the current line) and disable virtual text
    vim.diagnostic.config({
      virtual_lines = { only_current_line = true },
      virtual_text = false,
    })
  end
end

return M
