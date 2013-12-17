class String
  def render_tex
    arr = self.split('$')
    output = ""
    formula = false
    arr.each do |e|
      if formula
        output += "<img src='http://latex.codecogs.com/gif.latex?#{e}'>"
      else
        output += e
      end
      formula = !formula
    end
    output.html_safe
  end
end
