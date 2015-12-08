require 'mkmf'
ROOT_DIR = File.dirname(File.absolute_path(__FILE__))

TARBALL_PATH = "/tmp/Cbc.tgz"
CBC_SRC_DIR = "/tmp/Cbc-2.9.7"
CBC_INSTALL = "#{ROOT_DIR}/install"
def install_cbc
  system "curl -o #{TARBALL_PATH} http://www.coin-or.org/download/source/Cbc/Cbc-2.9.7.tgz"
  Dir.chdir "/tmp" do
    system "tar -xzf #{TARBALL_PATH}"
    res = system "cd #{CBC_SRC_DIR} && ./configure --prefix=#{CBC_INSTALL} -C --with-pic --without-static && make && make install"
    if not res
      puts "Failed to build CBC, aborting"
      exit 1
    end
  end
end

## Rerun this if updated cbc version
#  swig_cmd = find_executable "swig"
#  current_path = File.expand_path('../', __FILE__)
#  %x{#{swig_cmd} -ruby -I#{current_path}/install/include/coin #{current_path}/cbc.i }

libs = %w(
  Cbc
  CbcSolver
  Cgl
  Clp
  ClpSolver
  CoinUtils
  Osi
  OsiCbc
  OsiClp
  OsiCommonTests
)

libs.each do |lib|
  find_library(lib,nil, "#{CBC_INSTALL}/lib")
end

headers = Dir["#{CBC_INSTALL}/include/coin/*.h"].map{ |h| h.split('/').last }
headers.each do |header|
  find_header(header, "#{CBC_INSTALL}/include/coin")
end

dir_config("ruby-cbc")
RPATHFLAG << " -Wl,-rpath,'$$ORIGIN/install/lib'"
create_makefile('cbc_wrapper')
