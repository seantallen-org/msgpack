build/msgpack: build msgpack/*.pony
	ponyc msgpack -o build

build:
	mkdir build

test: build/msgpack
	build/msgpack

clean:
	rm -rf build

.PHONY: clean test
