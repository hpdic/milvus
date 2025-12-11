#!/usr/bin/env bash

function install_linux_deps() {
  if [[ -x "$(command -v apt)" ]]; then
    # 安装基础依赖（移除 clang-format-12 和 clang-tidy-12）
    sudo apt install -y wget curl ca-certificates gnupg2  \
      g++ gcc gfortran git make ccache libssl-dev zlib1g-dev zip unzip \
      clang-format clang-tidy lcov libtool m4 autoconf automake python3 python3-pip \
      pkg-config uuid-dev libaio-dev libopenblas-dev libgoogle-perftools-dev
    
    # 创建版本12的软链接
    sudo ln -sf /usr/bin/clang-format /usr/bin/clang-format-12
    sudo ln -sf /usr/bin/clang-tidy /usr/bin/clang-tidy-12
    
    # 使用 --break-system-packages 安装 conan
    pip3 install --break-system-packages conan==1.64.1
    
  elif [[ -x "$(command -v yum)" ]]; then
    sudo yum install -y epel-release centos-release-scl-rh
    sudo yum install -y wget curl which \
      git make automake python3-devel \
      devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-gcc-gfortran devtoolset-11-libatomic-devel \
      llvm-toolset-11.0-clang llvm-toolset-11.0-clang-tools-extra openblas-devel \
      libaio libuuid-devel zip unzip \
      ccache lcov libtool m4 autoconf automake
    pip3 install --break-system-packages conan==1.64.1
    echo "source scl_source enable devtoolset-11" | sudo tee -a /etc/profile.d/devtoolset-11.sh
    echo "source scl_source enable llvm-toolset-11.0" | sudo tee -a /etc/profile.d/llvm-toolset-11.sh
    echo "export CLANG_TOOLS_PATH=/opt/rh/llvm-toolset-11.0/root/usr/bin" | sudo tee -a /etc/profile.d/llvm-toolset-11.sh
    source "/etc/profile.d/llvm-toolset-11.sh"
  else
    echo "Error Install Dependencies ..."
    exit 1
  fi
  
  # install cmake
  cmake_version=$(echo "$(cmake --version | head -1)" | grep -o '[0-9][\.][0-9]*')
  if [ ! $cmake_version ] || [ `expr $cmake_version \>= 3.26` -eq 0 ]; then
    echo "cmake version $cmake_version is less than 3.26, wait to installing ..."
    wget -qO- "https://cmake.org/files/v3.26/cmake-3.26.5-linux-$(uname -m).tar.gz" | sudo tar --strip-components=1 -xz -C /usr/local
  else
    echo "cmake version is $cmake_version"
  fi
  
  # install rust
  if command -v cargo >/dev/null 2>&1; then
      echo "cargo exists"
      rustup install 1.89
      rustup default 1.89
  else
      bash -c "curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain=1.89 -y" || { echo 'rustup install failed'; exit 1;}
      source $HOME/.cargo/env
  fi
}

function install_mac_deps() {
  sudo xcode-select --install > /dev/null 2>&1
  brew install boost libomp ninja cmake llvm@15 ccache grep pkg-config zip unzip tbb
  export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
  brew update && brew upgrade && brew cleanup
  pip3 install conan==1.64.1
  if [[ $(arch) == 'arm64' ]]; then
    brew install openssl
    brew install librdkafka
  fi
  sudo ln -s "$(brew --prefix llvm@15)" "/usr/local/opt/llvm"
  
  # install rust
  if command -v cargo >/dev/null 2>&1; then
      echo "cargo exists"
      rustup install 1.89
      rustup default 1.89
  else
      bash -c "curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain=1.89 -y" || { echo 'rustup install failed'; exit 1;}
      source $HOME/.cargo/env
  fi
}

if ! command -v go &> /dev/null
then
    echo "go could not be found, please install it"
    exit
fi

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     install_linux_deps;;
    Darwin*)    install_mac_deps;;
    *)          echo "Unsupported OS:${unameOut}" ; exit 0;
esac
