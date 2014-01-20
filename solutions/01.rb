class Integer
  def prime?
    self > 1 && 2.upto(Math.sqrt(self)).all? { |n| remainder(n).nonzero? }
  end

  def prime_factors
    prime_factors = 2.upto(abs-1).select { |n| remainder(n).zero? && n.prime? }
    prime_factors.map { |prime|
      multiple_prime_factors([], self, prime)
    }.flatten
  end

  def harmonic
    1.upto(self).map { |i|
      1r / i
    }.inject :+
  end

  def digits
    self.to_s.split('').map &:to_i
  end

  private
  def multiple_prime_factors multiple_factors, n, prime
    if n.remainder(prime).zero?
      multiple_prime_factors(multiple_factors << prime, n/prime, prime)
    else
      multiple_factors
    end
  end
end

class Array
  def frequencies
    inject({}) do |frequencies, elem|
      frequencies[elem] ||= count(elem)
      frequencies
    end
  end

  def average
    inject(:+) / count.to_f
  end

  def drop_every(n)
    each_slice(n).map { |slice| slice[0,n-1] }.inject(:+)
  end

  def combine_with(other)
    zip(other).compact.flatten
  end
end

