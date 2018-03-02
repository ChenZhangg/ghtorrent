require 'csv'
@array_a=[]
@array_b=[]

def readInArray(array,file)
  CSV.foreach(file) do |row|
    array<<row[0]
  end
end

def sortArray(array)
  array.sort_by! do |element|
    match_a=/[^\/]*/.match(element)
    match_b=/\/.*/.match(element)
    [match_a[0].downcase,match_b[0].downcase]
  end
end

def getBefore(element)
  match=/[^\/]*/.match(element)
  match[0].downcase
end

def getAfter(element)
  match=/\/.*/.match(element)
  match[0].downcase
end


def compareElement(e_a,e_b)
  a_before=getBefore(e_a)
  b_before=getBefore(e_b)
  result=a_before<=>b_before
  if result==0
    a_after=getAfter(e_a)
    b_after=getAfter(e_b)
    result=a_after<=>b_after
  end
  result
end

def  differenceSet(array_a,array_b)
  mem_array=[]
  point_a=0
  point_b=0
  while point_a<array_a.length && point_b<array_b.length
    if compareElement(array_a[point_a],array_b[point_b])<0
      point_a+=1
    elsif compareElement(array_a[point_a],array_b[point_b])>0
      point_b+=1
    else
      mem_array<<point_a
      point_a+=1
      point_b+=1
    end
  end

  mem_array.reverse_each do |index|
    array_a.delete_at(index)
    puts "Delete #{array_a[index]} at #{index}"
  end

  array_a
end

def storeDifferenceSet(array)
  File.open("java_difference_set.csv",'a+') do |file|
    CSV(file,col_sep:',') do |csv|
      array.each do |element|
        csv<<[element]
      end
    end
  end
end

CSV.foreach('java_above200.csv',:headers=>true) do |row|
  @array_a<<row[0]
end

CSV.foreach('Above1000WithTravisAbove1000.csv') do |row|
  @array_b<<row[0]
end

sortArray(@array_a)
sortArray(@array_b)
storeDifferenceSet(differenceSet(@array_a,@array_b))




