class Array
	def serialize
		ser_ary = []
		self.each do |ele|
			case ele.class
			when Survey
				ser_ary << ele.serialize
			else
				ser_ary << ele
			end
		end
	end

	def mean
		return 0 if self.length == 0
		return self.sum.to_f / self.length
	end

	def estimate_answer_time
		answer_time = 0
		self.each do |ele|
			answer_time = answer_time + ele.estimate_answer_time if ele.class == Question
		end
		return answer_time
	end

	def before(e1, e2)
		return false if !self.include?(e1) || !self.include?(e2)
		return self.find_index(e1) < self.find_index(e2)
	end
end
