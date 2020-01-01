-- string.replace("{1} {2} {1} {3} {hi}", { [1] = "a", [2] = "b", [3] = "c", hi = "d" }a) --> "a b a c d"
-- Performance similar to string.format, in some cases better!

do
	local strgsub = string.gsub
	local pattern = "%b{}"

	local normalizeArgs = function(args)
		local out = { }
		for key, value in next, args do
			out["{" .. key .. "}"] = value
		end
		return out
	end

	string.replace = function(str, args, ignoreArgsNormalization)
		if not ignoreArgsNormalization then
			args = normalizeArgs(args)
		end

		return (strgsub(str, pattern, args, #str / 3))
	end
end
