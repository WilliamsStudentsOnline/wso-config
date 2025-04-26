-- AppleScript is very scary. Try nothing you see below at home.
on run argv
	set arch to item 1 of argv
	set vmName to item 2 of argv
	set isoPath to item 3 of argv

	display dialog "Approve the security prompt that follows soon. You need to do this for this script to work correctly. " buttons {"Ok"} default button "Ok"
		
	-- AppleScript can't do relative paths so we invent it
	set realIsoPath to do shell script "realpath " & quoted form of isoPath
	
	-- AppleScript can't do error handling so this deals with it
	if (do shell script "test -f " & quoted form of realIsoPath & " && echo true || echo false") is not "true" then
		display dialog "The ISO file does not exist at the specified path: " & realIsoPath buttons {"Ok"} default button "Ok"
		return
	end if

	set iso to POSIX file realIsoPath
	
	tell application "UTM"
		set vmList to virtual machines
		
		-- Convert UTM's UTF-8 VM IDs into AppleScript compatible, UTF-16 lists
		set squeakyCleanList to {}
		repeat with aVM in vmList
			set end of squeakyCleanList to aVM
		end repeat
		
		-- If this exits with an error, we'll assume it already exists
		set vm to make new virtual machine with properties {backend:qemu, configuration:{name:vmName, architecture:arch, drives:{{removable:true, source:iso}, {guest size:32768}}}}
		-- This halts the script until the user clicks it with a mouse
		display dialog "New VM named " & vmName & " created successfully." buttons {"Ok"} default button "Ok"
		return "[make-utm.scpt] VM made!"
	end tell
end run
