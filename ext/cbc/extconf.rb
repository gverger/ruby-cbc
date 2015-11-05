require 'mkmf'
ROOT_DIR = File.dirname(File.absolute_path(__FILE__))

TARBALL_PATH = "/tmp/Cbc.tgz"
CBC_SRC_DIR = "/tmp/Cbc-2.9.7"
CBC_INSTALL = "#{ROOT_DIR}/install"
def install_cbc
  system "curl -o #{TARBALL_PATH} http://www.coin-or.org/download/source/Cbc/Cbc-2.9.7.tgz"
  Dir.chdir "/tmp"
  system "tar -xzf #{TARBALL_PATH}"
  res = system "cd #{CBC_SRC_DIR} && ./configure --prefix=#{CBC_INSTALL} -C && make -j && make install"
  if not res
    puts "Failed to build CBC, aborting"
    exit 1
  end
end

unless RUBY_PLATFORM =~ /x86_64-linux/
  if not have_library("Cbc")
    install_cbc
  end
end

## Rerun this if updated cbc version
# swig_cmd = find_executable "swig"
# current_path = File.expand_path('../', __FILE__)
# %x{#{swig_cmd} -ruby -I#{current_path}/install/include/coin #{current_path}/cbc.i }

find_library("Cbc", nil, "#{CBC_INSTALL}/lib")
find_library("CbcSolver", nil, "#{CBC_INSTALL}/lib")
find_header("Cbc_C_Interface.h", "#{CBC_INSTALL}/include/coin")
find_header("Coin_C_defines.h", "#{CBC_INSTALL}/include/coin")

dir_config("cbc")
create_makefile('cbc_wrapper')
