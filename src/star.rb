require 'json'
require 'open-uri'
require 'smarter_csv'
require 'travis'
require 'mysql2'
@account=['528447050@139.com',
'15005210142@sohu.com',
'chenzhangfdse@sina.com',
'chenzhangfdse@outlook.com',
'chenzhangfdse@21cn.com',
'mfkzihys@dongqing365.com',
'erqrer@dongqing365.com',
'erqrer2fs@dongqing365.com',
'thyjyue@dongqing365.com',
'thyjyueee@dongqing365.com',
'etregggg@dongqing365.com',
'rgnggs@dongqing365.com',
'yulg@dongqing365.com',
'iiilds@dongqing365.com',
'zchnd@dongqing365.com',
'yukjg@dongqing365.com',
'ukld@dongqing365.com',
'lopf@dongqing365.com',
'opgs@dongqing365.com',
'plh@dongqing365.com'
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
    puts "#{@account[@count]}     #{f.meta["x-ratelimit-remaining"]}"
    @count+=1 if f.meta["x-ratelimit-remaining"].to_i<30

  rescue => e
    puts "===#{e.message}"
    k+=1
    stars=0
    #sleep 10
    #retry if k<3
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
end

def mysql_initiallize
  @client = Mysql2::Client.new(:host => 'localhost', :username => 'root',:password=>'701015')
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
      statement = @client.prepare('INSERT INTO repository(reponame,stars,builds) VALUES(?,?,?);')
      statement.execute(row[:repo_name],stars,builds)
    end
  end
end
scanCSV('test.csv')
#getProjectStar('rails/rails')