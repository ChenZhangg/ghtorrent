require 'json'
require 'open-uri'
require 'smarter_csv'
require 'travis'
require 'mysql2'
#@account=['shunervw497',
#'louqianzyq220808@163.com',
#'340355960@qq.com'
#]

def getProjectStar(repo_name)
  k=0
  begin
    url="https://api.github.com/repos/#{repo_name}"
    f=open(url,:http_basic_authentication=>[@account, @password])
    stars=JSON.parse(f.read)['stargazers_count']
    puts "#{repo_name}     stars: #{stars}"
    puts "#{repo_name}     Account:#{@account}     Remain: #{f.meta["x-ratelimit-remaining"]}"
    #@count+=1 if f.meta["x-ratelimit-remaining"].to_i<10
  rescue => e
    puts "#{e.message}"
    k+=1
    stars=0
    sleep 5
    retry if k<3 && e.message.include?('403')
  end
  stars
end

def getTravisBuildNumber(repo_name)
  begin
    travis_repo=Travis::Repository.find(repo_name)
  rescue
    travis_repo=nil
  end
  if travis_repo && travis_repo.last_build
    builds=travis_repo.last_build.number.to_i
  else
    builds=0
  end
  puts "#{repo_name}     builds: #{builds}"
  builds
end

def mysql_initiallize
  @client = Mysql2::Client.new(:host => 'localhost', :username => 'root',:password=>'root')
  results = @client.query('CREATE DATABASE IF NOT EXISTS zc')
  results = @client.query('USE zc')
  results = @client.query('CREATE TABLE IF NOT EXISTS repository(
    reponame varchar(255),
    stars int,
    builds int
    );')
end

def scanCSV(csv_file_path)
  mysql_initiallize
  SmarterCSV.process(csv_file_path, {:chunk_size => 10, :headers_in_file => false, :user_provided_headers => [:url, :repo_name]}) do |chunk|
    chunk.each do |row|
      stars=getProjectStar(row[:repo_name])
      builds=getTravisBuildNumber(row[:repo_name])
      puts
      statement = @client.prepare('INSERT INTO repository(reponame,stars,builds) VALUES(?,?,?);')
      statement.execute(row[:repo_name],stars,builds)
    end
  end
end
@account=ARGV[1]
@password=ARGV[2]
scanCSV(ARGV[0])