build/msgpack: build msgpack/*.pony
	ponyc msgpack -o build --debug

build:
	mkdir build

test: build/msgpack
	build/msgpack

clean:
	rm -rf build

.PHONY: clean test
