df -h

git clone https://github.com/mwcproject/mwcbuilder-win32-helpers

echo "scp.expect version.txt %1"
expect scp.expect version.txt %1

cat mwcbuilder-win32-helpers/qt5-part2/* | bzip2 -dc | tar xvf -
cat mwcbuilder-win32-helpers/qt5/* | bzip2 -dc | tar xvf -
bzip2 -dc mwcbuilder-win32-helpers/libs32.tar.bz2 | tar xvf -

rm -rf mwcbuilder-win32-helpers

echo "scp.expect version.txt %1"
./scp.expect version.txt %1

choco install -y llvm

rem need putty for scp
choco install -y putty

rustup install stable-i686-pc-windows-msvc


rem rustup install 1.37.0-i686-pc-windows-msvc
rem rustup override set 1.37.0-i686-pc-windows-msvc
