require 'open3'

def run_ffmpeg_command(command)
  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    puts "Command succeeded: #{command}"
  else
    puts "Command failed: #{command}"
    puts "Error message: #{stderr}"
  end
end

input_video = "chain.mp4"
duration_command = "ffmpeg -i #{input_video} 2>&1 | findstr Duration"
duration_output = `#{duration_command}`
duration_match = duration_output.match(/Duration: (\d+):(\d+):(\d+)/)

hours, minutes, seconds = duration_match[1..3].map(&:to_i)
duration = hours * 3600 + minutes * 60 + seconds
segment_length = 90
num_segments = (duration.to_f / segment_length).ceil

num_segments.times do |i|
  start_time = i * segment_length
  output_filename = "chain#{i}.mp4"

  command = "ffmpeg -y -i #{input_video} -ss #{start_time} -t #{segment_length} -vcodec copy -acodec copy #{output_filename}"
  run_ffmpeg_command(command)

  puts "Created #{output_filename}"
end

puts "Done!"
