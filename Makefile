ifdef UNAME_S
UNAME_S := $(UNAME_S)
else
UNAME_S := $(shell uname -s)
endif

ifdef UNAME_P
UNAME_P := $(UNAME_P)
else
UNAME_P := $(shell uname -p)
endif

ifdef UNAME_M
UNAME_M := $(UNAME_M)
else
UNAME_M := $(shell uname -m)
endif


# Mac OS + Arm can report x86_64
# ref: https://github.com/ggerganov/whisper.cpp/issues/66#issuecomment-1282546789
ifeq ($(UNAME_S),Darwin)
	ifneq ($(UNAME_P),arm)
		SYSCTL_M := $(shell sysctl -n hw.optional.arm64)
		ifeq ($(SYSCTL_M),1)
			UNAME_P := arm
			UNAME_M := arm64
			warn := $(warning Your arch is announced as x86_64, but it seems to actually be ARM64. Not fixing that can lead to bad performance. For more info see: https://github.com/ggerganov/whisper.cpp/issues/66\#issuecomment-1282546789)
		endif
	endif
endif

#
# Compile flags
#

CFLAGS   = -I.              -O3 -std=c11  
CXXFLAGS = -I. -I./examples -O3 -std=c++11
LDFLAGS  =

# OS specific
# TODO: support Windows
ifeq ($(UNAME_S),Linux)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif
ifeq ($(UNAME_S),Darwin)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif
ifeq ($(UNAME_S),FreeBSD)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif

# Architecture specific
# TODO: probably these flags need to be tweaked on some architectures
#       feel free to update the Makefile for your architecture and send a pull request or issue
ifeq ($(UNAME_M),x86_64)
	CFLAGS += -mavx -mavx2 -mfma -mf16c
endif
ifeq ($(UNAME_M),amd64)
	CFLAGS += -mavx -mavx2 -mfma -mf16c
endif
ifneq ($(filter arm%,$(UNAME_M)),)
	# Mac M1 - include Accelerate framework
	ifeq ($(UNAME_S),Darwin)
		CFLAGS  += -DGGML_USE_ACCELERATE
		LDFLAGS += -framework Accelerate
	endif
endif
ifneq ($(filter aarch64%,$(UNAME_M)),)
endif
ifneq ($(filter armv6%,$(UNAME_M)),)
	# Raspberry Pi 1, 2, 3
	CFLAGS += -mfpu=neon-fp-armv8 -mfp16-format=ieee -mno-unaligned-access
endif
ifneq ($(filter armv7%,$(UNAME_M)),)
	# Raspberry Pi 4
	CFLAGS += -mfpu=neon-fp-armv8 -mfp16-format=ieee -mno-unaligned-access -funsafe-math-optimizations
endif
ifneq ($(filter armv8%,$(UNAME_M)),)
	# Raspberry Pi 4
	CFLAGS += -mfp16-format=ieee -mno-unaligned-access
endif

#
# Build library + main
#

main: examples/main/main.cpp ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/main/main.cpp whisper.o ggml.o -o main $(LDFLAGS)
	./main -h

ggml.o: ggml.c ggml.h
	$(CC)  $(CFLAGS) -c ggml.c -o ggml.o

whisper.o: whisper.cpp whisper.h
	$(CXX) $(CXXFLAGS) -c whisper.cpp -o whisper.o

libwhisper.a: ggml.o whisper.o
	$(AR) rcs libwhisper.a ggml.o whisper.o

clean:
	rm -f *.o main stream bench libwhisper.a

#
# Examples
#

CC_SDL=`sdl2-config --cflags --libs`

stream: examples/stream/stream.cpp ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/stream/stream.cpp ggml.o whisper.o -o stream $(CC_SDL) $(LDFLAGS)

bench: examples/bench/bench.cpp ggml.o whisper.o
	$(CXX) $(CXXFLAGS) examples/bench/bench.cpp ggml.o whisper.o -o bench $(LDFLAGS)

#
# Audio samples
#

# download a few audio samples into folder "./samples":
.PHONY: samples
samples:
	@echo "Downloading samples..."
	@mkdir -p samples
	@wget --quiet --show-progress -O samples/gb0.ogg https://upload.wikimedia.org/wikipedia/commons/2/22/George_W._Bush%27s_weekly_radio_address_%28November_1%2C_2008%29.oga
	@wget --quiet --show-progress -O samples/gb1.ogg https://upload.wikimedia.org/wikipedia/commons/1/1f/George_W_Bush_Columbia_FINAL.ogg
	@wget --quiet --show-progress -O samples/hp0.ogg https://upload.wikimedia.org/wikipedia/en/d/d4/En.henryfphillips.ogg
	@wget --quiet --show-progress -O samples/mm1.wav https://cdn.openai.com/whisper/draft-20220913a/micro-machines.wav
	@echo "Converting to 16-bit WAV ..."
	@ffmpeg -loglevel -0 -y -i samples/gb0.ogg -ar 16000 -ac 1 -c:a pcm_s16le samples/gb0.wav
	@ffmpeg -loglevel -0 -y -i samples/gb1.ogg -ar 16000 -ac 1 -c:a pcm_s16le samples/gb1.wav
	@ffmpeg -loglevel -0 -y -i samples/hp0.ogg -ar 16000 -ac 1 -c:a pcm_s16le samples/hp0.wav
	@ffmpeg -loglevel -0 -y -i samples/mm1.wav -ar 16000 -ac 1 -c:a pcm_s16le samples/mm0.wav
	@rm samples/mm1.wav

#
# Models
#

# if not already downloaded, the following targets download the specified model and
# runs it on all samples in the folder "./samples":

.PHONY: tiny.en
.PHONY: tiny
.PHONY: base.en
.PHONY: base
.PHONY: small.en
.PHONY: small
.PHONY: medium.en
.PHONY: medium
.PHONY: large

tiny.en tiny base.en base small.en small medium.en medium large: main
	bash ./models/download-ggml-model.sh $@
	@echo ""
	@echo "==============================================="
	@echo "Running $@ on all samples in ./samples ..."
	@echo "==============================================="
	@echo ""
	@for f in samples/*.wav; do \
		echo "----------------------------------------------" ; \
		echo "[+] Running base.en on $$f ... (run 'ffplay $$f' to listen)" ; \
	    echo "----------------------------------------------" ; \
		echo "" ; \
		./main -m models/ggml-$@.bin -f $$f ; \
		echo "" ; \
	done
