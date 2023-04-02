require 'rest-client'
require 'json'
require 'httparty'
require 'dotenv'
require 'ffmpeg'
require 'securerandom'

Dotenv.load('.env')

# Your Coverr API key
API_KEY = ENV['COVERR_API_KEY']

# Your search query
query = 'documentary'

# Maximum number of videos allowed in the folder
MAX_VIDEOS = 20

# Count the number of existing videos in the folder
existing_videos = Dir.glob('video*.mp4').length

# Download more videos if required to reach a total of 18 videos
if existing_videos < MAX_VIDEOS
  # Search for videos using the Coverr API
  response = RestClient.get "https://api.coverr.co/videos?urls=true&query=#{query}", { 'Authorization' => API_KEY }

  # Debugging output: print the response body
  puts "Response body: #{response.body}"

  # Parse the JSON response and extract the relevant video information
  data = JSON.parse(response.body)
  if data && data['hits']
    videos = []
    data['hits'].each do |hit|
      if hit['urls'] && hit['urls']['mp4']
        videos << { id: hit['id'], url: hit['urls']['mp4'], duration: hit['duration'].to_f }
      end
    end

    # Download more videos to fill the folder with 18 videos
    while existing_videos + videos.length < MAX_VIDEOS
      response = RestClient.get "https://api.coverr.co/videos?urls=true&query=#{query}", { 'Authorization' => API_KEY }
      data = JSON.parse(response.body)
      next unless data && data['hits']

      data['hits'].each do |hit|
        if hit['urls'] && hit['urls']['mp4']
          videos << { id: hit['id'], url: hit['urls']['mp4'], duration: hit['duration'].to_f }
        end
      end
    end

    # Limit the videos to a maximum of 18
    videos = videos[0..(MAX_VIDEOS - existing_videos - 1)]

    # Download the videos and save them to disk
    videos.each_with_index do |video, index|
      response = RestClient.get video[:url], { 'Authorization' => API_KEY }
      filename = "video#{existing_videos + index}.mp4"
      File.open(filename, 'wb') { |file| file.write(response.body) }
    end
  else
    puts 'No videos found.'
  end
end

# Collect the video filenames into an array
video_filenames = []
Dir.glob('video*.mp4').each { |filename| video_filenames << filename }
video_filenames = video_filenames[0..(MAX_VIDEOS - 1)] # Limit to the first 18 videos

# Shuffle the filenames to create a random order
video_filenames.shuffle!

# ... (previous code remains unchanged)

# Create a list of random 5-second clips for each video
clips = []
video_filenames.each do |filename|
  duration = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{filename}`.to_f
  start_time = SecureRandom.random_number(duration - 5)
  clips << "-ss #{start_time} -t 5 -i #{filename}"
end

# Generate trimmed clips from input videos
temp_clips = []

video_filenames.each_with_index do |filename, index|
  duration = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{filename}`.to_f
  start_time = SecureRandom.random_number(duration - 5)
  temp_clip_name = "temp_clip_#{index}.mp4"
  temp_clips << temp_clip_name

  command = "ffmpeg -ss #{start_time} -i #{filename} -t 5 -c copy -an #{temp_clip_name}"
  system(command)
end

# Create a file list containing the names of the temporary clips
file_list = 'temp_clips.txt'
File.open(file_list, 'w') do |f|
  temp_clips.each { |clip| f.puts("file '#{clip}'") }
end

# Concatenate the clips using the concat demuxer
command = "ffmpeg -f concat -safe 0 -i #{file_list} -c copy output1.mp4"
system(command)

# Cleanup temporary files
File.delete(file_list) if File.exist?(file_list)
temp_clips.each { |clip| File.delete(clip) if File.exist?(clip) }
