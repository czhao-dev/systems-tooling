.PHONY: configure-debug build-debug test-debug \
        configure-release build-release test-release \
        asan ubsan tsan coverage clean

configure-debug:
	cmake --preset debug

build-debug:
	cmake --build --preset debug

test-debug:
	ctest --preset debug --output-on-failure

configure-release:
	cmake --preset release

build-release:
	cmake --build --preset release

test-release:
	ctest --preset release --output-on-failure

asan:
	cmake --preset asan
	cmake --build --preset asan
	ctest --preset asan --output-on-failure

ubsan:
	cmake --preset ubsan
	cmake --build --preset ubsan
	ctest --preset ubsan --output-on-failure

tsan:
	cmake --preset tsan
	cmake --build --preset tsan
	ctest --preset tsan --output-on-failure

coverage:
	cmake --preset coverage
	cmake --build --preset coverage
	./scripts/coverage.sh build/coverage

clean:
	rm -rf build install
