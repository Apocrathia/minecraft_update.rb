#! /usr/bin/env ruby

# Minecraft & Bukkit Update Script
#
# The following script will update both Minecraft server
# to the latest release, and Bukkit to the latest
# selected release. The Script supports development and stable
# release streams of both CraftBukkit and Spigot.
#
# It is assumed that the minecraft server has aleady been halted
# DO NOT RUN THIS SCRIPT WITH THE MINECRAFT SERVER RUNNING
#
# Usage: ./update_minecraft.rb
#
# To-Do:
# => enable selection of release stream (Done)
# => replace tar calls with zlib calls
# => if server doesn't exist, install (Done)
# => create update method with url argument (Done)
# => add spigot url (Done)
# => customizable previous version folder (Done)
# => search for running minecraft process
# => maybe add download progress bar?

# User-configurable options

# bukkit release (craftbukkit-stable, craftbukkit-dev, spigot-stable, spigot-dev)
RELEASE = 'spigot-dev'

# Minecraft server path
PATH = '/home/minecraft/McMyAdmin/Minecraft'

# Testing Path
#PATH = '/Users/ianyoung/Desktop/Minecraft'

# previous version folder
$PREVIOUS = "previous_versions"

# PLEASE DON'T EDIT ANYTHING BELOW THIS LINE

require 'digest/md5'
require 'open-uri'
require 'tempfile'
#require 'zlib'

# Latest minecraft_server
MC_SERVER = 'https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar'

# Latest craftbukkit-dev
CB_DEV = 'http://dl.bukkit.org/downloads/craftbukkit/get/latest-dev/craftbukkit.jar'

# Latest Stable craftbukkit
CB_STABLE = 'http://dl.bukkit.org/latest-rb/craftbukkit.jar'

# Latest successful Spigot build
SPIGOT_DEV = 'http://ci.md-5.net/job/Spigot/lastSuccessfulBuild/artifact/Spigot-Server/target/spigot.jar'

# Last stable Spigot build
SPIGOT_STABLE = 'http://ci.md-5.net/job/Spigot/lastStableBuild/artifact/Spigot-Server/target/spigot.jar'

# Latest recommended Spigot build

# Set up logging
$LOGFILE = 'update.log'

def logger(text)
	# Open the log file in append mode
	log = File.open $LOGFILE, "a"

	# output to console
	puts text.to_s

	# output to logfile
	log << text.to_s + "\n"
end

# consolidated update method
# parameters: name, stream, url, filename - all used as strings
def update(name, stream, url, filename)
	logger("Starting #{name} Update")
	logger("Using #{stream} release stream.")

	# check if there is a new version of the release
	# file is downloaded to temp file for multiple uses without redownloading
	tempfile = Tempfile.new('tempfile')
	tempfile.write(open(url, "rb").read)
	tempfile.rewind

	# check to make sure file is even installed
	if !File.exists?(filename)
		# move the temp file
		File.rename(tempfile, filename)

		logger("#{name} #{stream} Installed")
	else
		# pull md5 of remote file
		new_hash = Digest::MD5.hexdigest(File.read(tempfile))
		logger("New #{name} MD5: #{new_hash}")

		# pull md5 of local file
		current_hash = Digest::MD5.hexdigest(File.read(filename))
		logger("Current #{name} MD5: #{current_hash}")

		# compare hashes
		# if match no update needed
		if current_hash == new_hash
			logger("Already up-to-date")

		# if not a match, update (probably) needed
		elsif current_hash != new_hash
			logger("A new version is available")

			archive = "#{filename}.#{$timestamp}.tar.gz"
			logger("Archiving previous version of #{name} to #{archive}")

			# compress original
			`tar czf #{archive} #{filename}`

			File.rename(archive, "#{$PREVIOUS}/#{archive}")

			# move the temp file into new location
			File.rename(tempfile, filename)

			logger("#{name} Updated")
		else
			# you fucked up.
			logger("Something went wrong trying to update #{name}.")
		end
	end
	# Clean up the temp file
	tempfile.close
end

# make sure the PATH exists
if !Dir.exists?(PATH)
	logger("Minecraft path not found. Aborting.")
	abort
end

# cd to directory
Dir.chdir PATH

logger("---------------------------------------------")

# timestamp for log
logger(Time.now)

# Start logging
logger("Starting update script.")

# format a timestamp for the files (global scope)
$timestamp = Time.now.year.to_s + Time.now.month.to_s + Time.now.day.to_s

# make sure the directory exists
if !Dir.exists?($PREVIOUS)
	logger("previous version folder does not exist. Creating.")
	Dir.mkdir($PREVIOUS)
end

# update minecraft
update('Minecraft', 'Stable', MC_SERVER, 'minecraft_server.jar')

# call to the update method
case RELEASE
when "craftbukkit-stable"
	update('CraftBukkit', 'Stable', CB_STABLE, 'craftbukkit.jar')
when "craftbukkit-dev"
	update('CraftBukkit', 'Development', CB_DEV, 'craftbukkit.jar')
when "spigot-stable"
	update('Spigot', 'Stable', SPIGOT_STABLE, 'spigot.jar')
when "spigot-dev"
	update('Spigot', 'Development', SPIGOT_DEV, 'spigot.jar')
else
	# this is why we can't have nice things
	logger("Release configuration incorrect. Please adjust settings")
end

# that should be it. Please let me know if you have any questions,
# comments, issues, or requests on the github page for this script:
# https://github.com/Apocrathia/minecraft_update.rb
