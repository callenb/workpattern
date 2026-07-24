require "#{File.dirname(__FILE__)}/test_helper.rb"

class TestWorkpatternRegistryConcurrency < WorkpatternTest # :nodoc:
  def setup
    Workpattern.clear
  end

  # Covers AE1: exactly one of many concurrent creators for the same name
  # succeeds; the rest raise NameError; the registry ends with one entry.
  #
  # Plain thread racing does not reliably interleave under MRI's GVL for a
  # short, allocation-light method body -- verified empirically: 200 threads
  # racing Workpattern.new against the pre-fix (unguarded) code produced zero
  # observed races. GC.stress = true forces a full GC (and therefore a
  # scheduler checkpoint) on every allocation, which reliably widens the
  # check-then-insert window enough to expose the race with only a couple of
  # threads. Confirmed against the pre-fix code: this exact test fails
  # (more than one thread wins) every time under GC.stress; against the
  # fixed code it passes every time. Always restore GC.stress in ensure --
  # it is a process-wide VM setting, not thread- or test-local.
  def test_concurrent_creation_with_same_name_exactly_one_succeeds
    name = 'contested'
    thread_count = 3
    results = Array.new(thread_count)

    begin
      GC.stress = true
      threads = Array.new(thread_count) do |i|
        Thread.new do
          results[i] =
            begin
              Workpattern.new(name)
              :created
            rescue NameError
              :name_error
            end
        end
      end
      threads.each(&:join)
    ensure
      GC.stress = false
    end

    assert_equal 1, results.count(:created), 'expected exactly one thread to win the race'
    assert_equal thread_count - 1, results.count(:name_error), 'expected every other thread to raise NameError'
    assert_instance_of Workpattern::Workpattern, Workpattern.get(name)
  end

  # Covers AE2: a mixed workload of creators (distinct names, no collisions),
  # readers (get/to_a on pre-seeded names), and deleters (idempotent, never
  # raise) interleaves without any unexpected exception escaping a thread,
  # and leaves the registry in an internally consistent state.
  #
  # Unlike the uniqueness race above, the concurrent-mutation hazard this
  # guards against (RuntimeError from mutating a Hash mid-iteration) proved
  # too narrow to force reliably even with GC.stress -- and forcing it across
  # this many threads made runtime highly variable (seconds to minutes).
  # This test runs at natural speed as a general interleaving smoke test;
  # the uniqueness test above is the one that deterministically regresses
  # without the Mutex.
  def test_concurrent_mixed_operations_do_not_corrupt_registry
    seed_names = Array.new(10) { |i| "seed-#{i}" }
    seed_names.each { |name| Workpattern.new(name) }

    errors = Queue.new
    threads = []

    30.times do |i|
      threads << Thread.new do
        Workpattern.new("created-#{i}")
      rescue StandardError => e
        errors << e
      end
    end

    10.times do
      threads << Thread.new do
        50.times do
          Workpattern.to_a
          Workpattern.get(seed_names.sample)
        end
      rescue StandardError => e
        errors << e
      end
    end

    30.times do |i|
      threads << Thread.new do
        Workpattern.delete("created-#{i}")
      rescue StandardError => e
        errors << e
      end
    end

    threads.each(&:join)

    leaked = Array.new(errors.size) { errors.pop }

    assert_empty leaked, "unexpected exception(s) escaped a thread: #{leaked.map(&:message)}"

    Workpattern.to_a.each do |name, wp|
      assert_instance_of Workpattern::Workpattern, wp, "registry entry #{name.inspect} is not a Workpattern"
      assert_equal name, wp.name, "registry key #{name.inspect} does not match stored workpattern's own name"
    end
  end
end
