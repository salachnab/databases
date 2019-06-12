require 'pg'
inarr = ARGV
begin
    db = PG.connect :dbname => inarr[0], :user => inarr[1], :password => inarr[2]
    db.exec "CREATE TABLE ids(id numeric(19, 0) PRIMARY KEY);"
    db.exec "CREATE TABLE Member(id numeric(19, 0) PIMARY KEY, password varchar(128), is_leader integer(1), last_activity timestamp, upvotes numeric(19, 0), downvotes numeric(19, 0)), FOREIGN KEY(id) REFERENCES ids(id);"
    db.exec "CREATE TABLE Project(pid numeric(19, 0) PRIMARY KEY, timestamp timestamp, authority numeric(19, 0)), FOREIGN KEY pid REFERENCES ids(id));"
    db.exec "CREATE TABLE Action(aid numeric(19, 0) PRIMARY KEY, pid numeric(19, 0), mid numeric(19, 0), timestamp timestamp, type integer(1), upvotes numeric(19, 0), downvotes numeric(19, 0), FOREIGN KEY(aid) REFERENCES ids(id), FOREIGN KEY(pid) REFERENCES Project(pid), FOREIGN KEY(mid) REFERENCES Member(id));"
    db.exec "CREATE TABLE Votes(Memberid numeric(19, 0) PRIMARY KEY, Actionaid numeric(19, 0) PRIMARY KEY, updown integer(1), timestamp timestamp), FOREIGN KEY(Memberid) REFERENCES Member(id), FOREIGN KEY(Actionaid) REFERENCES Action(aid));"
rescue Exception => e
    puts "{\"status\": \"ERROR\"}"
ensure
    if db then db.close end
end