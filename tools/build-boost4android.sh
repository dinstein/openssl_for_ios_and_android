#!/bin/bash
#
# Copyright 2016 leenjewel
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -u

source ./_shared.sh

# Setup architectures, library name and other vars + cleanup from previous runs
LIB_NAME="boost_1_63_0"
LIB_DEST_DIR=${TOOLS_ROOT}/libs
# [ -d ${LIB_DEST_DIR} ] && rm -rf ${LIB_DEST_DIR}
[ -f "${LIB_NAME}.tar.gz" ] || wget https://sourceforge.net/projects/boost/files/boost/1.63.0/boost_1_63_0.tar.gz
# Unarchive library, then configure and make for specified architectures
configure_make() {
  ARCH=$1; ABI=$2;
  rm -rf "${LIB_NAME}"
  tar xfz "${LIB_NAME}.tar.gz"
  pushd "${LIB_NAME}"

  configure $*

  PATH=$TOOLCHAIN_PATH:$PATH

  ./bootstrap.sh

  sed -i 's/using gcc ;/using gcc : arm : '"${TOOL}"'-g++ ;/' project-config.jam

  ./b2 link=static cxxflags="-fPIC" cflags="-fPIC"  \
      --prefix=${LIB_DEST_DIR}/${ABI} \
      --with-thread --with-filesystem --with-system \
      install

  OUTPUT_ROOT=${TOOLS_ROOT}/../output/android/boost/${ABI}
  [ -d ${OUTPUT_ROOT} ] || mkdir -p ${OUTPUT_ROOT}
  cp ${LIB_DEST_DIR}/${ABI}/lib/*.a ${OUTPUT_ROOT}

  popd

}

OUTPUT_INCLUDE=${TOOLS_ROOT}/../output/android/boost/include
[ -d ${OUTPUT_INCLUDE} ] || mkdir -p ${OUTPUT_INCLUDE}
cp -r ${LIB_DEST_DIR}/${ABI}/include/boost ${OUTPUT_INCLUDE}

for ((i=0; i < ${#ARCHS[@]}; i++))
do
  if [[ $# -eq 0 ]] || [[ "$1" == "${ARCHS[i]}" ]]; then
    # Do not build 64 bit arch if ANDROID_API is less than 21 which is
    # the minimum supported API level for 64 bit.
    [[ ${ANDROID_API} < 21 ]] && ( echo "${ABIS[i]}" | grep 64 > /dev/null ) && continue;
    configure_make "${ARCHS[i]}" "${ABIS[i]}"
  fi
done
