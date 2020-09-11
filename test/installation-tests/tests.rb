# frozen_string_literal: true

def can_install_on?(os)
  image = "cbc-test-#{os}"
  install_ok = system("docker build . -q -f Dockerfile-#{os} -t #{image} >/dev/null")
  return false unless install_ok

  run_ok = system("docker run --rm #{image}")

  !!run_ok
end

os_list = %w[ubuntu debian archlinux]

passed = os_list.all? do |os|
  puts "Testing ruby-cbc on #{os}"
  can_install_on?(os)
end

if passed
  puts 'Sucessfully launched ruby-cbc on all os'
else
  puts 'Error!'
  exit 1
end
