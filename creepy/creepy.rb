require 'httparty'
require 'json'
require 'dotenv'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/texttospeech_v1'
require 'fileutils'

Dotenv.load('../.env')

class OpenAIClient
  include HTTParty
  base_uri 'https://api.openai.com'

  MAX_PROMPT_LENGTH = 2048

  def initialize(api_key)
    @api_key = api_key
  end

  def generate_text(prompt, messages)
    messages << { "role": 'user', "content": "#{prompt}" }
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }

    body = {
      model: 'gpt-3.5-turbo',
      messages: messages
    }.to_json

    self.class.post('/v1/chat/completions', headers: headers, body: body)
  end

  def text_to_speech(ssml, output_file)
    authorize
    client = Google::Apis::TexttospeechV1::TexttospeechService.new
    client.authorization = @credentials

    input = Google::Apis::TexttospeechV1::SynthesisInput.new(ssml: ssml)
    voice = Google::Apis::TexttospeechV1::VoiceSelectionParams.new(language_code: 'en-US', name: 'en-US-Neural2-J')
    audio_config = Google::Apis::TexttospeechV1::AudioConfig.new(audio_encoding: 'LINEAR16',
                                                                 model: 'video',
                                                                 effectsProfileId: [
                                                                   'headphone-class-device'
                                                                 ],
                                                                 pitch: 0,
                                                                 speaking_rate: 0.8,
                                                                 volume_gain_db: 2.0)

    request = Google::Apis::TexttospeechV1::SynthesizeSpeechRequest.new(input: input, voice: voice,
                                                                        audio_config: audio_config)
    response = client.synthesize_text_speech(request)

    File.open(output_file, 'wb') do |file|
      file.write(response.audio_content)
    end
  end

  def authorize
    @credentials ||= begin
      token_store = Google::Auth::Stores::FileTokenStore.new(file: 'tokens.yaml')
      client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
      scope = ['https://www.googleapis.com/auth/cloud-platform']
      authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

      user_id = 'default'
      credentials = authorizer.get_credentials(user_id)

      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: 'urn:ietf:wg:oauth:2.0:oob')
        puts 'Open the following URL in your browser and authorize the application.'
        puts url
        code = gets.chomp
        credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code,
                                                                     base_url: 'urn:ietf:wg:oauth:2.0:oob')
      end

      credentials
    end
  end

  def random_file_from_directory(directory)
    files = Dir.entries(directory).select { |f| File.file?(File.join(directory, f)) }
    files.sample
  end
end

api_key = ENV['GPT_ACCESS_KEY']
client = OpenAIClient.new(api_key)
current_time = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
folder_name = current_time
output_path = ENV['BASE_PATH'] + "\\creepy\\ready\\#{folder_name}"
output_file = "#{ENV['BASE_PATH']}\\creepy\\voiceover.flac"
FileUtils.mkdir_p(output_path)
creepy_videos_dir = ENV['BASE_PATH'] + '\\creepy\\video'
stupid_footage_cutter_dir = ENV['BASE_PATH'] + '\\stupidFootageCutter'

messages = [{ "role": 'system', "content": 'You are a professional storyteller and social media expert.' }]

prompt = 'Tell me a horrifying real world story that will keep me up all night in under 60 seconds. Use name and dates. Dont use ban words so I can post it on a social mediia'
story = client.generate_text(prompt, messages)
messages << story['choices'][0]['message']
story = story['choices'][0]['message']['content']
ssml_story = "<speak>#{story}</speak>"
puts ssml_story
client.text_to_speech(ssml_story, output_file)
puts "Audio file created: #{output_file}"

prompt = 'Provide me with eye-catching name for this story for youtube (in uppercase)'
story_title = client.generate_text(prompt, messages)
messages << story_title['choices'][0]['message']

prompt = 'Provide me with viral hashtags for this story'
hashtags = client.generate_text(prompt, messages)
messages << hashtags['choices'][0]['message']

prompt = 'Provide me with tags with which my video could be found. Add comma in between'
tags = client.generate_text(prompt, messages)
messages << tags['choices'][0]['message']

output = "#{output_path}/output_#{current_time}.txt"
messages.each { |n| File.open(output, 'a') { |f| f.write("#{n['content']}\n") } }

random_creepy_video = client.random_file_from_directory(creepy_videos_dir)
random_stupid_footage = client.random_file_from_directory(stupid_footage_cutter_dir)

FileUtils.cp("#{creepy_videos_dir}\\#{random_creepy_video}", "#{output_path}\\#{random_creepy_video}")
FileUtils.cp("#{stupid_footage_cutter_dir}\\#{random_stupid_footage}", "#{output_path}\\#{random_stupid_footage}")
FileUtils.cp(ENV['BASE_PATH'] + '//creepy//creepy.flp', "#{output_path}\\creepy.flp")
FileUtils.cp(ENV['BASE_PATH'] + '//creepy//outro.mp3', "#{output_path}\\outro.mp3")
