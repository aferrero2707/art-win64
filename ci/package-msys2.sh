#!/bin/bash

set -xv

# transfer.sh
transfer() 
{ 
	if [ $# -eq 0 ]; then 
		echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; 		
		return 1; 
	fi
	tmpfile=$( mktemp -t transferXXX ); 
	if tty -s; then 
		basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); 
		curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; 
	else 
		curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; 
	fi; 
	cat $tmpfile; 
	rm -f $tmpfile; 
}

/usr/bin/x86_64-w64-mingw32-gcc -v

# unzip to here
export installdir=/mingw64

export RT_PREFIX=Release
export RT_PREFIX_DEBUG=Debug

if [ ! -e /work/build.done ]; then
	rm -f /work/w64-build/rt/${RT_PREFIX}/rawtherapee.exe
	$TRAVIS_BUILD_DIR/ci/build-msys2.sh || exit 1
fi
if [ ! -e /work/w64-build/rt/${RT_PREFIX}/ART.exe ]; then exit 1; fi
if [ ! -e /work/w64-build/rt-debug/${RT_PREFIX_DEBUG}/ART.exe ]; then exit 1; fi

#echo ""
#echo "Contents of /work/w64-build/rt/${RT_PREFIX}/WindowsInnoSetup.iss"
#cat "/work/w64-build/rt/${RT_PREFIX}/WindowsInnoSetup.iss"
#echo ""
bundle_package=ART
#bundle_version="w64-$(date +%Y%m%d)_$(date +%H%M)-git-${TRAVIS_BRANCH}"
RT_VERSION=$(cat  /work/w64-build/rt/rtdata/WindowsInnoSetup.iss | grep " MyAppVersion " | grep define | cut -d "\"" -f 2)
bundle_version="${TRAVIS_BRANCH}-win64-${RT_VERSION}"
#repackagedir=$TRAVIS_BUILD_DIR/$bundle_package-$bundle_version
repackagedir=/work/$bundle_package-$bundle_version
cat /work/w64-build/rt/rtdata/WindowsInnoSetup.iss | sed -e "s|/work/w64-build/rt/${RT_PREFIX}|$repackagedir|g" | sed -e "s|\"${RT_VERSION}\"|\"${bundle_version}\"|g" | sed -e "s|#define MyBuildBasePath \".\"|#define MyBuildBasePath \"${repackagedir}\"|g" | sed "s|WizardImageFile|; WizardImageFile|g" > /work/WindowsInnoSetup.iss
cat /work/WindowsInnoSetup.iss



# stuff is in here
basedir=`pwd`
 
# download zips to here
packagedir=packages

# jhbuild will download sources to here 
#checkoutdir=source

mingw_prefix=x86_64-w64-mingw32-

echo "Contents of \"$installdir/bin\":"
ls -l $installdir/bin
echo "================="; echo ""

echo "copying install area \"$installdir\""

rm -rf $repackagedir
mkdir -p $repackagedir
#cp -r $installdir/* $repackagedir || exit 1
cp -a $installdir/lib $repackagedir || exit 1
cp -a $installdir/share $repackagedir || exit 1
#cp -a $installdir/etc $repackagedir || exit 1
rm -rf $repackagedir/bin
rm -rf $repackagedir/wine
#mkdir $repackagedir/bin
#(cp -L $installdir/bin/* $repackagedir/bin) || exit 1
(cp -a /work/w64-build/rt/${RT_PREFIX}/* $repackagedir) || exit 1
(cp -a /work/w64-build/rt-debug/${RT_PREFIX_DEBUG}/ART.exe $repackagedir/ART-debug.exe) || exit 1
(cp -L $installdir/lib/*.dll $repackagedir/) #|| exit 1
(cp -L $installdir/bin/*.dll $repackagedir/) #|| exit 1
echo "================="; echo ""

echo "Contents of \"$repackagedir\":"
ls -l $repackagedir
echo "================="; echo ""
echo "Contents of \"$repackagedir/bin\":"
ls -l $repackagedir/bin
echo "================="; echo ""

echo "cleaning build \"$repackagedir\""

#if [ ! -e $repackagedir/bin ]; then echo "$repackagedir/bin not found."; exit; fi
#if [ ! -e $repackagedir/lib ]; then echo "$repackagedir/lib not found."; exit; fi

wget ftp://ftp.equation.com/gdb/64/gdb.exe -O $repackagedir/gdb.exe

cp -a /mingw64/bin/gspawn-win64-helper* "$repackagedir"

echo "Before cleaning $repackagedir/bin"
pwd
#read dummy

#( cd $repackagedir/bin ; echo "$repackagedir/bin before cleaning:"; ls $repackagedir/bin; mkdir poop ; mv *photoflow* pfbatch.exe gdb.exe phf_stack.exe gdk-pixbuf-query-loaders.exe update-mime-database.exe camconst.json gmic_def.gmic poop ; mv *.dll poop ; rm -f * ; mv poop/* . ; rmdir poop )

#( cd $repackagedir/bin ; rm -f libvipsCC-15.dll run-nip2.sh *-vc100-*.dll *-vc80-*.dll *-vc90-*.dll  )

#( cd $repackagedir/bin ; strip --strip-unneeded *.exe )

# for some reason we can't strip zlib1
#( cd $repackagedir/bin ; mkdir poop ; mv zlib1.dll poop ; strip --strip-unneeded *.dll ; mv poop/zlib1.dll . ; rmdir poop )


( cd $repackagedir/share && rm -rf aclocal applications doc glib-2.0 gtk-2.0 gtk-doc ImageMagick-* info jhbuild man mime pixmaps xml goffice locale)

( cd $repackagedir && rm -rf include )

# we need some lib stuff at runtime for goffice and the theme
( cd $repackagedir/lib && mkdir ../poop ; mv goffice gtk-2.0 gdk-pixbuf-2.0 ../poop ; rm -rf * ; mv ../poop/* . ; rmdir ../poop )

# we don't need a lot of it though
( cd $repackagedir/lib/gtk-2.0 && find . -name "*.la" -exec rm {} \; )
( cd $repackagedir/lib/gtk-2.0 && find . -name "*.a" -exec rm {} \; )
( cd $repackagedir/lib/gtk-2.0 && find . -name "*.h" -exec rm {} \; )

( cd $repackagedir && rm -rf make man manifest src bin share/gdb)
echo "================="; echo ""


# Remove unneeded libraries
for LIB in \
libatomic-1.dll \
libjson-glib-1.0-0.dll \
libcairo-script-interpreter-2.dll \
liblzo2-2.dll \
libcharset-1.dll \
libminizip-1.dll \
libfftw3-3.dll \
libmpdec-2.dll \
libfftw3l-3.dll \
libp11-kit-0.dll \
libfreeglut.dll \
libpcre16-0.dll \
libgailutil-3-0.dll \
libpcre32-0.dll \
libgettextlib-0-19-8-1.dll \
libpcrecpp-0.dll \
libgettextpo-0.dll \
libpcreposix-0.dll \
libgettextsrc-0-19-8-1.dll \
libpython3.7m.dll \
libglibmm_generate_extra_defs-2.4-1.dll \
libquadmath-0.dll \
libgmp-10.dll \
libreadline7.dll \
libgmpxx-4.dll \
libsqlite3-0.dll \
libgthread-2.0-0.dll \
libssl-1_1-x64.dll \
libgtkreftestprivate-0.dll \
libssp-0.dll \
libharfbuzz-gobject-0.dll \
libtasn1-6.dll \
libharfbuzz-icu-0.dll \
libtermcap-0.dll \
libharfbuzz-subset-0.dll \
libturbojpeg-0.dll \
libhistory7.dll \
tcl86.dll \
libjasper-4.dll \
tk86.dll; do

	rm -f "$repackagedir/$LIB"

done


# Remove unneeded folders
for DIR in \
gettext-0.19.8 \
gir-1.0 \
graphite2 \
installed-tests \
libthai \
p11-kit \
pki \
readline \
tabset \
terminfo \
thumbnailers \
vala; do

	rm -rf "$repackagedir/share/$DIR"

done



# Remove unneeded icons
ls "$repackagedir/share/icons"
rm -rf "$repackagedir/share/icons/adwaita-temp"
mkdir -p "$repackagedir/share/icons/adwaita-temp"
mv "$repackagedir/share/icons/Adwaita/index.theme" "$repackagedir/share/icons/adwaita-temp" || exit 1
mv "$repackagedir/share/icons/Adwaita/scalable" "$repackagedir/share/icons/adwaita-temp"

if [ "x" = "y" ]; then
mv "$repackagedir/share/icons/Adwaita/scalable/actions" "$repackagedir/share/icons/adwaita-temp/scalable"
mv "$repackagedir/share/icons/Adwaita/scalable/devices" "$repackagedir/share/icons/adwaita-temp/scalable"
mv "$repackagedir/share/icons/Adwaita/scalable/mimetypes" "$repackagedir/share/icons/adwaita-temp/scalable"
mv "$repackagedir/share/icons/Adwaita/scalable/places" "$repackagedir/share/icons/adwaita-temp/scalable"
mv "$repackagedir/share/icons/Adwaita/scalable/status" "$repackagedir/share/icons/adwaita-temp/scalable"
mkdir -p "$repackagedir/share/icons/adwaita-temp/cursors"
mv "$repackagedir/share/icons/Adwaita/cursors/plus.cur" "$repackagedir/share/icons/adwaita-temp/cursors"
mv "$repackagedir/share/icons/Adwaita/cursors/sb_h_double_arrow.cur" "$repackagedir/share/icons/adwaita-temp/cursors"
mv "$repackagedir/share/icons/Adwaita/cursors/sb_left_arrow.cur" "$repackagedir/share/icons/adwaita-temp/cursors"
mv "$repackagedir/share/icons/Adwaita/cursors/sb_right_arrow.cur" "$repackagedir/share/icons/adwaita-temp/cursors"
mv "$repackagedir/share/icons/Adwaita/cursors/sb_v_double_arrow.cur" "$repackagedir/share/icons/adwaita-temp/cursors"
fi

rm -rf "$repackagedir/share/icons/Adwaita"
mv "$repackagedir/share/icons/adwaita-temp" "$repackagedir/share/icons/Adwaita"
rm -rf "$repackagedir/share/icons/hicolor"
#exit


#rm -rf "$repackagedir/licenses"


# we need to copy the C++ runtime dlls in there
gccmingwlibdir=/usr/lib/gcc/x86_64-w64-mingw32
mingwlibdir=/usr/x86_64-w64-mingw32/lib
cp -L $gccmingwlibdir/*/*.dll $repackagedir/
cp -L $mingwlibdir/*.dll $repackagedir/

#rm -rf $repackagedir/share/mime
#cp -a /usr/share/mime $repackagedir/share/mime
#rm $repackagedir/share/mime/application/vnd.ms-*

#mkdir -p $repackagedir/share/glib-2.0/schemas
#cp -a $installdir/share/glib-2.0/schemas/gschemas.compiled $repackagedir/share/glib-2.0/schemas

(cd /tmp && rm -f lensfun*.pkg.tar.xz && wget https://archive.archlinux.org/packages/l/lensfun/lensfun-0.3.2-9-x86_64.pkg.tar.xz &&
sudo pacman --noconfirm -U lensfun-0.3.2-9-x86_64.pkg.tar.xz) || exit 1
#sudo pacman --noconfirm -S lensfun || exit 1
sudo lensfun-update-data
mkdir -p $repackagedir/share/lensfun
cp -a /var/lib/lensfun-updates/version_1/* $repackagedir/share/lensfun

if [ "x" = "y" ]; then
#(cd $repackagedir && \
#wget http://ftp.gnome.org/pub/gnome/sources/adwaita-icon-theme/3.26/adwaita-icon-theme-3.26.0.tar.xz && \
#tar xJf adwaita-icon-theme-3.26.0.tar.xz && cp -a adwaita-icon-theme-3.26.0/Adwaita $repackagedir/share/icons && \
#rm -rf adwaita-icon-theme-3.26.0*) || exit 1
echo "==================="
echo "Contents of /mingw64/share/icons:"
ls /mingw64/share/icons
echo "==================="
(cp -a /mingw64/share/icons $repackagedir/share) || exit 1
fi
echo "==================="
echo "Contents of $repackagedir/share/icons:"
ls $repackagedir/share/icons
echo "==================="
#exit


#if [ ! -e $HOME/.wine ]; then
#	(cd $HOME && tar xzvf /sources/ci/wine.tgz) || exit 1
#fi


(cd /tmp && rm -f wine-4.*.pkg.tar.xz && wget https://archive.archlinux.org/packages/w/wine/wine-4.17-1-x86_64.pkg.tar.xz && sudo pacman -U --noconfirm wine-4.*.pkg.tar.xz) || exit 1
#sudo pacman --noconfirm -S wine || exit 1
wine /mingw64/bin/gdk-pixbuf-query-loaders.exe | sed -e "s%Z:/mingw64/%%g" > $repackagedir/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
cat $repackagedir/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

# Cleanup
rm -rf $repackagedir/etc
rm -f $repackagedir/icu*.dll $repackagedir/libgdkmm-2.4*.dll $repackagedir/libgfortran-*.dll $repackagedir/libgtkmm-2.4*.dll $repackagedir/libvips-*.dll
#rm -rf "$repackagedir/share/icons/Adwaita"/scalable*
rm -rf "$repackagedir/lib/gtk-2.0"
for dir in GConf bash-completion devhelp fontconfig gettext icu "lensfun/version_1" locale man pkgconfig themes; do
  rm -rf "$repackagedir/share/$dir"
done

mkdir -p "$repackagedir/share/glib-2.0/schemas"
cp -a /mingw64/share/glib-2.0/schemas/* "$repackagedir/share/glib-2.0/schemas"
glib-compile-schemas "$repackagedir/share/glib-2.0/schemas"

mkdir -p "$repackagedir/share/gtk-3.0" || exit 1
echo '[Settings]' >> "$repackagedir/share/gtk-3.0/settings.ini"
echo 'gtk-button-images=1' >> "$repackagedir/share/gtk-3.0/settings.ini"

# Remove debugging symbols from AppImage binaries and libraries
#find "${repackagedir}" -type f -regex '.*\.dll' -print0 | xargs -0 --no-run-if-empty --verbose -n1 strip


#exit

#echo creating $bundle_package-$bundle_version.zip
#rm -f $bundle_package-$bundle_version.zip
#zip -r -qq $bundle_package-$bundle_version.zip $bundle_package-$bundle_version

sudo pacman --noconfirm -S zip unzip || exit 1

# install latest version of exiftool.exe
(cd /tmp && rm -f exiftool* && wget https://exiftool.org/exiftool-11.86.zip && unzip exiftool-11.86.zip && mv "exiftool(-k).exe" "exiftool.exe" && mkdir -p $repackagedir/bin && cp -a "exiftool.exe" $repackagedir/bin) || exit 1
echo "Contents of $repackagedir/bin"
ls $repackagedir/bin
echo "================"; echo ""

rm -f $TRAVIS_BUILD_DIR/${bundle_package}_${bundle_version}.zip
cd $repackagedir/../
echo "zip -q -r $TRAVIS_BUILD_DIR/${bundle_package}_${bundle_version}.zip $bundle_package-$bundle_version"
sudo zip -q -r $TRAVIS_BUILD_DIR/${bundle_package}_${bundle_version}.zip $bundle_package-$bundle_version
#transfer $TRAVIS_BUILD_DIR/$bundle_package-$bundle_version.zip

#echo "cat /work/WindowsInnoSetup.iss"
#cat /work/WindowsInnoSetup.iss

#exit 

cd /
#dpkg --add-architecture i386 && apt-get update -y && apt-get install -y wine32
wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Inno\ Setup\ 5/ISCC.exe - < /work/WindowsInnoSetup.iss
sudo cp "$repackagedir/.."/*_*.exe "$TRAVIS_BUILD_DIR"

exit

# have to make in a subdir to make sure makensis does not grab other stuff
echo building installer nsis/$photoflow_package-$photoflow_version-setup.exe
( cd nsis ; rm -rf $photoflow_package-$photoflow_version ; 
#unzip -qq -o ../$photoflow_package-$photoflow_version.zip ;
rm -rf $photoflow_package-$photoflow_version
mv ../$photoflow_package-$photoflow_version .
#makensis -DVERSION=$photoflow_version $photoflow_package.nsi > makensis.log 
)
cd nsis
rm -f $photoflow_package-$photoflow_version.zip
zip -r $photoflow_package-$photoflow_version.zip $photoflow_package-$photoflow_version
rm -rf $photoflow_package-$photoflow_version
rm -f $photoflow_package-$photoflow_version-setup.zip
#zip $photoflow_package-$photoflow_version-setup.zip $photoflow_package-$photoflow_version-setup.exe
