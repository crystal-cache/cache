require "spec"
require "timecop"
require "../src/cache"

module Spec::Methods
  def freeze(&)
    local_time = Time.local
    Timecop.freeze(local_time)
    yield local_time
  ensure
    Timecop.return
  end
end
