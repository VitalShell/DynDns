#!/bin/sh
#
#    Copyright (C) 2014  Vitaly Druzhinin
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

DEBUG=0
LOCAL_LIB_VER="2.000012"

echo "MkMojo v0.1"
echo "Copyright (c) Vitaly Druzhinin aka VitalkaDrug, 2014. Email: VitalkaDrug@gmail.com"

CURL_BIN=`which curl`
if [ $? -ne 0 ];
then
    echo "Error: can;t find curl. Please, install required package."
    exit 1
fi

if [ $# -ne 1 ];
then
    echo ""
    echo "Usage: $0 path_to_new_mojo_directory"
    echo ""
    exit 1
fi

# Check mojo directory
if [ ! -d "$1" ];
then
    # Create mojo directory
    mkdir -p $1 >/dev/null 2>&1
fi
if [ ! -d "$1" ];
then
    echo "Error: invalid directory name '$1'? Can't create it."
    exit 1
fi

CUR_DIR=`pwd`
cd $1
MOJO_DIR=`pwd`

echo "Download local-lib-$LOCAL_LIB_VER..."
$CURL_BIN -s -O http://cpan.metacpan.org/authors/id/H/HA/HAARG/local-lib-$LOCAL_LIB_VER.tar.gz
tar zxf local-lib-$LOCAL_LIB_VER.tar.gz
cd local-lib-$LOCAL_LIB_VER

echo "Making local-lib-$LOCAL_LIB_VER..."
if [ "$DEBUG" = "1" ];
then
    perl Makefile.PL --bootstrap=$MOJO_DIR --no-manpages
else
    perl Makefile.PL --bootstrap=$MOJO_DIR --no-manpages >/dev/null 2>&1
fi

if [ "$DEBUG" = "1" ];
then
    make
else
    make >/dev/null 2>&1
fi

if [ "$DEBUG" = "1" ];
then
    make test
fi

if [ "$DEBUG" = "1" ];
then
    make install
else
    make install >/dev/null 2>&1
fi
cd ..
rm local-lib-$LOCAL_LIB_VER.tar.gz
rm -Rf local-lib-$LOCAL_LIB_VER


# Prepare environmnet
echo "Prepare environment..."
eval $(perl -I$MOJO_DIR/lib/perl5 -Mlocal::lib=$MOJO_DIR) 

echo "Install Mojolicious..."
if [ "$DEBUG" = "1" ];
then
    $CURL_BIN -s -L cpanmin.us | perl - Mojolicious
else
    $CURL_BIN -s -L cpanmin.us | perl - Mojolicious >/dev/null 2>&1
fi

echo "Prepare env.sh script..."
#cat <<END_OF_FILE_1 > mojo.sh
##!/bin/sh
#eval \$(perl -I$MOJO_DIR/lib/perl5 -Mlocal::lib=$MOJO_DIR)
#mojo \$@
## end of file
#END_OF_FILE_1
#chmod +x mojo.sh
#
#cat <<END_OF_FILE_2 > morbo.sh
##!/bin/sh
#eval \$(perl -I$MOJO_DIR/lib/perl5 -Mlocal::lib=$MOJO_DIR)
#morbo \$@
## end of file
#END_OF_FILE_2
#chmod +x morbo.sh

cat <<END_OF_FILE_3 > env.sh
#!/bin/sh
eval \$(perl -I$MOJO_DIR/lib/perl5 -Mlocal::lib=$MOJO_DIR)
\$@
# end of file
END_OF_FILE_3
chmod +x env.sh

cd $CUR_DIR

echo "All done."

# end of file