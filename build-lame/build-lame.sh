#!/bin/sh

CONFIGURE_FLAGS="--disable-shared --disable-frontend"

#ARCHS="arm64 x86_64 i386 armv7 armv7s"
ARCHS="armv7 arm64 i386 x86_64"
# directories
SOURCE="lame-3.99.5"
FAT="lame-ios"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CPU=
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
		    	HOST="--host=x86_64-apple-darwin"
		    else
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
			    HOST="--host=i386-apple-darwin"
		    fi
		else
		    PLATFORM="iPhoneOS"
		    if [ "$ARCH" = "arm64" ]
		    then
#		        CFLAGS="$CFLAGS -D__arm__ -D__ARM_ARCH_7EM__" # hack!
                CFLAGS="$CFLAGS -fembed-bitcode -miphoneos-version-min=7.0"
#                HOST="--host=aarch64-apple-darwin"
                HOST="--host=arm-apple-darwin"
            else
                CFLAGS="$CFLAGS -fembed-bitcode -miphoneos-version-min=7.0"
		        HOST="--host=arm-apple-darwin"
            fi
		    SIMULATOR=
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH"
		AS="$CWD/$SOURCE/extras/gas-preprocessor.pl $CC"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

        $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        $HOST \
        $CPU \
        CC="$CC" \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        --prefix="$THIN/$ARCH"
        make clean
        make -j8
        make install
        cd $CWD
	done
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    mkdir -p $FAT/lib
    set - $ARCHS
    CWD=`pwd`
    cd $THIN/$1/lib
    for LIB in *.a
    do
        cd $CWD
        lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
    done

    cd $CWD
    cp -rf $THIN/$1/include $FAT
fi
