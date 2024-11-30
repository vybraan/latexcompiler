
local M = {}

local terminal_open = false
local terminal_win_id = nil

M.compile_latex = function(file_path)
	if not M.is_latex_file(file_path) then
		print("Not a LaTeX file: " .. file_path)
		return
	end

	local compile_command = string.format("xelatex %s", file_path)

	M.run_command_async(compile_command)
end

M.is_latex_file = function(file_path)
	return vim.fn.match(file_path, "\\v\\.tex$") ~= -1
end

M.run_command_async = function(command)
	vim.fn.jobstart(command, {
		on_stdout = function(_, data)
			for _, line in ipairs(data or {}) do
				print(line) -- Print the output of the LaTeX compiler
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data or {}) do
				print("ERROR: " .. line)
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				print("LaTeX compiled successfully!")
			else
				print("Compilation failed with exit code " .. code)
			end
		end,
	})
end

-- Creates an autocommand to trigger LaTeX compilation on saving a .tex file
M.setup_autocommand = function()
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*.tex",
		callback = function()
			local file_path = vim.fn.expand("%")

			if not terminal_open then
				terminal_open = true
				M.open_terminal_and_compile(file_path)
			else
				-- Just run the LaTeX compiler in the existing terminal
				vim.api.nvim_set_current_win(terminal_win_id)
				M.compile_latex(file_path)
			end
		end,
	})
end

M.open_terminal_and_compile = function(file_path)
	vim.cmd("belowright split | terminal")

	vim.api.nvim_set_current_win(vim.api.nvim_get_current_win())

	M.compile_latex(file_path)

	terminal_win_id = vim.api.nvim_get_current_win()

	-- Reset terminal_open when the terminal window is closed
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = "*",
		callback = function()
			if
				vim.api.nvim_win_is_valid(terminal_win_id)
				and vim.api.nvim_win_get_buf(terminal_win_id) == vim.fn.bufname()
			then
				terminal_open = false
			end
		end,
	})
end

return M
