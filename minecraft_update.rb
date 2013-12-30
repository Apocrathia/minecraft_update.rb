#! /usr/bin/env ruby

# Minecraft & CraftBukkit Update Script
# 
# The following script will update both Minecraft server
# to the latest release, and CraftBukkit to the latest
# development snapshot (CraftBukkit tends to lag behind).
# 
# It is assumed that the minecraft server has aleady been halted
# DO NOT RUN THIS SCRIPT WITH THE MINECRAFT SERVER RUNNING
#
# Usage: ./update_minecraft.rb
#
# To-Do:
# => replace tar calls with zlib calls
# => if server doesn't exist, install

# User-configurable options

# CraftBukkit Release Channel
# Please change this value to either 'stable' or 'dev' (anything else will fail)
CB_RELEASE = 'dev'

# Minecraft server path
#PATH = '/home/minecraft/McMyAdmin/Minecraft'

# Testing Path
PATH = '/Users/ianyoung/Desktop/Minecraft'

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

# Set up logging
$LOGFILE = 'update.log'

def logger(text)
  # Open the log file in append mode
  log = File.open $LOGFILE, "a"

  # output to console
  puts text.to_s
  
  # output to logfile
  log << text.to_s 
  log << "\n"
end

# update minecraft
def update_minecraft
  puts "Starting Minecraft Update"
  
  # check if there is a new version of the minecraft_server.jar
  # file is downloaded to temp file for multiple uses without redownloading
  mc_temp = Tempfile.new('mc_temp')
  mc_temp.write(open(MC_SERVER, "rb").read)
  mc_temp.rewind
  
  # pull md5 of remote file
  mc_new_hash = Digest::MD5.hexdigest(File.read(mc_temp))
  logger("New Minecraft MD5: #{mc_new_hash}")
  # pull md5 of local file
  mc_current_hash = Digest::MD5.hexdigest(File.read('minecraft_server.jar'))
  logger("Current Minecraft MD5: #{mc_current_hash}")

  # compare hashes
  # if match no update needed
  if mc_current_hash == mc_new_hash
    logger("Already up-to-date.")
  
  # if not a match, update needed
  elsif mc_current_hash != mc_new_hash
    logger("A newer version is available")

    mc_archive = "minecraft_server.#{$timestamp}.tar.gz"
    # compress minecraft & craftbukkit
    `tar czf #{mc_archive} minecraft_server.jar`
  
    # move to previous_versions folder
    File.rename(mc_archive, "previous_versions/#{mc_archive}")
  
    # move the temp file into minecraft_server.jar
    File.rename(mc_temp, 'minecraft_server.jar')
  
    
    logger("Minecraft Updated")
  else
    # Something got fucked up
    logger("Something went wrong trying to update CraftBukkit.")
  end
  
  # Clean up the tempfile
  mc_temp.close
end

# update craftbukkit
def update_craftbukkit
  logger("Staring CraftBukkit Update")
  
  # Determine CraftBukkit release stream
  if CB_RELEASE == 'dev'
    logger("Using development release stream.")
    cb_server = CB_DEV
  elsif CB_RELEASE == 'stable'
    logger("Using stable release stream")
    cb_server = CB_STABLE
  end

  # check if there is a new version of the craftbukkit.jar
  # file is downloaded to temp file for multiple uses without redownloading
  cb_temp = Tempfile.new('cb_temp')
  cb_temp.write(open(cb_server, "rb").read)
  cb_temp.rewind

  # pull md5 of remote file
  cb_new_hash = Digest::MD5.hexdigest(File.read(cb_temp))
  logger("New CraftBukkit MD5: #{cb_new_hash}")

  # pull md5 of local file
  cb_current_hash = Digest::MD5.hexdigest(File.read('craftbukkit.jar'))
  logger("Current CraftBukkit MD5: #{cb_current_hash}")

  # compare hashes
  # if match no update needed
  if cb_current_hash == cb_new_hash
    logger("Already up-to-date")
    
  # if not a match, update needed
  elsif cb_current_hash != cb_new_hash
    logger("A new version is available")
    
    cb_archive = "craftbukkit.#{$timestamp}.tar.gz"
    
    # compress minecraft & craftbukkit
    `tar czf #{cb_archive} craftbukkit.jar`
    
    File.rename(cb_archive, "previous_versions/#{cb_archive}")
  
    # move the temp file into craftbukkit.jar
    File.rename(cb_temp, 'craftbukkit.jar')
    
    logger("CraftBukkit Updated")
  else
    # you fucked up. check the CB_RELESE variable
    logger("Something went wrong trying to update CraftBukkit.")
  end
  
  # Clean up the temp file
  cb_temp.close
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
if !Dir.exists?('previous_versions')
  logger("previous_versions folder does not exist. Creating.")
  Dir.mkdir('previous_versions')
end

update_minecraft
update_craftbukkit

# that should be it.

