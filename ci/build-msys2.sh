#! /bin/bash

sudo pacman --noconfirm -Syu || exit 1
sudo pacman --noconfirm -S wget || exit 1
(sudo mkdir -p /work && sudo chmod a+w /work) || exit 1

cd /work || exit 1

(rm -f pacman-msys.conf && wget https://raw.githubusercontent.com/aferrero2707/docker-buildenv-mingw/master/pacman-msys.conf && sudo cp pacman-msys.conf /etc/pacman-msys.conf) || exit 1
(rm -f Toolchain-mingw-w64-x86_64.cmake && wget https://raw.githubusercontent.com/aferrero2707/docker-buildenv-mingw/master/Toolchain-mingw-w64-x86_64.cmake && sudo cp Toolchain-mingw-w64-x86_64.cmake /etc/Toolchain-mingw-w64-x86_64.cmake) || exit 1


sudo pacman --noconfirm --config /etc/pacman-msys.conf -Syu || exit 1

#for PKG in mingw-w64-x86_64-libjpeg-turbo-1.5.3-1-any.pkg.tar.xz mingw-w64-x86_64-lensfun-0.3.2-4-any.pkg.tar.xz mingw-w64-x86_64-gtk3-3.22.30-1-any.pkg.tar.xz mingw-w64-x86_64-gtkmm3-3.22.3-1-any.pkg.tar.xz; do
for PKG in mingw-w64-x86_64-libjpeg-turbo-1.5.3-1-any.pkg.tar.xz mingw-w64-x86_64-lensfun-0.3.2-4-any.pkg.tar.xz; do
	rm -f "$PKG"
	wget http://repo.msys2.org/mingw/x86_64/"$PKG" || exit 1
	sudo pacman --noconfirm --config /etc/pacman-msys.conf -U "$PKG" || exit 1
done

sudo pacman --noconfirm --config /etc/pacman-msys.conf -S mingw64/mingw-w64-x86_64-exiv2 \
mingw64/mingw-w64-x86_64-fftw mingw64/mingw-w64-x86_64-libtiff mingw64/mingw-w64-x86_64-lcms2 || exit 1
sudo pacman --noconfirm --config /etc/pacman-msys.conf -S \
mingw64/mingw-w64-x86_64-gtk3 mingw64/mingw-w64-x86_64-gtkmm3 || exit 1

sudo sed -i 's|prefix=/mingw64|prefix=/msys2/mingw64|g' /msys2/mingw64/lib/pkgconfig/exiv2.pc

(cd / && sudo rm -f mingw64 && sudo ln -s /msys2/mingw64 mingw64) || exit 1
export PKG_CONFIG_PATH=/msys2/mingw64/lib/pkgconfig:$PKG_CONFIG_PATH

mkdir -p /work/w64-build || exit 1
cd /work/w64-build || exit 1

#rm -rf libiptcdata-*
if [ ! -e libiptcdata-1.0.4 ]; then
curl -LO http://downloads.sourceforge.net/project/libiptcdata/libiptcdata/1.0.4/libiptcdata-1.0.4.tar.gz || exit 1
tar xzf libiptcdata-1.0.4.tar.gz || exit 1
cd libiptcdata-1.0.4 || exit 1
./configure --host=x86_64-w64-mingw32 --prefix=/msys2/mingw64 || exit 1
sed -i -e 's|iptc docs||g' Makefile || exit 1
(make && sudo make install) || exit 1
fi


echo "Compiling RawTherapee"
ls /sources
mkdir -p /work/w64-build/rt || exit 1
cd /work/w64-build/rt || exit 1
(cd /sources; sudo patch -N -p0 < ci/rtgui-options-headers.patch; sudo patch -N -p0 < ci/rtgui-pixbuf-env.patch; sudo patch -N -p0 < ci/rtgui-GTK_CSD-env.patch; sudo patch -N -p0 < ci/rtgui-placesbrowser-headers.patch; sudo patch -N -p0 < ci/rt-innosetup.patch)
#(x86_64-w64-mingw32-cmake \
(cmake \
 -DCMAKE_TOOLCHAIN_FILE=/etc/Toolchain-mingw-w64-x86_64.cmake \
 -DCMAKE_BUILD_TYPE=Release -DPROC_TARGET_NUMBER=1 \
 -DCACHE_NAME_SUFFIX="'5-dev'" \
 -DCMAKE_C_FLAGS="'-mwin32 -m64 -mthreads -msse2'" \
 -DCMAKE_C_FLAGS_RELEASE="'-DNDEBUG -O2'" \
 -DCMAKE_CXX_FLAGS="'-mwin32 -m64 -mthreads -msse2'" \
 -DCMAKE_CXX_FLAGS_RELEASE="'-Wno-aggressive-loop-optimizations -DNDEBUG -O3'" \
 -DCMAKE_EXE_LINKER_FLAGS="'-m64 -mthreads -static-libgcc'" \
 -DCMAKE_EXE_LINKER_FLAGS_RELEASE="'-s -O3'" \
 -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
 -DWIN32=TRUE \
 /sources && make -j 3 install) || exit 1


echo "Compiling RawTherapee (Debug version)"
ls /sources
mkdir -p /work/w64-build/rt-debug || exit 1
cd /work/w64-build/rt-debug || exit 1
#(cd /sources; sudo patch -N -p0 < ci/rtgui-options-headers.patch; sudo patch -N -p0 < ci/rtgui-pixbuf-env.patch; sudo patch -N -p0 < ci/rtgui-GTK_CSD-env.patch; sudo patch -N -p0 < ci/rtgui-placesbrowser-headers.patch; sudo patch -N -p0 < ci/rt-innosetup.patch)
#(x86_64-w64-mingw32-cmake \
(cmake \
 -DCMAKE_TOOLCHAIN_FILE=/etc/Toolchain-mingw-w64-x86_64.cmake \
 -DCMAKE_BUILD_TYPE=Debug -DPROC_TARGET_NUMBER=1 \
 -DCACHE_NAME_SUFFIX="'5-dev'" \
 -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
 -DWIN32=TRUE \
 /sources && make -j 3 install) || exit 1
 

echo ""
echo "########################################################################"
echo ""
echo "Install Hicolor and Adwaita icon themes"

if [ "x" = "y" ]; then
(cd /work/w64-build && rm -rf hicolor-icon-theme-0.* && \
wget http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz && \
tar xJf hicolor-icon-theme-0.17.tar.xz && cd hicolor-icon-theme-0.17 && \
./configure --host=x86_64-w64-mingw32 --prefix=/msys2/mingw64 && sudo make install && rm -rf hicolor-icon-theme-0.*) || exit 1
echo "icons after hicolor installation:"
ls /mingw64/share/icons
echo ""

(cd /work/w64-build && rm -rf adwaita-icon-theme-3.* && \
wget http://ftp.gnome.org/pub/gnome/sources/adwaita-icon-theme/3.26/adwaita-icon-theme-3.26.0.tar.xz && \
tar xJf adwaita-icon-theme-3.26.0.tar.xz && cd adwaita-icon-theme-3.26.0 && \
./configure --host=x86_64-w64-mingw32 --prefix=/msys2/mingw64 && sudo make install && rm -rf adwaita-icon-theme-3.24.0*) || exit 1
fi

sudo pacman --noconfirm -S gtk-update-icon-cache || exit 1
sudo gtk-update-icon-cache "/mingw64/share/icons/Adwaita"
echo "icons after adwaita installation:"
ls /mingw64/share/icons
echo ""

touch /work/build.done
