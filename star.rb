require 'json'
require 'open-uri'
require 'smarter_csv'
require 'travis'

def getProjectStar(repo_name)
  url="https://api.github.com/repos/#{repo_name}"
  k=0
  begin
    puts url
    op=open(url)
    res=JSON.parse(op.read)
    puts res['stargazers_count']
  rescue
    k+=1
    puts $!
    puts $!.to_s
    #sleep 30
    #retry if k<10
  end
end

def getTravisBuildNumber(repo_name)
  begin
    travis_repo=Travis::Repository.find(repo_name)
  rescue
    travis_repo=nil
  end
  if travis_repo && travis_repo.last_build
    return travis_repo.last_build.number.to_i
  else
    return 0
  end
end

def scanCSV(csv_file_path)
  SmarterCSV.process(csv_file_path, {:chunk_size => 10, :headers_in_file => false, :user_provided_headers => [:url, :repo_name]}) do |chunk|
    chunk.each do |row|
      #getProjectStar(row[:repo_name])
      buildNumber=getTravisBuildNumber(row[:repo_name])
      File.open("testWithTravis.csv",'a+') do |file|
        CSV(file,col_sep:',') do |csv|
          puts "#{row[:repo_name]},#{buildNumber}"
          csv<<[row[:repo_name],buildNumber]
        end
      end
    end
  end
end

scanCSV('test.csv')