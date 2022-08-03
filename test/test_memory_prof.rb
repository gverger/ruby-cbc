$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ruby-cbc"

class TestMemoryProf
  def self.run
    while true
      1000.times do |i|
        run_once
      end

      GC.start
      puts `ps -o rss -p #{$$}`.lines.last
    end
  end

  def self.run_once
    m = Cbc::Model.new
    vars = m.int_var_array(100, 0..Cbc::INF);
    vars.each do |v|
      m.enforce(v <= 10)
    end

    m.maximize(Cbc.add_all(vars))

    p = m.to_problem

    p.solve
  end
end

module DontDelete
  def finalizer(cbc_model, int_arrays, double_arrays)
    proc do
    end
  end
end

module DeleteModelOnly
  def finalizer(cbc_model, int_arrays, double_arrays)
    proc do
      Cbc_wrapper.Cbc_deleteModel(cbc_model)
    end
  end
end

module DeleteAll
  def finalizer(cbc_model, int_arrays, double_arrays)
    proc do
      Cbc_wrapper.Cbc_deleteModel(cbc_model)
      int_arrays.each { |ar| Cbc_wrapper.delete_intArray(ar) }
      double_arrays.each { |ar| Cbc_wrapper.delete_doubleArray(ar) }
    end
  end
end

Cbc::Problem.singleton_class.prepend DontDelete
# Cbc::Problem.singleton_class.prepend DeleteModelOnly
# Cbc::Problem.singleton_class.prepend DeleteAll

TestMemoryProf.run
