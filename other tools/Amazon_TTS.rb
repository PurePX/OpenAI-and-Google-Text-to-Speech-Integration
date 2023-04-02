require 'httparty'
require 'json'
require 'dotenv'
require 'aws-sdk-polly'
require 'google-cloud-text_to_speech'

Dotenv.load('.env')

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
      max_tokens: 6000,
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0
    }.to_json

    response = self.class.post('/v1/completions', headers: headers, body: body)

    return response.parsed_response['choices'][0]['text'].strip if response.success?

    raise StandardError, "API request failed: #{response.response.body}"
  end

  def text_to_speech(ssml, output_file)
    polly = Aws::Polly::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )

    response = polly.synthesize_speech({
                                         output_format: 'mp3',
                                         text_type: 'ssml', # Set input type to SSML
                                         text: ssml,
                                         voice_id: 'Justin'
                                       })

    raise StandardError, "Speech synthesis failed: #{response.message}" if response.audio_stream.nil?

    File.open(output_file, 'wb') do |file|
      file.write(response.audio_stream.read)
    end
  end

  require 'google/cloud/text_to_speech'

  def text_to_speech(ssml, output_file)
    client = Google::Cloud::TextToSpeech.text_to_speech

    input = { ssml: ssml }
    # Select the language, voice type, and gender
    voice = { language_code: 'en-US', name: 'en-US-Wavenet-A', ssml_gender: :MALE }
    audio_config = { audio_encoding: :MP3, speaking_rate: 0.8 }

    response = client.synthesize_speech(input: input, voice: voice, audio_config: audio_config)

    File.open(output_file, 'wb') do |file|
      file.write(response.audio_content)
    end
  end

  def convert_to_creepy_ssml(text, pitch: 'low', rate: '80%', volume: 'soft')
    # Adjust the prosody (pitch, rate, and volume) to create a creepy effect
    "<speak><prosody pitch='#{pitch}' rate='#{rate}' volume='#{volume}'>#{text}</prosody></speak>"
  end
end

api_key = ENV['GPT_ACCESS_KEY']
client = OpenAIClient.new(api_key)
theme = 'haunted house'
prompt = "I want you to act as a storyteller. You will come up with entertaining stories that are engaging, imaginative and captivating for the audience. It is should be spooky stories for grownups entartaining. Generally it should be around 2 minutes long for reading. Theme is #{theme}"
story = client.generate_text(prompt)
puts story

# Convert the text story to SSML with a creepy effect
ssml_story = client.convert_to_creepy_ssml(story, pitch: 'low', rate: '80%', volume: 'soft')

# Convert the SSML story to an audio file
output_file = 'story2.mp3'
client.text_to_speech(ssml_story, output_file)
puts "Audio file created: #{output_file}"
