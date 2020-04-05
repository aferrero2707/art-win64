#! /bin/bash

rm -rf RawTherapee
ln -s art RawTherapee || exit 1
rm -rf RawTherapee/ci
cp -a win64 RawTherapee/ci || exit 1
cd RawTherapee
git clone https://github.com/SpiNNakerManchester/SupportScripts.git support
python support/travis_blocking_stdout.py
travis_wait 120 sleep infinity & sudo docker pull photoflow/docker-buildenv-mingw-manjaro-wine || exit 1
sudo docker run -it -e "TRAVIS_BUILD_DIR=/sources" -e "TRAVIS_BRANCH=${RT_BRANCH}" -e "TRAVIS_COMMIT=xxx" -v $(pwd):/sources photoflow/docker-buildenv-mingw-manjaro-wine bash -x -c /sources/ci/package-msys2.sh || exit 1

