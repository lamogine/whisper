TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'whisper'
require 'test/unit'
require 'tempfile'
require 'tmpdir'
require 'shellwords'

class TestWhisper < Test::Unit::TestCase
  def setup
    @params  = Whisper::Params.new
  end

  def test_language
    @params.language = "en"
    assert_equal @params.language, "en"
    @params.language = "auto"
    assert_equal @params.language, "auto"
  end

  def test_offset
    @params.offset = 10_000
    assert_equal @params.offset, 10_000
    @params.offset = 0
    assert_equal @params.offset, 0
  end

  def test_duration
    @params.duration = 60_000
    assert_equal @params.duration, 60_000
    @params.duration = 0
    assert_equal @params.duration, 0
  end

  def test_max_text_tokens
    @params.max_text_tokens = 300
    assert_equal @params.max_text_tokens, 300
    @params.max_text_tokens = 0
    assert_equal @params.max_text_tokens, 0
  end

  def test_translate
    @params.translate = true
    assert @params.translate
    @params.translate = false
    assert !@params.translate
  end

  def test_no_context
    @params.no_context = true
    assert @params.no_context
    @params.no_context = false
    assert !@params.no_context
  end

  def test_single_segment
    @params.single_segment = true
    assert @params.single_segment
    @params.single_segment = false
    assert !@params.single_segment
  end

  def test_print_special
    @params.print_special = true
    assert @params.print_special
    @params.print_special = false
    assert !@params.print_special
  end

  def test_print_progress
    @params.print_progress = true
    assert @params.print_progress
    @params.print_progress = false
    assert !@params.print_progress
  end

  def test_print_realtime
    @params.print_realtime = true
    assert @params.print_realtime
    @params.print_realtime = false
    assert !@params.print_realtime
  end

  def test_print_timestamps
    @params.print_timestamps = true
    assert @params.print_timestamps
    @params.print_timestamps = false
    assert !@params.print_timestamps
  end

  def test_suppress_blank
    @params.suppress_blank = true
    assert @params.suppress_blank
    @params.suppress_blank = false
    assert !@params.suppress_blank
  end

  def test_suppress_non_speech_tokens
    @params.suppress_non_speech_tokens = true
    assert @params.suppress_non_speech_tokens
    @params.suppress_non_speech_tokens = false
    assert !@params.suppress_non_speech_tokens
  end

  def test_token_timestamps
    @params.token_timestamps = true
    assert @params.token_timestamps
    @params.token_timestamps = false
    assert !@params.token_timestamps
  end

  def test_split_on_word
    @params.split_on_word = true
    assert @params.split_on_word
    @params.split_on_word = false
    assert !@params.split_on_word
  end

  def test_whisper
    @whisper = Whisper::Context.new(File.join(TOPDIR, '..', '..', 'models', 'ggml-base.en.bin'))
    params  = Whisper::Params.new
    params.print_timestamps = false

    jfk = File.join(TOPDIR, '..', '..', 'samples', 'jfk.wav')
    @whisper.transcribe(jfk, params) {|text|
      assert_match /ask not what your country can do for you, ask what you can do for your country/, text
    }
  end

  def test_new_segment_callback
    whisper = Whisper::Context.new(File.join(TOPDIR, '..', '..', 'models', 'ggml-base.en.bin'))

    @params.new_segment_callback = ->(context, state, n_new, user_data) {
      assert_kind_of Integer, n_new
      assert n_new > 0
      assert_same whisper, context

      n_segments = context.full_n_segments
      n_new.times do |i|
        i_segment = n_segments - 1 + i
        start_time = context.full_get_segment_t0(i_segment) * 10
        end_time = context.full_get_segment_t1(i_segment) * 10
        text = context.full_get_segment_text(i_segment)

        assert_kind_of Integer, start_time
        assert start_time >= 0
        assert_kind_of Integer, end_time
        assert end_time > 0
        assert_match /ask not what your country can do for you, ask what you can do for your country/, text if i_segment == 0
      end
    }

    jfk = File.join(TOPDIR, '..', '..', 'samples', 'jfk.wav')
    whisper.transcribe(jfk, @params)
  end

  def test_new_segment_callback_closure
    whisper = Whisper::Context.new(File.join(TOPDIR, '..', '..', 'models', 'ggml-base.en.bin'))

    search_word = "what"
    @params.new_segment_callback = ->(context, state, n_new, user_data) {
      n_segments = context.full_n_segments
      n_new.times do |i|
        i_segment = n_segments - 1 + i
        text = context.full_get_segment_text(i_segment)
        if text.include?(search_word)
          t0 = context.full_get_segment_t0(i_segment)
          t1 = context.full_get_segment_t1(i_segment)
          raise "search word '#{search_word}' found at between #{t0} and #{t1}"
        end
      end
    }

    jfk = File.join(TOPDIR, '..', '..', 'samples', 'jfk.wav')
    assert_raise RuntimeError do
      whisper.transcribe(jfk, @params)
    end
  end

  sub_test_case "After transcription" do
    class << self
      attr_reader :whisper

      def startup
        @whisper = Whisper::Context.new(File.join(TOPDIR, '..', '..', 'models', 'ggml-base.en.bin'))
        params = Whisper::Params.new
        params.print_timestamps = false
        jfk = File.join(TOPDIR, '..', '..', 'samples', 'jfk.wav')
        @whisper.transcribe(jfk, params)
      end
    end

    def whisper
      self.class.whisper
    end

    def test_full_n_segments
      assert_equal 1, whisper.full_n_segments
    end

    def test_full_lang_id
      assert_equal 0, whisper.full_lang_id
    end

    def test_full_get_segment_t0
      assert_equal 0, whisper.full_get_segment_t0(0)
      assert_raise IndexError do
        whisper.full_get_segment_t0(whisper.full_n_segments)
      end
      assert_raise IndexError do
        whisper.full_get_segment_t0(-1)
      end
    end

    def test_full_get_segment_t1
      t1 = whisper.full_get_segment_t1(0)
      assert_kind_of Integer, t1
      assert t1 > 0
      assert_raise IndexError do
        whisper.full_get_segment_t1(whisper.full_n_segments)
      end
    end

    def test_full_get_segment_speaker_turn_next
      assert_false whisper.full_get_segment_speaker_turn_next(0)
    end

    def test_full_get_segment_text
      assert_match /ask not what your country can do for you, ask what you can do for your country/, whisper.full_get_segment_text(0)
    end
  end

  def test_lang_max_id
    assert_kind_of Integer, Whisper.lang_max_id
  end

  def test_lang_id
    assert_equal 0, Whisper.lang_id("en")
    assert_raise ArgumentError do
      Whisper.lang_id("non existing language")
    end
  end

  def test_lang_str
    assert_equal "en", Whisper.lang_str(0)
    assert_raise IndexError do
      Whisper.lang_str(Whisper.lang_max_id + 1)
    end
  end

  def test_lang_str_full
    assert_equal "english", Whisper.lang_str_full(0)
    assert_raise IndexError do
      Whisper.lang_str_full(Whisper.lang_max_id + 1)
    end
  end

  def test_build
    Tempfile.create do |file|
      assert system("gem", "build", "whispercpp.gemspec", "--output", file.to_path.shellescape, exception: true)
      assert_path_exist file.to_path
    end
  end

  sub_test_case "Building binary on installation" do
    def setup
      system "rake", "build", exception: true
    end

    def test_install
      filename = `rake -Tbuild`.match(/(whispercpp-(?:.+)\.gem)/)[1]
      basename = "whisper.#{RbConfig::CONFIG["DLEXT"]}"
      Dir.mktmpdir do |dir|
        system "gem", "install", "--install-dir", dir.shellescape, "pkg/#{filename.shellescape}", exception: true
        assert_path_exist File.join(dir, "gems/whispercpp-1.3.0/lib", basename)
      end
    end
  end
end
