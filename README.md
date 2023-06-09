OpenAI YouTube Story Generator + Google or AWS TTS voiceover + various side tools
==============================

This project demonstrates how to use the OpenAI GPT-3 API to generate story ideas and automatically create a video compilation. The application is split into several scripts that perform different tasks such as generating text, downloading video clips, and synthesizing speech.

**Script 1: Generating Text with OpenAI GPT-3** creepy/creepy.rb and edueveryday/*various .rb files*
This script demonstrates how to use the GPT-3 API to generate story ideas. The script sends a prompt to the GPT-3 API and receives a response, which is then printed to the console.

**Script 2: Downloading Video Clips** videoGenerator.rb
This script demonstrates how to use the Coverr API to search for and download video clips. The script downloads a set number of videos and saves them to disk. These video clips can be used later to create a video compilation.

**Script 3: Splitting Video Clips** stupidFootageCutter.rb
This script uses FFmpeg to split a video file into smaller segments. This can be useful for creating video compilations from a single video file or for extracting shorter clips from a longer video.

**Script 4: Merging Video Clips** stupidFootageCutter.rb
This script demonstrates how to use FFmpeg to merge video clips into a single video file. It selects a random set of video clips and combines them into a final video compilation.

**Script 5: Amazon TTS and Google Cloud Text-to-Speech Integration** GPT+TTS+SFX.rb
This script demonstrates how to use Amazon Polly and Google Cloud Text-to-Speech to convert a text story generated by the OpenAI YouTube Story Generator into an audio file. The integration with Amazon Polly and Google Cloud Text-to-Speech allows you to create engaging audio content using the synthesized speech. The script also includes a function to adjust the prosody (pitch, rate, and volume) of the synthesized speech to create a creepy effect, suitable for spooky stories.

**Requirements**
- Ruby
- FFmpeg
- Dotenv
- Open3
- RestClient
- JSON
- HTTParty
- Google Cloud Text-to-Speech library
- AWS SDK for Ruby

**Setup**
1. Install the required Ruby gems by running `gem install dotenv httparty rest-client json aws-sdk-polly google-cloud-text_to_speech`.
2. Sign up for an API key from the following services:
   - OpenAI GPT-3: https://beta.openai.com/signup/
   - Coverr: https://coverr.co/api
   - Amazon Polly: https://aws.amazon.com/polly/
   - Google Cloud Text-to-Speech: https://cloud.google.com/text-to-speech/
3. Create a `.env` file in the project root directory and add your API keys as environment variables:
**GPT_ACCESS_KEY=your_openai_gpt3_api_key
COVERR_API_KEY=your_coverr_api_key
AWS_ACCESS_KEY_ID=your_amazon_polly_access_key_id
AWS_SECRET_ACCESS_KEY=your_amazon_polly_secret_access_key
GOOGLE_APPLICATION_CREDENTIALS=path_to_your_google_cloud_credentials_json_file**
4. Run each script in the order listed in the Readme, starting with the text generation and proceeding through the video download, splitting, merging, and text-to-speech scripts.

**Usage**
1. Adjust the variables and parameters in each script to customize the story generation, video download, and text-to-speech options.
2. Run the scripts in the order listed in the Readme to generate a story, download video clips, create a video compilation, and synthesize speech for the story.
3. I also use FL Studio to change voiceovers to match thematics I want. Example .flp files could be found it this repository too
4. Then it all comes together in a single folder where you can use any video editor you like. 
5. Combine the audio file with the video compilation to create a final video with a background story.

Please note that you may need to modify the video and audio processing scripts to handle different video formats or adjust the audio processing
