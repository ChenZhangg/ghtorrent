require 'json'
require 'open-uri'
require 'smarter_csv'
require 'travis'
require 'mysql2'
@account=['shunervw497',
'louqianzyq220808@163.com',
'340355960@qq.com'
]
@count=0
def changeAccount(i)
  @account[i%(@account.length)]
end

def getProjectStar(repo_name)
  k=0
  begin
    url="https://api.github.com/repos/#{repo_name}"
    f=open(url,:http_basic_authentication=>[@account[@count], 'cumtzc04091751'])
    stars=JSON.parse(f.read)['stargazers_count']
    puts "#{repo_name}     #{stars}"
    puts "#{repo_name}     #{@account[@count]}     #{f.meta["x-ratelimit-remaining"]}"
    @count+=1 if f.meta["x-ratelimit-remaining"].to_i<10
  rescue => e
    puts "#{e.message}"
    k+=1
    stars=0
    sleep 10
    retry if k<3 && !(e.message.include?('404'))
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
  puts "#{repo_name}     #{builds}"
  builds
end

def mysql_initiallize
  @client = Mysql2::Client.new(:host => 'localhost', :username => 'root',:password=>'701015')
  results = @client.query('CREATE DATABASE IF NOT EXISTS zc')
  results = @client.query('USE zc')
  results = @client.query('CREATE TABLE IF NOT EXISTS repository(
    id    int,
    reponame varchar(255),
    stars int,
    builds int
    );')
end

def scanCSV(csv_file_path)
  mysql_initiallize
  count=0
  SmarterCSV.process(csv_file_path, {:chunk_size => 10, :headers_in_file => false, :user_provided_headers => [:url, :repo_name]}) do |chunk|
    chunk.each do |row|
      stars=getProjectStar(row[:repo_name])
      builds=getTravisBuildNumber(row[:repo_name])
      puts
      statement = @client.prepare('INSERT INTO repository(id,reponame,stars,builds) VALUES(?,?,?,?);')
      statement.execute(count,row[:repo_name],stars,builds)
      count+=1
    end
  end
end
scanCSV('../data/test.csv')