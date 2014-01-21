class Array

  def frequencies
    unique_elements = self.uniq
    unique_elements_counts = unique_elements.map { |e| self.count(e) }
    Hash[unique_elements.zip unique_elements_counts]
  end

  def sum
    inject(0.0) { |result, el| result + el }
  end

  def average
    sum / size
  end

  def drop_every(n)
    self.each_with_index.map { |item, i| item unless (i + 1) % n == 0}.compact
  end

  def combine_with(other)
    self.zip(other).flatten.compact
  end

end

class Integer

  def prime?
    return false if self <= 0

    (2..Math.sqrt(self)).each do |i|
      if self % i == 0 && i < self
        return false
      end
    end
    true
  end

  def prime_factors
    factors = []
    numerator = self.abs

    until numerator == 1
      factors.push (2..numerator).find { |i| i.prime? && numerator % i == 0 }
      numerator /= factors.last
    end
    factors
  end

  def harmonic
    Rational (1..self).inject { |sum, n| sum + Rational(1) / n }
  end

  def digits
    self.abs.to_s.chars.map { |char| char.to_i }
  end

end