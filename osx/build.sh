#! /bin/bash

MPPREFIX=/opt/local
export PATH=$MPPREFIX/bin:$PATH
export LD_LIBRARY_PATH=$MPPREFIX/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$MPPREFIX/lib/pkgconfig:$PKG_CONFIG_PATH

WD=$(PWD)
if [ x"${TRAVIS_OS_NAME}" == "xosx" ]; then
brew remove --force --ignore-dependencies libtiff libpng jpeg openjpeg
(wget -q https://github.com/aferrero2707/macports-travis-cache/releases/download/continuous/macports-travis-cache-7.3-2.tgz && cd / && sudo tar xf $WD/macports-travis-cache-7.3-2.tgz) || exit 1
sudo port install exiv2 lcms2 lensfun fftw-3 gtk-osx-application-gtk3 || exit 1
fi


BTYPE=RelWithDebInfo
mkdir -p art/build || exit 1
(cd art/build && cmake -DCMAKE_BUILD_TYPE=$BTYPE -DCMAKE_OSX_DEPLOYMENT_TARGET=10.11 .. && make -j 2 install) || exit 1

BUNDLE_DIR="$(pwd)/art.app"
RES_DIR=${BUNDLE_DIR}/Resources

rm -rf art.app
mkdir -p art.app/Contents || exit 1
cp -a art/build/$BTYPE/MacOS ${BUNDLE_DIR}/Contents || exit 1
cp -a art/build/Resources art.app || exit 1
rm -f ${BUNDLE_DIR}/Contents/MacOS/ART.bin
mv ${BUNDLE_DIR}/Contents/MacOS/ART ${BUNDLE_DIR}/Contents/MacOS/ART.bin || exit 1
cp -a osx/launcher.sh ${BUNDLE_DIR}/Contents/MacOS/ART || exit 1

#exit


# Build the macdylibbundler executable
(mkdir -p tools && cd tools && rm -rf macdylibbundler && git clone https://github.com/aferrero2707/macdylibbundler.git && cd macdylibbundler && make) || exit 1


# Add libraries to the bundle and fix the rpath
echo "Fixing dependencies of \"${BUNDLE_DIR}/Contents/MacOS/ART.bin\""
tools/macdylibbundler/dylibbundler -od -of -b -x ${BUNDLE_DIR}/Contents/MacOS/ART.bin -d ${RES_DIR}/lib -p @executable_path/../../Resources/lib || exit 1 #> dylibbundler.log || exit 1
tools/macdylibbundler/dylibbundler -x ${BUNDLE_DIR}/Contents/MacOS/ART-cli -d ${RES_DIR}/lib -p @executable_path/../../Resources/lib || exit 1#> dylibbundler.log

#exit

# Bundle GdkPixbuf loaders and cache
gdk_pixbuf_src_moduledir=$(pkg-config --variable=gdk_pixbuf_moduledir gdk-pixbuf-2.0)
if [ -z "$gdk_pixbuf_src_moduledir" ]; then exit 1; fi
gdk_pixbuf_dst_moduledir=${RES_DIR}/lib/gdk-pixbuf-2.0/loaders
mkdir -p $gdk_pixbuf_dst_moduledir || exit 1
echo "Copying \"$gdk_pixbuf_src_moduledir\"/* to \"$gdk_pixbuf_dst_moduledir\""
cp -L "$gdk_pixbuf_src_moduledir"/* "$gdk_pixbuf_dst_moduledir" || exit 1

gdk_pixbuf_src_cache_file=$(pkg-config --variable=gdk_pixbuf_cache_file gdk-pixbuf-2.0)
if [ -z "$gdk_pixbuf_src_cache_file" ]; then exit 1; fi
gdk_pixbuf_dst_cache_file=${RES_DIR}/lib/gdk-pixbuf-2.0/loaders.cache
mkdir -p $(dirname "$gdk_pixbuf_dst_cache_file") || exit 1
echo "Copying \"$gdk_pixbuf_src_cache_file\" to \"$gdk_pixbuf_dst_cache_file\""
cp -L "$gdk_pixbuf_src_cache_file" "$gdk_pixbuf_dst_cache_file" || exit 1
sed -i -e "s|$gdk_pixbuf_src_moduledir|@executable_path/../../Resources/lib/gdk-pixbuf-2.0/loaders|g" "$gdk_pixbuf_dst_cache_file"

# Fix rpath of GdkPixbuf loaders
for l in "$gdk_pixbuf_dst_moduledir"/*.so; do
  echo "Fixing dependencies of \"$l\""
  chmod u+w "$l"
  tools/macdylibbundler/dylibbundler -of -b -x "$l" -d ${RES_DIR}/lib -p @executable_path/../../Resources/lib > /dev/null  || exit 1
done

# Copy Glib schemas into the bundle
mkdir -p ${RES_DIR}/share/glib-2.0 || exit 1
cp -a $MPPREFIX/share/glib-2.0/schemas ${RES_DIR}/share/glib-2.0 || exit 1

# Update LensFun database
lensfun-update-data
echo "Contents of lensfun database:"
ls $HOME/.local/share/lensfun/updates/version_1
mkdir -p ${RES_DIR}/share/lensfun/version_1 || exit 1
cp -a $HOME/.local/share/lensfun/updates/version_1/* ${RES_DIR}/share/lensfun/version_1 || exit 1
echo "Contents of \"${RES_DIR}/share/lensfun/version_1\":"
ls ${RES_DIR}/share/lensfun/version_1

export GIT_DESCRIBE="$(cd art && git describe --tags --always)"
echo "TRAVIS_BRANCH: ${TRAVIS_BRANCH}  GIT_DESCRIBE: ${GIT_DESCRIBE}"
curr_date="$(date '+%Y%m%d')"
if [[ $TRAVIS_BRANCH = releases ]]; then
    bundle_version="${GIT_DESCRIBE}"
else
    bundle_version="${TRAVIS_BRANCH}_${GIT_DESCRIBE}_${curr_date}"
fi

zip -q -r ART_${bundle_version}_macos.zip "art.app" || exit 1
pwd
ls -lhrt
