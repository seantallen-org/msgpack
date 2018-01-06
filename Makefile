test: build msgpack/*.pony
	ponyc msgpack -o build --debug
	build/msgpack

test-ci: build msgpack/*.pony
	ponyc msgpack -o build --debug -Dci
	build/msgpack

clean:
	rm -rf build

build:
	mkdir build

.PHONY: clean test
