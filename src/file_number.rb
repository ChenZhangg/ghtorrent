@maven_error_message='COMPILATION ERROR'
@gradle_error_message='Compilation failed'

def mavenOrGradle(log_file_path)
  @error_type_number.clear

  puts "--Scanning file: #{log_file_path}"
  file=IO.read(log_file_path).gsub(/\r\n?/, "\n")
  if file.scan(/gradle/i).size >= 2
    print '>>>>>>>>>>>>>>>>>>>>>>>>>',' USE Gradle'
    puts
    gradleCutSegment(log_file_path)
  end

  if file.scan(/Reactor Summary|mvn/i).size >= 2
    print '>>>>>>>>>>>>>>>>>>>>>>>>>',' USE Maven'
    puts
    mavenCutSegment(log_file_path)
  end

  File.open('statistics.csv','a') do |output|
    CSV(output) do |csv|
      array=[]
      array<<log_file_path
      @error_type_number.each do |key,value|
        array<<"#{key}:#{value}"
      end
      csv<< array
    end
  end
end


def traverseDir(build_logs_path)
  (Dir.entries(build_logs_path)).delete_if {|repo_name| /.+@.+/!~repo_name}.each do |repo_name|
    repo_path=File.join(build_logs_path,repo_name)
    puts "Scanning projects: #{repo_path}"
    Dir.entries(repo_path).delete_if {|log_file_name| /.+@.+/!~log_file_name}.sort_by!{|e| e.sub(/\.log/,'').sub(/@/,'.').to_f}.each do |log_file_name|
      log_file_path=File.join(repo_path,log_file_name)
      mavenOrGradle(log_file_path)
    end
  end
end

@build_logs_path='../../bodyLog2/build_logs/'
traverseDir(@build_logs_path)