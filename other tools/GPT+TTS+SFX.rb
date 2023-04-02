require 'httparty'
require 'json'
require 'dotenv'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/texttospeech_v1'

Dotenv.load('../.env')

class OpenAIClient
  include HTTParty
  base_uri 'https://api.openai.com'

  MAX_PROMPT_LENGTH = 2048

  def initialize(api_key)
    @api_key = api_key
  end

  def generate_text(prompt)
    raise ArgumentError, "Prompt is too long (max #{MAX_PROMPT_LENGTH} characters)" if prompt.length > MAX_PROMPT_LENGTH
    raise ArgumentError, 'Prompt cannot be empty' if prompt.strip.empty?

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }

    body = {
      model: 'text-davinci-003',
      prompt: prompt,
      temperature: 1,
      max_tokens: 3900,
      top_p: 1,
      frequency_penalty: 0.5,
      presence_penalty: 0
    }.to_json

    response = self.class.post('/v1/completions', headers: headers, body: body)

    return response.parsed_response['choices'][0]['text'].strip if response.success?

    raise StandardError, "API request failed: #{response.response.body}"
  end

  FREESOUND_API_KEY = ENV['FREESOUND_API_KEY']

  def search_sound_effect(query)
    url = "https://freesound.org/apiv2/search/text/?query=#{URI.encode_www_form_component(query)}&token=#{FREESOUND_API_KEY}&fields=name,previews&page_size=1"

    response = HTTParty.get(url)
    data = JSON.parse(response.body)

    if data['results'].empty?
      puts "No sound effect found for '#{query}'"
      return nil
    end

    sound_effect = data['results'][0]
    download_sound_effect(sound_effect['previews']['preview-hq-mp3'], sound_effect['name'])
  end

  def download_sound_effect(url, name)
    audio_file = "#{name}.mp3"
    File.open(audio_file, 'wb') do |file|
      file.write(HTTParty.get(url).body)
    end
    audio_file
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

  def convert_to_creepy_ssml(text, pitch: -4, rate: 0.9, volume: -6)
    "<speak><prosody pitch='#{pitch}st' rate='#{rate}' volume='#{volume}dB'>#{text}</prosody></speak>"
  end

  private

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
end

api_key = ENV['GPT_ACCESS_KEY']
client = OpenAIClient.new(api_key)
theme = 'chainsaw'
prompt = 'Tell me horrifying real world story in under 60 seconds that will keep me up all night'
story_and_sfx = client.generate_text(prompt)
story, sound_effects_raw = story_and_sfx.split(/(?<=\.)\s*Sound effects:/)

if sound_effects_raw
  sound_effects = sound_effects_raw.split(',').map(&:strip)
else
  puts 'No sound effects found in the response.'
  sound_effects = []
end

puts story

downloaded_sound_effects = sound_effects.map do |sfx|
  client.search_sound_effect(sfx)
end.compact



ssml_story = "<speak>#{story}</speak>"

require 'fileutils'


# Create a directory with the current date and time
current_time = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
dir_name = "story_#{current_time}"
Dir.mkdir(dir_name)

# Save the story text in a file
story_file_name = "audio/story_text_#{current_time}.txt"
File.write(story_file_name, story)

# Create a directory for sound effects
sfx_dir = "#{dir_name}/sfx"
Dir.mkdir(sfx_dir)

# Download sound effects and save them in the sfx directory
downloaded_sound_effects = sound_effects.map do |sfx|
  audio_file = client.search_sound_effect(sfx)
  next unless audio_file

  new_file_path = "#{sfx_dir}/#{File.basename(audio_file)}"
  FileUtils.mv(audio_file, new_file_path)
  new_file_path
end.compact

# Convert the SSML story to an audio file
output_file = "audio/vocieover_#{current_time}.flac"
client.text_to_speech(ssml_story, output_file)
puts "Audio file created: #{output_file}"
