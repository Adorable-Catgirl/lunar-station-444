-- FUCK YEAH, DIRECTORIES
task("dirs", function()
	os.execute("mkdir build")
	os.execute("mkdir build/server")
	os.execute("mkdir build/client")
end)