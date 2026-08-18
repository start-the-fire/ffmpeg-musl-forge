IMAGE ?= ffmpeg-musl-forge
PLATFORM ?= linux/arm64
BUILD_ID ?= dev
BUILD_DATE ?= $(shell date -u +%Y%m%d)
ALPINE_VERSION := $(shell python3 -c 'import json; print(json.load(open("versions.lock"))["alpine"]["version"])')
ALPINE_DIGEST := $(shell python3 -c 'import json; print(json.load(open("versions.lock"))["alpine"].get("digest", ""))')
ALPINE_IMAGE := alpine:$(ALPINE_VERSION)$(if $(ALPINE_DIGEST),@$(ALPINE_DIGEST),)
FFMPEG_VERSION := $(shell python3 -c 'import json; print(json.load(open("versions.lock"))["sources"]["ffmpeg"]["version"])')
BMX_VERSION := $(shell python3 -c 'import json; print(json.load(open("versions.lock"))["sources"]["bmxlib"]["version"])')
ARTIFACT_ARCH := $(patsubst linux/%,%,$(PLATFORM))
.PHONY: build export verify update-foundations update-lock update-lock-all validate-lock clean
build: validate-lock
	docker buildx build --load --platform $(PLATFORM) --build-arg BUILD_ID=$(BUILD_ID) --build-arg BUILD_DATE=$(BUILD_DATE) --build-arg ALPINE_IMAGE=$(ALPINE_IMAGE) -t $(IMAGE):$(BUILD_ID) .
export: validate-lock
	mkdir -p dist
	@tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	  docker buildx build --platform $(PLATFORM) --build-arg BUILD_ID=$(BUILD_ID) --build-arg BUILD_DATE=$(BUILD_DATE) --build-arg ALPINE_IMAGE=$(ALPINE_IMAGE) --target export --output type=local,dest="$$tmp" .; \
	  install -m 755 "$$tmp/ffmpeg" "dist/ffmpeg-$(FFMPEG_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  install -m 755 "$$tmp/ffprobe" "dist/ffprobe-$(FFMPEG_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  install -m 755 "$$tmp/raw2bmx" "dist/raw2bmx-$(BMX_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  install -m 755 "$$tmp/bmxtranswrap" "dist/bmxtranswrap-$(BMX_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  echo "Exported dist/ffmpeg-$(FFMPEG_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  echo "Exported dist/ffprobe-$(FFMPEG_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  echo "Exported dist/raw2bmx-$(BMX_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"; \
	  echo "Exported dist/bmxtranswrap-$(BMX_VERSION)-$(BUILD_DATE)-$(ARTIFACT_ARCH)"
verify: build
	docker run --rm --entrypoint /ffmpeg $(IMAGE):$(BUILD_ID) -version
	docker run --rm --entrypoint /ffprobe $(IMAGE):$(BUILD_ID) -version
	docker run --rm --entrypoint /raw2bmx $(IMAGE):$(BUILD_ID) --help
	docker run --rm --entrypoint /bmxtranswrap $(IMAGE):$(BUILD_ID) --help
update-foundations:
	./update-foundations.sh
update-lock:
	python3 update-lock.py
update-lock-all:
	./update-foundations.sh
	python3 update-lock.py
validate-lock:
	python3 -m json.tool versions.lock >/dev/null
	! rg -n '"sha256": "pending"|git clone|curl .*[|]' versions.lock Dockerfile build-scripts prepare-ffmpeg.sh
clean:
	rm -rf dist
