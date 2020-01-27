#! /bin/bash

export RT_BRANCH=master
#rm -rf RawTherapee
if [ ! -e RawTherapee ]; then
	git clone https://bitbucket.org/agriggio/art.git --branch $RT_BRANCH --single-branch RawTherapee
fi
rm -rf RawTherapee/ci
cp -a ci RawTherapee
cd RawTherapee
#docker run -it -v $(pwd):/sources -e "RT_BRANCH=$RT_BRANCH" photoflow/docker-centos7-gtk bash 
#/sources/ci/appimage-centos7.sh

#docker run -it -e "TRAVIS_BUILD_DIR=/sources" -e "TRAVIS_BRANCH=${RT_BRANCH}" -e "TRAVIS_COMMIT=${TRAVIS_COMMIT}" -v $(pwd):/sources photoflow/docker-buildenv-mingw bash #-c /sources/ci/package-w64.sh

docker run -it -e "TRAVIS_BUILD_DIR=/sources" -e "TRAVIS_BRANCH=${RT_BRANCH}" -e "TRAVIS_COMMIT=${TRAVIS_COMMIT}" -v $(pwd):/sources photoflow/docker-buildenv-mingw-manjaro-wine bash #-c /sources/ci/package-w64.sh
