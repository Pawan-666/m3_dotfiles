return {
	entry = function(_, args)
		local current = cx.active.current
		local new = (current.cursor + args[1]) % #current.files
		yy.manager_emit("arrow", { new - current.cursor })
	end,
}

