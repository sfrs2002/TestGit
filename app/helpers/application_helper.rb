module ApplicationHelper
  def d2c(d)
    case d
    when 0
      return "A"
    when 1
      return "B"
    when 2
      return "C"
    when 3
      return "D"
    else
      return "E"
    end
  end

  def render_content(str)
    arr = str.split('$')
    output = ""
    formula = str[0] == "$"
    arr.each do |e|
      if formula
        output += "<img src='http://latex.codecogs.com/gif.latex?#{e}'>"
      else
        output += e
      end
      formula = !formula
    end
  end
end
