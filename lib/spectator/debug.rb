module Kernel
  alias real_p p
  def p(*args)
    real_p(*args) if $spectator_debug
  end
  def p_print(*args)
    print(*args) if $spectator_debug
  end
end

