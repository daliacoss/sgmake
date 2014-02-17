-- david deckman coss (cosstropolis.com)
-- this script allows you to compile your sgdk games with custom metadata
-- (windows only - to port to linux, change os.execute calls)

require("inifile")
require("getopt_alt")

ROM_NAME_DEFAULT = "rom.bin"

-- -o rom_name
-- -i config_file
-- --no-ini			//set no-input and do not read or create an ini file
-- --no-input		//use no-ini instead of user input to determine whether to create ini

-- checklist:
-- +read config file and map it to t
-- +override values with command line arguments
-- +if config file doesn't exist, create new
-- +overwrite rom_head.c with our project
-- +run make with our custom rom name
-- +rename rom

config = {
	sys = {
		output_name = ROM_NAME_DEFAULT,
		sgdk_path = "%GDK_WIN%",
		sgdk_src_boot = "%GDK%/src/boot"
	},
	header = {
		console = "SEGA MEGA DRIVE",
		copyright = "(C)FLEMTEAM 2013",
		title_local = "SAMPLE PROGRAM",
		title_int = "SAMPLE PROGRAM",
		serial = "GM 00000000-00",
		checksum = 0x0000,
		IOSupport = "JD",
		rom_start = 0x00000000,
		rom_end = 0x00100000,
		ram_start = 0x00FF0000,
		ram_end = 0x00FFFFFF,
		sram_sig = "",
		sram_type = 0x0000,
		sram_start = 0x00200000,
		sram_end = 0x002001FF,
		modem_support = "",
		notes = "DEMONSTRATION PROGRAM",
		region = "JUE",
	}
}
string_widths = {
	console = 16,
	copyright = 16,
	title_local = 48,
	title_int = 48,
	serial = 14,
	IOSupport = 16,
	sram_sig = 2,
	notes = 40,
	region = 16
}

rom_head_start = [[#include "types.h"

const struct{
	char console[16];        /* Console Name (16) */
	char copyright[16];      /* Copyright Information (16) */
	char title_local[48];    /* Domestic Name (48) */
	char title_int[48];      /* Overseas Name (48) */
	char serial[14];         /* Serial Number (2, 12) */
	u16 checksum;            /* Checksum (2) */
	char IOSupport[16];      /* I/O Support (16) */
	u32 rom_start;           /* ROM Start Address (4) */
	u32 rom_end;             /* ROM End Address (4) */
	u32 ram_start;           /* Start of Backup RAM (4) */
	u32 ram_end;             /* End of Backup RAM (4) */
	char sram_sig[2];        /* "RA" for save ram (2) */
	u16 sram_type;           /* 0xF820 for save ram on odd bytes (2) */
	u32 sram_start;          /* SRAM start address - normally 0x200001 (4) */
	u32 sram_end;            /* SRAM end address - start + 2*sram_size (4) */
	char modem_support[12];  /* Modem Support (24) */
	char notes[40];          /* Memo (40) */
	char region[16];         /* Country Support (16) */
} rom_header = {
]]
rom_head_end = "};"

function setConfigFromIni(fname)
	local t = inifile.parse(fname)

	if t then
		-- for each section in ini
		for sec_key,sec_val in pairs(t) do
			-- for each setting in section
			for key,val in pairs(sec_val) do
				-- for all strings
				if type(val) == "string" then
					--pad/trim string to exact width
					local width = string_widths[key]
					if width then
						val = string.format("%-"..width.."s",val):sub(1,width)
					end
				end

				config[sec_key][key] = val
			end
		end
	else
		return nil
	end

	return true
end

function setIniFromConfig(fname)
	f = function(x,y) return string.lower(x) < string.lower(y) end
	inifile.save(fname, config, true, f)
end

--evaluate any environment variables
function evaluate(dir)
	ftemp = "tmp.txt"
	os.execute("echo " .. dir .. "> " .. ftemp)

	temp = io.open(ftemp, "r")
	abs = temp:read()
	temp:close()
	os.remove(ftemp)

	return abs
end

function main()

	opts = getopt(arg, "oi")
	--print(opts.e)
	local inifile = "sgmake.ini"
	if opts.i then
		inifile = opts.i
	end
	--set flags to false by default
	local no_ini = (opts["no-ini"] == true)
	local no_input = ((opts["no-input"] == true) or no_ini)

	-- if config file doesn't exist, make new one or use default table
	if not setConfigFromIni(inifile) then
		if not (no_input) then
			io.write("sgmake.ini not found. Create new config file? (y/n) > ")
			while create == nil do
				input = io.read()
				-- would use (es)? instead of e?s? but that's posix regex only
				if input:sub(1,3):match("^[yY]e?s?$") then create = true
				elseif input:sub(1,3):match("[nN]o?") then create = false
				else io.write("Invalid input - enter (y)es or (n)o > ") 
				end
			end
			no_ini = not create
		end
		--check no_ini regardless of no_input
		if not no_ini then setIniFromConfig(inifile) end
	end

	-- write rom_head.c
	local boot_dir = evaluate(config.sys.sgdk_src_boot)
	local rom_head_file = io.open(boot_dir .. "/rom_head.c", "w")
	rom_head_file:write(rom_head_start)

	--use a loop to write each line to avoid expensive string concatenation
	ordered_data = {
		"console",
		"copyright",
		"title_local",
		"title_int",
		"serial",
		"checksum",
		"IOSupport",
		"rom_start",
		"rom_end",
		"ram_start",
		"ram_end",
		"sram_sig",
		"sram_type",
		"sram_start",
		"sram_end",
		"modem_support",
		"notes",
		"region",
	}
	local fw = function(s)
		--only wrap in quotes if s is string
		if type(s)=="string" then q = "\"" else q = "" end
		return "\t"..q..s..q..",\n"
	end
	for k,v in ipairs(ordered_data) do
		rom_head_file:write(fw(config.header[v]))
	end
	
	rom_head_file:write(rom_head_end)
	rom_head_file:close()
	print("rom_head.c written")

	-- compile game
	local sgdk_path = config.sys.sgdk_path
	local command = "%s\\bin\\make -f %s\\makefile.gen"
	command = command:format(sgdk_path,sgdk_path)
	print("executing command: "..command) 
	local status = os.execute(command)

	-- rename rom
	if (status==0) then
		local output_name = ""
		if opts.o then
			output_name = opts.o
		else
			output_name = config.sys.output_name
		end
		if output_name ~= ROM_NAME_DEFAULT then
			print("renaming rom to "..output_name)
			os.execute("rename out\\rom.bin "..output_name)
		end
		print("done")
	else
		print("compile failed")
	end
end

main()
