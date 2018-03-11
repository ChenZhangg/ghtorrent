require 'json'
require 'open-uri'
require 'travis'
require 'mysql2'

@account='340355960@qq.com'
@password='cumtzc04091751'
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
  builds
end

def urlOpen(url)
  begin
    f=open(url,:http_basic_authentication=>[@account, @password])
    puts "x-ratelimit-remaining: #{f.meta["x-ratelimit-remaining"]}"
  rescue =>e
    puts "cannot open #{url}\n#{e.message}"
    puts "x-ratelimit-remaining: #{f.meta["x-ratelimit-remaining"]}"
    sleep 5
    retry
  end
  f
end

def getProjectsList(url)
  puts "Scanning #{url}  use  account=#{@account}"
  f=urlOpen(url)

  match=f.meta['link'].match(/<(.+?)>/)
  next_url=match[1]
  repo_list=JSON.parse(f.read)
  repo_list.each do |hash|
    repo_url="https://api.github.com/repos/#{hash['full_name']}"
    puts repo_url

    builds=getTravisBuildNumber(hash['full_name'])

    rf=urlOpen(repo_url)
    json=JSON.parse(rf.read)

    stars=json['stargazers_count']
    language=json['language']
    puts "#{hash['id']}    #{hash['full_name']}   language: #{language}      stars: #{stars}      builds: #{builds}"

    statement = @client.prepare('INSERT INTO all_repository_github(id,reponame,language,stars,builds) VALUES(?,?,?,?,?);')
    statement.execute(hash['id'],hash['full_name'],language,stars,builds)
  end

  getProjectsList(next_url)
end

def mysql_initiallize
  @client = Mysql2::Client.new(:host => 'localhost', :username => 'root',:password=>'root')
  results = @client.query('CREATE DATABASE IF NOT EXISTS zc')
  results = @client.query('USE zc')
  results = @client.query('CREATE TABLE IF NOT EXISTS all_repository_github(
    id int,
    reponame varchar(255),
    language varchar(255),
    stars int,
    builds int
    );')
end
mysql_initiallize
getProjectsList('https://api.github.com/repositories')